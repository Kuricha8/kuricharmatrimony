import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/admin_config.dart';
import 'forgot_password_screen.dart';
import '../family_tree/family_tree_auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final input = _emailController.text.trim();
      final password = _passwordController.text;

      // Normalize phone number to email if phone is entered
      String loginEmail = input;
      final cleanDigits = input.replaceAll(RegExp(r'\D'), '');
      if (!input.contains('@') && cleanDigits.length >= 10) {
        loginEmail = '$cleanDigits@auth.kurichiyar.com';
      }

      AuthResponse response;
      try {
        response = await Supabase.instance.client.auth.signInWithPassword(
          email: loginEmail,
          password: password,
        );
      } catch (err) {
        // Fallback: If login with synthetic email failed and input had no @, try direct input
        if (loginEmail != input) {
          response = await Supabase.instance.client.auth.signInWithPassword(
            email: input,
            password: password,
          );
        } else {
          rethrow;
        }
      }

      if (response.user != null) {
        final user = response.user!;
        bool isSuperAdmin = AdminConfig.isSuperAdmin(
          phone: input,
          email: user.email,
        ) || AdminConfig.isSuperAdmin(
          phone: user.phone,
        );

        bool isAdmin = isSuperAdmin || user.email?.toLowerCase() == 'kuricha8@gmail.com';

        if (!isAdmin) {
          try {
            final doc = await FirebaseFirestore.instance.collection('users').doc(user.id).get();
            if (doc.exists && (doc.data()?['role'] == 'admin' || doc.data()?['role'] == 'super_admin' || doc.data()?['isAdmin'] == true)) {
              isAdmin = true;
            }
          } catch (_) {}
        }

        if (!isAdmin) {
          try {
            final profile = await Supabase.instance.client
                .from('kurichiyar_profiles')
                .select('role, guardian_phone, public_display_number')
                .eq('id', user.id)
                .maybeSingle();
            if (profile != null) {
              final role = profile['role']?.toString().toLowerCase().trim();
              final phone = (profile['guardian_phone'] ?? profile['public_display_number'])?.toString();
              if (role == 'admin' || role == 'super_admin' || AdminConfig.isSuperAdmin(phone: phone)) {
                isAdmin = true;
              }
            }
          } catch (_) {}
        }

        if (!isAdmin) {
          try {
            final adminRecord = await Supabase.instance.client
                .from('admin_users')
                .select()
                .eq('id', user.id)
                .maybeSingle();
            if (adminRecord != null) {
              isAdmin = true;
            }
          } catch (_) {}
        }

        // If Super Admin or Admin, auto-sync and persist admin role in Firestore and Supabase
        if (isAdmin || isSuperAdmin) {
          isAdmin = true;
          unawaited(AdminConfig.ensureAdminRecord(
            user.id,
            phone: input,
            email: user.email,
          ));
        }

        bool isAgent = false;
        String? agentApprovalStatus;

        if (!isAdmin) {
          try {
            final agentRecord = await Supabase.instance.client
                .from('agents')
                .select()
                .eq('id', user.id)
                .maybeSingle();
            if (agentRecord != null) {
              isAgent = true;
              agentApprovalStatus = agentRecord['approval_status'] ?? 'PENDING';
            }
          } catch (_) {}
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login successful!'),
              backgroundColor: Colors.green,
            ),
          );

          if (isAdmin) {
            // Directly bypass the regular gateway logic and mount admin panel
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/admin',
              (route) => false,
            );
          } else if (isAgent) {
            if (agentApprovalStatus == 'APPROVED') {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/agent_dashboard',
                (route) => false,
              );
            } else {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/agent_waiting',
                (route) => false,
              );
            }
          } else {
            // Regular user routing via AuthWrapper
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          }
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: const Color(0xFF000080),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.lock_person,
                    size: 80,
                    color: Color(0xFF000080),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome Back',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF000080),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),

                  // Phone / Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Phone Number or Email',
                      hintText: 'e.g. 8606415174 or user@email.com',
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        color: Color(0xFF000080),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF000080),
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your phone number or email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFF000080),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF000080),
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF000080),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Log In',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Colors.indigo.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  GoogleSignInButton(
                    label: 'Continue with Google',
                    onPressed: () =>
                        FamilyTreeAuthService.handleContinueWithGoogle(context),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),

                  // Become an Agent
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/agent_register');
                    },
                    icon: const Icon(Icons.assignment_ind),
                    label: const Text('Apply to Become an Agent'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF000080),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
