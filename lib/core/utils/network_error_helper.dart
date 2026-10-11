import 'dart:io';

/// Utility to convert raw network/socket errors into friendly Malayalam messages.
class NetworkErrorHelper {
  /// Returns true if the error is network/connectivity related.
  static bool isNetworkError(Object error) {
    final msg = error.toString().toLowerCase();
    return error is SocketException ||
        msg.contains('socketexception') ||
        msg.contains('websocketchannelexception') ||
        msg.contains('handshakeexception') ||
        msg.contains('connection refused') ||
        msg.contains('connection timed out') ||
        msg.contains('connection terminated') ||
        msg.contains('network is unreachable') ||
        msg.contains('no internet') ||
        msg.contains('failed host lookup') ||
        msg.contains('connection reset') ||
        msg.contains('connection closed') ||
        msg.contains('lost connection') ||
        msg.contains('realtime') ||
        msg.contains('realtimesubscribeexception');
  }

  /// Returns a friendly, user-facing error message in Malayalam.
  static String friendlyMessage(Object error) {
    if (isNetworkError(error)) {
      return 'ഇന്റർനെറ്റ് കണക്ഷൻ ഇല്ല. ദയവായി നെറ്റ്‌വർക്ക് പരിശോധിച്ച് വീണ്ടും ശ്രമിക്കുക.';
    }

    final msg = error.toString();

    // Supabase auth errors
    if (msg.contains('JWT') || msg.contains('token')) {
      return 'സെഷൻ കാലഹരണപ്പെട്ടു. ദയവായി വീണ്ടും ലോഗിൻ ചെയ്യുക.';
    }

    // RLS / permission errors
    if (msg.contains('permission denied') ||
        msg.contains('row-level security')) {
      return 'ഈ പ്രവർത്തനത്തിന് അനുമതി ഇല്ല.';
    }

    // UUID type errors
    if (msg.contains('22P02') ||
        msg.contains('22p02') ||
        msg.contains('invalid input syntax')) {
      return 'ഡാറ്റാ ഫോർമാറ്റ് പിശക്. ദയവായി ആപ്പ് അപ്ഡേറ്റ് ചെയ്യുക.';
    }

    // Storage errors
    if (msg.contains('storage') || msg.contains('bucket')) {
      return 'മീഡിയ അപ്‌ലോഡ് പരാജയപ്പെട്ടു. ദയവായി വീണ്ടും ശ്രമിക്കുക.';
    }

    // Generic fallback — hide technical details
    return 'ഒരു പിശക് സംഭവിച്ചു. ദയവായി വീണ്ടും ശ്രമിക്കുക.';
  }

  /// Wraps a raw error into a short, non-technical SnackBar-friendly string.
  static String snackBarMessage(Object error) {
    return friendlyMessage(error);
  }
}
