import 'package:flutter/material.dart';

import '../providers/app_state.dart';
import '../features/requests/data/recircle_api.dart';
import '../theme/app_theme.dart';
import '../widgets/recircle_branding.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.appState});
  final AppState appState;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_register) {
        await widget.appState.register(
          _name.text.trim(),
          _email.text.trim(),
          _password.text,
        );
      } else {
        await widget.appState.login(_email.text.trim(), _password.text);
      }
    } on ApiException catch (error) {
      if (mounted) {
        final message = error.statusCode == null
            ? (_register
                  ? 'Could not create your account. Check your connection and try again.'
                  : 'Could not sign in. Check your connection and try again.')
            : error.message;
        setState(() => _error = message);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              _register
                  ? 'Could not create your account. Check your connection and try again.'
                  : 'Could not sign in. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ReCircleBrandTitle('ReCircle'),
                  const SizedBox(height: 8),
                  Text(
                    _register
                        ? 'Create your customer account'
                        : 'Sign in to continue',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.subtitleGrey),
                  ),
                  const SizedBox(height: 28),
                  if (_register) ...[
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) => (value?.trim().length ?? 0) < 2
                          ? 'Enter your name'
                          : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) => (value?.contains('@') ?? false)
                        ? null
                        : 'Enter a valid email',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (value) => (value?.length ?? 0) >= 8
                        ? null
                        : 'Use at least 8 characters',
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_register ? 'Create Account' : 'Sign In'),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _register = !_register;
                            _error = null;
                          }),
                    child: Text(
                      _register
                          ? 'Already registered? Sign in'
                          : 'New to ReCircle? Create customer account',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Collection partners sign in with their partner account. Accounts are created by the demo administrator.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.subtitleGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
