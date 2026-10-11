import 'package:flutter/material.dart';
import 'permission_router.dart';

class PermissionSplashScreen extends StatefulWidget {
  final Widget nextScreen;
  const PermissionSplashScreen({super.key, required this.nextScreen});

  @override
  State<PermissionSplashScreen> createState() => _PermissionSplashScreenState();
}

class _PermissionSplashScreenState extends State<PermissionSplashScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initPermissions();
  }

  Future<void> _initPermissions() async {
    await PermissionRouter.requestEssentialPermissions();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return widget.nextScreen;
  }
}
