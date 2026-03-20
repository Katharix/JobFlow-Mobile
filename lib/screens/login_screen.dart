import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/user_service.dart';
import '../state/app_session.dart';
import '../theme/app_theme.dart';
import 'home_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.firebaseReady});

  final bool firebaseReady;

  static const routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _warningMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!widget.firebaseReady || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _warningMessage = null;
    });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(code: 'user-not-found');
      }

      final token = await user.getIdToken();
      AppSession.accessToken = token;
      AppSession.firebaseUid = user.uid;

      final profile = await UserService().fetchByFirebaseUid(user.uid);
      AppSession.employeeId = profile?.id;
      if (profile == null) {
        _warningMessage = 'Signed in, but profile lookup failed. Check API connectivity.';
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacementNamed(HomeShell.routeName);
    } on FirebaseAuthException catch (error) {
      setState(() {
        _errorMessage = error.message ?? 'Unable to sign in.';
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Unable to sign in. Check your connection and try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.mist, AppTheme.sand],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.sand,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    widget.firebaseReady
                        ? 'Secure sign-in is powered by Firebase and JobFlow API policies.'
                        : 'Firebase is not configured yet. Add Google Services config files to enable login.',
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
                  ),
                ],
                if (_warningMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _warningMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.secondary),
                  ),
                ],
                const SizedBox(height: 12),
                Image.asset(
                  'assets/branding/jobflow-logo.png',
                  height: 36,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome back',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Secure sign-in keeps job access protected while you stay on schedule.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.ink),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Work email',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.firebaseReady && !_isSubmitting ? _signIn : null,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign in'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {},
                  child: const Text('Need help signing in?'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
