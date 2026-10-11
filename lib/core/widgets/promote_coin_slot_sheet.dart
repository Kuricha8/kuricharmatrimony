import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/coin_ad_slot_model.dart';
import '../services/coin_ad_slot_service.dart';
import '../utils/mock_data.dart';
import '../../features/premium_packages/cashfree_service.dart';
import '../../features/premium_packages/payment_celebration_dialog.dart';

class PromoteCoinSlotSheet extends StatefulWidget {
  const PromoteCoinSlotSheet({super.key});

  @override
  State<PromoteCoinSlotSheet> createState() => _PromoteCoinSlotSheetState();
}

class _PromoteCoinSlotSheetState extends State<PromoteCoinSlotSheet> {
  String _selectedPosition = 'front'; // 'front' | 'back'
  File? _selectedImage;
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    CoinAdSlotService.instance.fetchActiveSlots();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final photo = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 75,
      );
      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking coin slot image: $e');
    }
  }

  Future<void> _startPurchaseFlow() async {
    final coinService = CoinAdSlotService.instance;
    final isFullyBooked = coinService.isPositionFullyBooked(_selectedPosition);

    if (isFullyBooked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ഈ ഫെയ്‌സിലെ സ്ലോട്ടുകൾ പൂർണ്ണമായി ബുക്ക് ചെയ്തിരിക്കുന്നു.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('കോയിനിൽ പ്രദർശിപ്പിക്കാൻ ഫോട്ടോ തിരഞ്ഞെടുക്കുക.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final me = MockData().currentUser;
    if (me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ദയവായി ലോഗിൻ ചെയ്യുക.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final orderId =
        'coin_${_selectedPosition}_${DateTime.now().millisecondsSinceEpoch}';
    final amount = 200.00;

    try {
      await CashfreeService()
          .startPayment(
            orderId: orderId,
            orderAmount: amount,
            customerId: me.id,
            customerPhone: '9876543210',
            customerName: me.name.isNotEmpty ? me.name : 'Community Member',
            customerEmail: me.email.isNotEmpty
                ? me.email
                : 'user@matrimony.com',
            planName:
                '3D Coin ${_selectedPosition.toUpperCase()} Slot (7 Days)',
            tierName: 'COIN_SLOT',
            durationMonths: 1,
            onSuccess: () async {
              try {
                // 1. Upload photo to Supabase storage
                final imageUrl = await CoinAdSlotService.instance
                    .uploadSlotImage(_selectedImage!, me.id);

                // 2. Activate or queue slot in database
                final result = await CoinAdSlotService.instance
                    .activateOrQueueCoinSlot(
                      slotPosition: _selectedPosition,
                      userId: me.id,
                      imageUrl: imageUrl,
                      amountPaid: amount,
                      paymentId: orderId,
                      durationDays: 7,
                    );

                if (mounted) {
                  setState(() => _isProcessing = false);

                  // 1. Close bottom sheet
                  if (context.mounted && Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }

                  // 2. Show full celebration dialog
                  if (context.mounted) {
                    await showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => PaymentCelebrationDialog(
                        title: 'അഭിനന്ദനങ്ങൾ! 🎉',
                        customSubtitle: result.isQueued
                            ? 'താങ്കളുടെ 3D കോയിൻ വെയ്റ്റിംഗ് സ്ലോട്ട് വിജയകരമായി ബുക്ക് ചെയ്തിരിക്കുന്നു.'
                            : 'താങ്കളുടെ 3D കോയിൻ പ്രൊമോഷൻ വിജയകരമായി ബുക്ക് ചെയ്തിരിക്കുന്നു.',
                        badgeText: result.isQueued
                            ? 'അടുത്ത ആഴ്ചയിലെ സ്ലോട്ടിൽ നിങ്ങളുടെ ഫോട്ടോ പ്രദർശിപ്പിക്കും.'
                            : 'അടുത്ത 7 ദിവസത്തേക്ക് കോയിനിൽ നിങ്ങളുടെ ഫോട്ടോ പ്രദർശിപ്പിക്കും.',
                        buttonText: 'തുടങ്ങാം',
                        onDone: () async {
                          Navigator.of(ctx, rootNavigator: true).pop();
                          await CoinAdSlotService.instance.fetchActiveSlots();
                        },
                      ),
                    );
                  }
                }
              } catch (e) {
                debugPrint('Error finalizing coin slot: $e');
                if (mounted) {
                  setState(() => _isProcessing = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ആക്റ്റിവേഷൻ പരാജയപ്പെട്ടു: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            onFailure: (errorMsg) {
              if (mounted) {
                setState(() => _isProcessing = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('പേയ്‌മെന്റ് പരാജയപ്പെട്ടു: $errorMsg'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              if (mounted) {
                setState(() => _isProcessing = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'പേയ്‌മെന്റ് സെർവർ പ്രതികരിച്ചില്ല (Timeout). ദയവായി വീണ്ടും ശ്രമിക്കുക.',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          );
    } catch (e) {
      debugPrint('Cashfree startPayment error: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('പേയ്‌മെന്റ് ആരംഭിക്കാൻ കഴിഞ്ഞില്ല: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSlotSelectionCard({
    required String position,
    required String title,
    required String subtitle,
    required CoinAdSlot? activeSlot,
    required CoinAdSlot? waitingSlot,
    required IconData icon,
  }) {
    final isSelected = _selectedPosition == position;
    final isActiveOccupied = activeSlot != null && !activeSlot.isExpired;
    final isWaitingOccupied = waitingSlot != null;
    final isFullyBooked = isActiveOccupied && isWaitingOccupied;

    return GestureDetector(
      onTap: () => setState(() => _selectedPosition = position),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isFullyBooked
              ? Colors.grey.shade50
              : (isSelected ? Colors.amber.shade50 : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isFullyBooked
                ? Colors.grey.shade300
                : (isSelected ? Colors.amber.shade800 : Colors.grey.shade300),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected && !isFullyBooked
              ? [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFullyBooked
                    ? Colors.grey.shade400
                    : (isSelected
                          ? Colors.amber.shade700
                          : const Color(0xFF000080)),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isFullyBooked
                                ? Colors.grey.shade600
                                : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected && !isFullyBooked)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.amber,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Status Badges (Active Free / Waiting Queue / Fully Booked)
                  if (!isActiveOccupied)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        '🟢 ലഭ്യമാണ് (Starts Immediately - 7 Days)',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (!isWaitingOccupied)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Text(
                        '🟡 അടുത്ത ആഴ്ചത്തേക്ക് ബുക്ക് ചെയ്യാം (Waiting Queue)',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        '🔴 സ്ലോട്ടുകൾ പൂർണ്ണമായി ബുക്ക് ചെയ്തിരിക്കുന്നു (Fully Booked)',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red.shade800,
                          fontWeight: FontWeight.bold,
                        ),
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CoinAdSlotService.instance,
      builder: (context, _) {
        final coinService = CoinAdSlotService.instance;
        final isSelectedPositionFull = coinService.isPositionFullyBooked(
          _selectedPosition,
        );

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header with glowing badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.monetization_on,
                        color: Colors.amber,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '3D കോയിനിൽ പ്രൊമോട്ട് ചെയ്യുക',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: Color(0xFF000080),
                            ),
                          ),
                          Text(
                            'ആപ്പ് ബാറിലെ കറങ്ങുന്ന കോയിനിൽ നിങ്ങളുടെ ഫോട്ടോ',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Pricing Banner
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade800, Colors.orange.shade700],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'പ്രത്യേക നിരക്ക്',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '₹200 / 7 ദിവസത്തേക്ക്',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.remove_red_eye,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'മുഴുവൻ അംഗങ്ങൾക്കും',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Slot Position Selector
                const Text(
                  'സ്ലോട്ട് തിരഞ്ഞെടുക്കുക:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 10),
                _buildSlotSelectionCard(
                  position: 'front',
                  title: 'മുൻഭാഗം (Front Face)',
                  subtitle: 'കോയിൻ കറങ്ങുമ്പോൾ മുന്നിൽ ആദ്യം കാണുന്നത്',
                  activeSlot: coinService.activeFrontSlot,
                  waitingSlot: coinService.waitingFrontSlot,
                  icon: Icons.flip_to_front,
                ),
                const SizedBox(height: 10),
                _buildSlotSelectionCard(
                  position: 'back',
                  title: 'പിൻഭാഗം (Back Face)',
                  subtitle: 'കോയിൻ കറങ്ങുമ്പോൾ 180° തിരിയുമ്പോൾ കാണുന്നത്',
                  activeSlot: coinService.activeBackSlot,
                  waitingSlot: coinService.waitingBackSlot,
                  icon: Icons.flip_to_back,
                ),
                const SizedBox(height: 16),

                // Photo Selection Section
                const Text(
                  'പ്രദർശിപ്പിക്കേണ്ട ഫോട്ടോ:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Center(
                  child: GestureDetector(
                    onTap: () => _pickImage(ImageSource.gallery),
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade100,
                        border: Border.all(
                          color: Colors.amber.shade700,
                          width: 3,
                        ),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 6),
                        ],
                      ),
                      child: _selectedImage != null
                          ? ClipOval(
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                                width: 90,
                                height: 90,
                              ),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo,
                                  color: Color(0xFF000080),
                                  size: 28,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'ഫോട്ടോ ചേർക്കുക',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF000080),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library, size: 16),
                      label: const Text(
                        'ഗാലറി',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt, size: 16),
                      label: const Text(
                        'ക്യാമറ',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Pay Button with Full Capacity Lock
                ElevatedButton(
                  onPressed: (_isProcessing || isSelectedPositionFull)
                      ? null
                      : _startPurchaseFlow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelectedPositionFull
                        ? Colors.grey
                        : const Color(0xFF000080),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: isSelectedPositionFull ? 0 : 3,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          isSelectedPositionFull
                              ? 'സ്ലോട്ടുകൾ പൂർണ്ണമായി ബുക്ക് ചെയ്തിരിക്കുന്നു'
                              : '₹200 അടയ്ക്കുക',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
