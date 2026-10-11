import 'package:flutter/material.dart';
import 'package:kurichiyar_matrimony/features/admin/admin_realtime_leads_screen.dart';

export 'package:kurichiyar_matrimony/features/admin/admin_realtime_leads_screen.dart';

/// Admin Approvals & Realtime Leads View for the Admin Web Dashboard.
class AdminApprovalsTab extends StatelessWidget {
  const AdminApprovalsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminRealtimeLeadsScreen(streamLimit: 50);
  }
}
