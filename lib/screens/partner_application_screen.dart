import 'package:flutter/material.dart';

import '../features/requests/data/recircle_api.dart';
import '../providers/app_state.dart';
import '../widgets/recircle_branding.dart';

class PartnerApplicationScreen extends StatefulWidget {
  const PartnerApplicationScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<PartnerApplicationScreen> createState() =>
      _PartnerApplicationScreenState();
}

class _PartnerApplicationScreenState extends State<PartnerApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = List.generate(8, (_) => TextEditingController());
  bool _submitting = false;
  bool _submitted = false;
  bool _passwordVisible = false;
  String? _error;

  static const _fields = [
    ('Full name', 'name'),
    ('Email address', 'email'),
    ('Phone number', 'phone'),
    ('Password (at least 8 characters)', 'password'),
    ('Pickup address', 'address'),
    ('City', 'city'),
    ('Postal / PIN code', 'pinCode'),
    ('Collection service area', 'serviceArea'),
  ];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _validate(String? value, String key) {
    final text = value?.trim() ?? '';
    if (key == 'password') {
      if (value == null || value.length < 8 || value.length > 72) {
        return 'Use a password from 8 to 72 characters';
      }
      return null;
    }
    if (key == 'email') {
      return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)
          ? null
          : 'Enter a valid email address';
    }
    final minLength = key == 'pinCode' ? 3 : 2;
    if (text.length < minLength) {
      return 'Enter ${_fields.firstWhere((f) => f.$2 == key).$1.toLowerCase()}';
    }
    if (key == 'pinCode' && !RegExp(r'^[A-Za-z0-9 -]{3,12}$').hasMatch(text)) {
      return 'Use 3 to 12 letters, numbers, spaces or hyphens';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_submitting || _submitted || !_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final body = <String, dynamic>{
        for (var i = 0; i < _fields.length; i++)
          _fields[i].$2: _controllers[i].text.trim(),
      };
      await widget.appState.api.post('/auth/partner-register', body);
      if (mounted) setState(() => _submitted = true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Application could not be sent. Retry.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const ReCircleBrandTitle('Partner Application')),
    body: _submitted
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.hourglass_top, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'Application submitted',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your account is pending administrator review. Pickup requests are available after approval.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Return to sign in'),
                  ),
                ],
              ),
            ),
          )
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Apply to collect ReCircle requests in your area. Approval is required before partner pickup tools are enabled.',
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < _fields.length; i++) ...[
                  TextFormField(
                    key: ValueKey('partner-application-${_fields[i].$2}'),
                    controller: _controllers[i],
                    obscureText: i == 3 && !_passwordVisible,
                    keyboardType: i == 1
                        ? TextInputType.emailAddress
                        : i == 2
                        ? TextInputType.phone
                        : TextInputType.text,
                    textCapitalization: i == 1 || i == 3
                        ? TextCapitalization.none
                        : TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: _fields[i].$1,
                      suffixIcon: i == 3
                          ? IconButton(
                              tooltip: _passwordVisible
                                  ? 'Hide password'
                                  : 'Show password',
                              onPressed: () => setState(
                                () => _passwordVisible = !_passwordVisible,
                              ),
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            )
                          : null,
                    ),
                    validator: (value) => _validate(value, _fields[i].$2),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit application'),
                ),
              ],
            ),
          ),
  );
}
