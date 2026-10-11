import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/services/call_service.dart';

/// Active In-App Audio & Video Call Screen with Mediated Safe Call Features.
/// Supports WebRTC P2P media, 30s ringing timeout, call reject, mute/speaker/camera controls,
/// and automatic session cleanup on disconnect.
class SecureAudioCallScreen extends StatefulWidget {
  final String currentUserId;
  final String targetUserId;
  final String targetUserName;
  final bool isCaller;
  final bool isAdmin;
  final int maxDurationMinutes;
  final String? callId;
  final String callType; // 'audio' or 'video'

  const SecureAudioCallScreen({
    super.key,
    required this.currentUserId,
    required this.targetUserId,
    required this.targetUserName,
    this.isCaller = true,
    this.isAdmin = false,
    this.maxDurationMinutes = 15,
    this.callId,
    this.callType = 'audio',
  });

  @override
  State<SecureAudioCallScreen> createState() => _SecureAudioCallScreenState();
}

class _SecureAudioCallScreenState extends State<SecureAudioCallScreen>
    with TickerProviderStateMixin {
  late int _remainingSeconds;
  Timer? _activeCallTimer;
  Timer? _ringingTimeoutTimer;
  int _ringingSeconds = 30; // 30-Second Ringing Timeout

  String _callState =
      'calling'; // 'calling', 'connected', 'rejected', 'ended', 'timeout'
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isCameraOff = false;
  bool _sosTriggered = false;
  bool _isOnHold = false;
  final AudioPlayer _holdAudioPlayer = AudioPlayer();
  StreamSubscription<List<Map<String, dynamic>>>? _holdStatusSubscription;

  RealtimeChannel? _callChannel;
  RTCPeerConnection? _peerConnection;
  final List<RTCIceCandidate> _pendingCandidates = [];
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.maxDurationMinutes * 60;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(_pulseController);

    if (widget.isCaller) {
      _startRingingTimeoutTimer();
    } else {
      _callState = 'connected';
      _startActiveCallTimer();
    }

    _listenForRemoteHoldStatus();
    _initWebRTCP2PSession();
  }

  /// 30-Second Ringing Timeout Timer
  void _startRingingTimeoutTimer() {
    _ringingSeconds = 30;
    _ringingTimeoutTimer?.cancel();
    _ringingTimeoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_callState != 'calling') {
        timer.cancel();
        return;
      }
      if (_ringingSeconds <= 1) {
        timer.cancel();
        _handleRingingTimeout();
      } else {
        if (mounted) {
          setState(() {
            _ringingSeconds--;
          });
        }
      }
    });
  }

  /// Handle Ringing Timeout (No Answer within 30 seconds)
  Future<void> _handleRingingTimeout() async {
    if (_callState != 'calling') return;
    setState(() => _callState = 'timeout');

    if (widget.callId != null) {
      await CallService.instance.timeoutCallSession(
        widget.callId!,
        widget.targetUserId,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('മറുപടി ലഭിച്ചില്ല (No answer - Call Timed Out)'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 3),
        ),
      );
      _cleanupAndPop();
    }
  }

  /// Active Connected Call Timer
  void _startActiveCallTimer() {
    _ringingTimeoutTimer?.cancel();
    _activeCallTimer?.cancel();
    _activeCallTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _endCall(
          reason:
              'കോൾ സമയം പൂർത്തിയായി (${widget.maxDurationMinutes} മിനിറ്റ്)',
        );
      } else {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
          });
        }
      }
    });
  }

  Future<void> _initWebRTCP2PSession() async {
    try {
      debugPrint(
        '[SIGNALING] Initializing ${widget.callType} WebRTC call for Room: call_room_${widget.callId}',
      );

      // Permissions
      await Permission.microphone.request();
      if (widget.callType == 'video') {
        final cameraStatus = await Permission.camera.request();
        if (cameraStatus.isDenied || cameraStatus.isPermanentlyDenied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'വീഡിയോ കോളിനായി ക്യാമറ അനുമതി ആവശ്യമാണ് (Camera Permission Required)',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      // Initialize Renderers
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();

      // Constraints
      final mediaConstraints = {
        'audio': {'echoCancellation': true, 'noiseSuppression': true},
        'video': widget.callType == 'video'
            ? {
                'facingMode': 'user',
                'mandatory': {
                  'minWidth': '640',
                  'minHeight': '480',
                  'minFrameRate': '30',
                },
              }
            : false,
      };

      try {
        _localStream = await navigator.mediaDevices.getUserMedia(
          mediaConstraints,
        );
        _localRenderer.srcObject = _localStream;
        if (mounted) setState(() {});
      } catch (e) {
        debugPrint('[SIGNALING] getUserMedia notice: $e');
      }

      final Map<String, dynamic> configuration = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {'urls': 'stun:stun1.l.google.com:19302'},
          {'urls': 'stun:stun2.l.google.com:19302'},
          {'urls': 'stun:stun3.l.google.com:19302'},
        ],
        'sdpSemantics': 'unified-plan',
      };

      _peerConnection = await createPeerConnection(configuration);

      _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
        debugPrint('[CONNECTION] ICE State: $state');
        if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
            state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
          if (mounted && _callState == 'calling') {
            setState(() => _callState = 'connected');
            _startActiveCallTimer();
          }
        }
      };

      if (_localStream != null) {
        _localStream!.getTracks().forEach((track) {
          _peerConnection!.addTrack(track, _localStream!);
        });
      }

      _peerConnection!.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams[0];
          _remoteRenderer.srcObject = _remoteStream;
          if (mounted) {
            setState(() {
              _callState = 'connected';
            });
            _startActiveCallTimer();
          }
        }
      };

      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        if (widget.callId == null) return;
        _callChannel?.sendBroadcastMessage(
          event: 'ice_candidate',
          payload: {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        );
      };

      _initSupabaseSignalingChannel();

      if (widget.isCaller) {
        RTCSessionDescription offer = await _peerConnection!.createOffer();
        await _peerConnection!.setLocalDescription(offer);

        _callChannel?.sendBroadcastMessage(
          event: 'sdp_offer',
          payload: {'sdp': offer.sdp, 'type': offer.type},
        );

        if (widget.callId != null) {
          await Supabase.instance.client
              .from('call_signaling')
              .insert({
                'call_id': widget.callId,
                'sender_id': widget.currentUserId,
                'type': offer.type,
                'sdp': offer.sdp,
                'created_at': DateTime.now().toIso8601String(),
              })
              .catchError((_) {});
        }
      }
    } catch (e, stackTrace) {
      debugPrint("CRASH ERROR: $e \n $stackTrace");
    }
  }

  void _initSupabaseSignalingChannel() {
    if (widget.callId == null || widget.callId!.isEmpty) return;
    try {
      _callChannel = Supabase.instance.client
          .channel('call_room_${widget.callId}')
          .onBroadcast(
            event: 'call_signal',
            callback: (payload) {
              final type = payload['type'];
              if (type == 'end_call') {
                _endCall(reason: 'മറ്റേ വ്യക്തി കോൾ അവസാനിപ്പിച്ചു');
              }
            },
          )
          .onBroadcast(
            event: 'call_rejected',
            callback: (payload) {
              if (mounted) {
                setState(() => _callState = 'rejected');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('കോൾ നിരസിച്ചു (Call Rejected)'),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: Colors.red.shade800,
                  ),
                );
                _cleanupAndPop();
              }
            },
          )
          .onBroadcast(
            event: 'call_timeout',
            callback: (payload) {
              if (mounted) {
                setState(() => _callState = 'timeout');
                _cleanupAndPop();
              }
            },
          )
          .onBroadcast(
            event: 'sdp_offer',
            callback: (payload) async {
              if (!widget.isCaller && _peerConnection != null) {
                final sdp = payload['sdp'];
                final type = payload['type'];
                await _peerConnection!.setRemoteDescription(
                  RTCSessionDescription(sdp, type),
                );
                await _drainPendingCandidates();

                RTCSessionDescription answer = await _peerConnection!
                    .createAnswer();
                await _peerConnection!.setLocalDescription(answer);

                _callChannel?.sendBroadcastMessage(
                  event: 'sdp_answer',
                  payload: {'sdp': answer.sdp, 'type': answer.type},
                );
              }
            },
          )
          .onBroadcast(
            event: 'sdp_answer',
            callback: (payload) async {
              if (widget.isCaller && _peerConnection != null) {
                final sdp = payload['sdp'];
                final type = payload['type'];
                await _peerConnection!.setRemoteDescription(
                  RTCSessionDescription(sdp, type),
                );
                await _drainPendingCandidates();
                if (mounted) {
                  setState(() {
                    _callState = 'connected';
                  });
                  _startActiveCallTimer();
                }
              }
            },
          )
          .onBroadcast(
            event: 'ice_candidate',
            callback: (payload) async {
              if (_peerConnection != null) {
                final candidateStr = payload['candidate'];
                final sdpMid = payload['sdpMid'];
                final sdpMLineIndex = payload['sdpMLineIndex'];
                if (candidateStr != null) {
                  final candidate = RTCIceCandidate(
                    candidateStr,
                    sdpMid,
                    sdpMLineIndex,
                  );
                  var remoteDesc = await _peerConnection!
                      .getRemoteDescription();
                  if (remoteDesc != null) {
                    await _peerConnection!.addCandidate(candidate);
                  } else {
                    // റിമോട്ട് ഡിസ്ക്രിപ്ഷൻ സെറ്റ് ആകുന്നതുവരെ കാൻഡിഡേറ്റുകൾ ഒരു ലിസ്റ്റിൽ സൂക്ഷിക്കുക
                    _pendingCandidates.add(candidate);
                  }
                }
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('[SIGNALING] Realtime channel notice: $e');
    }
  }

  Future<void> _drainPendingCandidates() async {
    if (_peerConnection == null) return;
    for (var candidate in _pendingCandidates) {
      await _peerConnection!.addCandidate(candidate).catchError((_) {});
    }
    _pendingCandidates.clear();
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !_isMuted;
    });
  }

  void _toggleSpeaker() {
    setState(() => _isSpeakerOn = !_isSpeakerOn);
    try {
      Helper.setSpeakerphoneOn(_isSpeakerOn);
    } catch (_) {}
  }

  void _toggleCamera() {
    setState(() => _isCameraOff = !_isCameraOff);
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = !_isCameraOff;
    });
  }

  String get _formattedTime {
    final mins = _remainingSeconds ~/ 60;
    final secs = _remainingSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _endCall({String? reason}) async {
    _ringingTimeoutTimer?.cancel();
    _activeCallTimer?.cancel();
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}

    try {
      _callChannel?.sendBroadcastMessage(
        event: 'call_signal',
        payload: {'type': 'end_call'},
      );
    } catch (_) {}

    if (widget.callId != null) {
      try {
        await CallService.instance.updateCallSessionStatus(
          widget.callId!,
          'ended',
          endReason: reason,
        );
      } catch (_) {}
    }

    if (mounted) {
      if (reason != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(reason),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }
      _cleanupAndPop();
    }
  }

  void _cleanupAndPop() {
    _ringingTimeoutTimer?.cancel();
    _activeCallTimer?.cancel();
    try {
      _localStream?.getTracks().forEach((track) => track.stop());
      _localStream?.dispose();
      _localStream = null;

      _remoteStream?.getTracks().forEach((track) => track.stop());
      _remoteStream?.dispose();
      _remoteStream = null;

      _peerConnection?.close();
      _peerConnection = null;

      _localRenderer.dispose();
      _remoteRenderer.dispose();
    } catch (e) {
      debugPrint('Error in call cleanup: $e');
    }

    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Future<void> _triggerSOS() async {
    if (widget.isAdmin) return;
    HapticFeedback.heavyImpact();
    setState(() => _sosTriggered = true);

    if (widget.callId != null) {
      await CallService.instance.triggerEmergencySOS(
        callId: widget.callId!,
        userId: widget.currentUserId,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🚨 അടിയന്തിര SOS അലർട്ട് അഡ്മിനിലേക്ക് അയച്ചു!'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.red.shade800,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  void dispose() {
    _holdStatusSubscription?.cancel();
    _holdAudioPlayer.dispose();
    _pulseController.dispose();
    _ringingTimeoutTimer?.cancel();
    _activeCallTimer?.cancel();
    _callChannel?.unsubscribe();
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _peerConnection?.close();
    super.dispose();
  }

  void _listenForRemoteHoldStatus() {
    if (widget.callId == null || widget.callId!.isEmpty) return;

    _holdStatusSubscription?.cancel();
    _holdStatusSubscription = Supabase.instance.client
        .from('call_sessions')
        .stream(primaryKey: ['id'])
        .eq('id', widget.callId!)
        .listen((data) async {
          if (data.isNotEmpty && mounted) {
            final callData = data.first;
            final bool remoteIsOnHold = callData['is_on_hold'] == true;

            if (remoteIsOnHold && !_isOnHold) {
              await _holdAudioPlayer.setReleaseMode(ReleaseMode.loop);
              try {
                await _holdAudioPlayer.play(AssetSource('audio/hold_tune.mp3'));
              } catch (_) {
                await _holdAudioPlayer.play(
                  AssetSource('sounds/general_notification.wav'),
                );
              }
            } else if (!remoteIsOnHold && !_isOnHold) {
              await _holdAudioPlayer.stop();
            }
          }
        });
  }

  Future<void> _toggleHold() async {
    final nextHoldState = !_isOnHold;
    setState(() {
      _isOnHold = nextHoldState;
    });

    try {
      if (_localStream != null && _localStream!.getAudioTracks().isNotEmpty) {
        _localStream!.getAudioTracks().first.enabled = !nextHoldState;
      }

      if (nextHoldState) {
        await _holdAudioPlayer.setReleaseMode(ReleaseMode.loop);
        try {
          await _holdAudioPlayer.play(AssetSource('audio/hold_tune.mp3'));
        } catch (_) {
          await _holdAudioPlayer.play(
            AssetSource('sounds/general_notification.wav'),
          );
        }
      } else {
        await _holdAudioPlayer.stop();
      }

      if (widget.callId != null && widget.callId!.isNotEmpty) {
        try {
          await Supabase.instance.client
              .from('call_sessions')
              .update({'is_on_hold': nextHoldState})
              .eq('id', widget.callId!);
        } catch (e) {
          debugPrint('Hold DB update notice: $e');
        }
      }
    } catch (e) {
      debugPrint('Hold toggle error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isRinging = _callState == 'calling';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            color: Colors.greenAccent,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              widget.callType == 'video'
                                  ? 'സുരക്ഷിത ലൈവ് വീഡിയോ കോൾ'
                                  : 'സുരക്ഷിത ലൈവ് ഓഡിയോ കോൾ',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!isRinging)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _remainingSeconds < 60
                            ? Colors.red.withValues(alpha: 0.2)
                            : Colors.blue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _remainingSeconds < 60
                              ? Colors.redAccent
                              : Colors.blueAccent,
                        ),
                      ),
                      child: Text(
                        _formattedTime,
                        style: TextStyle(
                          color: _remainingSeconds < 60
                              ? Colors.redAccent
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber, width: 1),
                      ),
                      child: Text(
                        'റിംഗിംഗ്... (${_ringingSeconds}s)',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const Spacer(),

            // Main Display (Video Renderers or Avatar)
            if (widget.callType == 'video' && !_isCameraOff && !isRinging)
              SizedBox(
                width: 280,
                height: 350,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.greenAccent,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _remoteRenderer.srcObject != null
                              ? RTCVideoView(
                                  _remoteRenderer,
                                  objectFit: RTCVideoViewObjectFit
                                      .RTCVideoViewObjectFitCover,
                                )
                              : (_localRenderer.srcObject != null
                                    ? RTCVideoView(
                                        _localRenderer,
                                        mirror: true,
                                        objectFit: RTCVideoViewObjectFit
                                            .RTCVideoViewObjectFitCover,
                                      )
                                    : const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            CircularProgressIndicator(
                                              color: Colors.greenAccent,
                                            ),
                                            SizedBox(height: 12),
                                            Text(
                                              'വീഡിയോ കണക്റ്റ് ചെയ്യുന്നു...',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )),
                        ),
                      ),
                    ),
                    if (_remoteRenderer.srcObject != null &&
                        _localRenderer.srcObject != null)
                      Positioned(
                        right: 10,
                        bottom: 10,
                        width: 85,
                        height: 110,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: RTCVideoView(
                              _localRenderer,
                              mirror: true,
                              objectFit: RTCVideoViewObjectFit
                                  .RTCVideoViewObjectFitCover,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              )
            else
              ScaleTransition(
                scale: isRinging
                    ? _pulseAnimation
                    : const AlwaysStoppedAnimation(1.0),
                child: CircleAvatar(
                  radius: 64,
                  backgroundColor: isRinging
                      ? Colors.amber.shade800
                      : Colors.deepPurple.shade700,
                  child: Text(
                    widget.targetUserName.isNotEmpty
                        ? widget.targetUserName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),
            Text(
              widget.targetUserName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isRinging
                  ? '${widget.targetUserName}-ലേക്ക് കോൾ കണക്റ്റ് ചെയ്യുന്നു...'
                  : (_sosTriggered
                        ? '🚨 അഡ്മിൻ സുരക്ഷാ മോണിറ്ററിംഗ്'
                        : 'അഡ്മിൻ വഴി സുരക്ഷിതമായി കണക്ട് ചെയ്തിരിക്കുന്നു'),
              style: TextStyle(
                fontSize: 13,
                color: isRinging
                    ? Colors.amber
                    : (_sosTriggered ? Colors.redAccent : Colors.white54),
                fontWeight: isRinging ? FontWeight.bold : FontWeight.normal,
              ),
            ),

            const Spacer(),

            // SOS Alert Trigger Button (ONLY for regular users, NOT for Admin)
            if (!widget.isAdmin && !isRinging)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32.0,
                  vertical: 10,
                ),
                child: ElevatedButton.icon(
                  onPressed: _sosTriggered ? null : _triggerSOS,
                  icon: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                  ),
                  label: Text(
                    _sosTriggered
                        ? 'SOS അലർട്ട് അയച്ചു'
                        : '🚨 SOS അഡ്മിൻ സഹായം',
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    backgroundColor: _sosTriggered
                        ? Colors.grey
                        : Colors.orange.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),

            // Controls Toolbar
            Padding(
              padding: const EdgeInsets.only(bottom: 36.0, top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute Button
                  IconButton.filledTonal(
                    iconSize: 30,
                    onPressed: _toggleMute,
                    icon: Icon(_isMuted ? Icons.mic_off : Icons.mic),
                    style: IconButton.styleFrom(
                      backgroundColor: _isMuted
                          ? Colors.red.shade900
                          : Colors.white24,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),

                  // Hold Button
                  IconButton.filledTonal(
                    iconSize: 30,
                    onPressed: _toggleHold,
                    icon: Icon(
                      _isOnHold
                          ? Icons.pause_circle_filled
                          : Icons.pause_circle_outline,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: _isOnHold
                          ? Colors.amber.shade900
                          : Colors.white24,
                      foregroundColor: _isOnHold ? Colors.amber : Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),

                  if (widget.callType == 'video')
                    IconButton.filledTonal(
                      iconSize: 30,
                      onPressed: _toggleCamera,
                      icon: Icon(
                        _isCameraOff ? Icons.videocam_off : Icons.videocam,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: _isCameraOff
                            ? Colors.red.shade900
                            : Colors.white24,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),

                  // End Call Button
                  IconButton.filled(
                    iconSize: 36,
                    onPressed: () => _endCall(reason: 'കോൾ അവസാനിപ്പിച്ചു'),
                    icon: const Icon(Icons.call_end),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(20),
                    ),
                  ),

                  // Speaker Button
                  IconButton.filledTonal(
                    iconSize: 30,
                    onPressed: _toggleSpeaker,
                    icon: Icon(
                      _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: _isSpeakerOn
                          ? Colors.blue.shade900
                          : Colors.white24,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
