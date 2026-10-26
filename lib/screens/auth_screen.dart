import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';
import '../providers/app_state.dart';
import '../features/requests/data/recircle_api.dart';
import '../widgets/recircle_branding.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.appState});
  final AppState appState;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  late final AnimationController _ambient;
  bool _register = false;
  bool _busy = false;
  bool _passwordVisible = false;
  bool _motionDisabled = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    );
    if (!_reduceMotion) _ambient.repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disabled = MediaQuery.of(context).disableAnimations;
    if (disabled == _motionDisabled) return;
    _motionDisabled = disabled;
    if (disabled) {
      _ambient.stop();
    } else if (WidgetsBinding.instance.lifecycleState ==
        AppLifecycleState.resumed) {
      _ambient.repeat(reverse: true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        !_motionDisabled &&
        !_reduceMotion) {
      _ambient.repeat(reverse: true);
    } else {
      _ambient.stop();
    }
  }

  bool get _reduceMotion => WidgetsBinding
      .instance
      .platformDispatcher
      .accessibilityFeatures
      .disableAnimations;

  bool _validEmail(String value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ambient.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) {
      if (_register && _name.text.trim().length < 2) {
        _nameFocus.requestFocus();
      } else if (!_validEmail(_email.text.trim())) {
        _emailFocus.requestFocus();
      } else {
        _passwordFocus.requestFocus();
      }
      return;
    }
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
        setState(
          () => _error = error.statusCode == null
              ? (_register
                    ? 'Could not create your account. Check your connection and try again.'
                    : 'Could not sign in. Check your connection and try again.')
              : error.message,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = _register
              ? 'Could not create your account. Check your connection and try again.'
              : 'Could not sign in. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toggleMode() {
    if (_busy) return;
    setState(() {
      _register = !_register;
      _error = null;
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              22,
              constraints.maxHeight < 690 ? 10 : 18,
              22,
              24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: AutofillGroup(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _entrance(
                          reduceMotion,
                          0,
                          const ReCircleBrandTitle('ReCircle'),
                        ),
                        SizedBox(height: constraints.maxHeight < 690 ? 12 : 20),
                        _entrance(
                          reduceMotion,
                          60,
                          _HeroArtwork(controller: _ambient),
                        ),
                        const SizedBox(height: 18),
                        _entrance(
                          reduceMotion,
                          110,
                          Column(
                            children: [
                              AnimatedSwitcher(
                                duration: reduceMotion
                                    ? Duration.zero
                                    : const Duration(milliseconds: 260),
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, .08),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    ),
                                child: Text(
                                  _register
                                      ? 'Make room for a better cycle.'
                                      : 'Welcome back.',
                                  key: ValueKey(_register),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.forest,
                                    fontSize: 27,
                                    height: 1.15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -.7,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                _register
                                    ? 'Small actions today. A lighter footprint tomorrow.'
                                    : 'Your next good habit is just around the corner.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.subtitle,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        _entrance(
                          reduceMotion,
                          170,
                          AnimatedSize(
                            duration: reduceMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 240),
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.topCenter,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                20,
                                20,
                                16,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(
                                  color: const Color(0xFFE4ECE5),
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x10174C3C),
                                    blurRadius: 28,
                                    offset: Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _register
                                              ? 'Your details'
                                              : 'Sign in',
                                          style: const TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.text,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.lightGreen,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.eco_rounded,
                                              size: 14,
                                              color: AppColors.primary,
                                            ),
                                            SizedBox(width: 5),
                                            Text(
                                              'ECO MEMBER',
                                              style: TextStyle(
                                                fontSize: 10,
                                                letterSpacing: .8,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.forest,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 17),
                                  if (_register) ...[
                                    _fieldLabel('Full name', required: true),
                                    const SizedBox(height: 7),
                                    _input(
                                      controller: _name,
                                      focusNode: _nameFocus,
                                      hint: 'How should we call you?',
                                      icon: Icons.person_outline_rounded,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      autofillHints: const [AutofillHints.name],
                                      textInputAction: TextInputAction.next,
                                      validator: (value) =>
                                          (value?.trim().length ?? 0) < 2
                                          ? 'Enter your name'
                                          : null,
                                      onFieldSubmitted: (_) =>
                                          _emailFocus.requestFocus(),
                                    ),
                                    const SizedBox(height: 14),
                                  ],
                                  _fieldLabel('Email address', required: true),
                                  const SizedBox(height: 7),
                                  _input(
                                    controller: _email,
                                    focusNode: _emailFocus,
                                    hint: 'you@example.com',
                                    icon: Icons.alternate_email_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    textCapitalization: TextCapitalization.none,
                                    autofillHints: const [AutofillHints.email],
                                    textInputAction: TextInputAction.next,
                                    validator: (value) =>
                                        _validEmail((value ?? '').trim())
                                        ? null
                                        : 'Enter a valid email',
                                    onFieldSubmitted: (_) =>
                                        _passwordFocus.requestFocus(),
                                  ),
                                  const SizedBox(height: 14),
                                  _fieldLabel('Password', required: true),
                                  const SizedBox(height: 7),
                                  _input(
                                    controller: _password,
                                    focusNode: _passwordFocus,
                                    hint: 'At least 8 characters',
                                    icon: Icons.lock_outline_rounded,
                                    textCapitalization: TextCapitalization.none,
                                    obscureText: !_passwordVisible,
                                    autofillHints: [
                                      AutofillHints.password,
                                      if (_register) AutofillHints.newPassword,
                                    ],
                                    textInputAction: TextInputAction.done,
                                    validator: (value) =>
                                        (value?.length ?? 0) >= 8
                                        ? null
                                        : 'Use at least 8 characters',
                                    onFieldSubmitted: (_) => _submit(),
                                    suffix: IconButton(
                                      tooltip: _passwordVisible
                                          ? 'Hide password'
                                          : 'Show password',
                                      onPressed: () => setState(
                                        () => _passwordVisible =
                                            !_passwordVisible,
                                      ),
                                      icon: AnimatedSwitcher(
                                        duration: reduceMotion
                                            ? Duration.zero
                                            : const Duration(milliseconds: 160),
                                        child: Icon(
                                          _passwordVisible
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          key: ValueKey(_passwordVisible),
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                  AnimatedSize(
                                    duration: reduceMotion
                                        ? Duration.zero
                                        : const Duration(milliseconds: 180),
                                    child: _error == null
                                        ? const SizedBox.shrink()
                                        : Padding(
                                            padding: const EdgeInsets.only(
                                              top: 14,
                                            ),
                                            child: Semantics(
                                              liveRegion: true,
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  11,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFFFF0EE,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Icon(
                                                      Icons
                                                          .error_outline_rounded,
                                                      size: 18,
                                                      color: Color(0xFFB42318),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        _error!,
                                                        style: const TextStyle(
                                                          color: Color(
                                                            0xFF9F241B,
                                                          ),
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                  ),
                                  const SizedBox(height: 18),
                                  _SubmitButton(
                                    busy: _busy,
                                    register: _register,
                                    onPressed: _submit,
                                  ),
                                  const SizedBox(height: 4),
                                  TextButton(
                                    onPressed: _busy ? null : _toggleMode,
                                    style: TextButton.styleFrom(
                                      minimumSize: const Size(48, 48),
                                    ),
                                    child: Text(
                                      _register
                                          ? 'Already have an account?  Sign in'
                                          : 'New to ReCircle?  Create a customer account',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppColors.forest,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (!_register) ...[
                          const SizedBox(height: 15),
                          const Text(
                            'Collection partners sign in with their partner account. Accounts are created by the demo administrator.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: AppColors.subtitle,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.recycling_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Nothing ends. It transforms.',
                              style: TextStyle(
                                color: AppColors.subtitle,
                                fontSize: 12,
                                letterSpacing: .2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _entrance(bool reduceMotion, int delayMs, Widget child) {
    if (reduceMotion) return child;
    return TweenAnimationBuilder<double>(
      key: ValueKey('entrance-$delayMs'),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 480 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }

  Widget _fieldLabel(String label, {required bool required}) => Row(
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
      ),
      if (required)
        const Text(
          ' *',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
    ],
  );

  Widget _input({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    required Iterable<String> autofillHints,
    required TextInputAction textInputAction,
    required TextCapitalization textCapitalization,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
    ValueChanged<String>? onFieldSubmitted,
  }) => TextFormField(
    controller: controller,
    focusNode: focusNode,
    validator: validator,
    autofillHints: autofillHints,
    keyboardType: keyboardType,
    textCapitalization: textCapitalization,
    textInputAction: textInputAction,
    obscureText: obscureText,
    autocorrect: false,
    enableSuggestions: !obscureText,
    onFieldSubmitted: onFieldSubmitted,
    style: const TextStyle(fontSize: 14, color: AppColors.text),
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 19, color: AppColors.subtitle),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFFAFCFA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      errorMaxLines: 2,
      hintStyle: const TextStyle(color: Color(0xFF8A9A90), fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDCE7DF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDCE7DF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFB42318)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFB42318), width: 1.5),
      ),
    ),
  );
}

class _SubmitButton extends StatefulWidget {
  const _SubmitButton({
    required this.busy,
    required this.register,
    required this.onPressed,
  });
  final bool busy;
  final bool register;
  final VoidCallback onPressed;

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: widget.busy ? null : (_) => setState(() => _pressed = true),
    onTapCancel: () => setState(() => _pressed = false),
    onTapUp: widget.busy ? null : (_) => setState(() => _pressed = false),
    child: AnimatedScale(
      scale: _pressed ? .985 : 1,
      duration: const Duration(milliseconds: 120),
      child: SizedBox(
        height: 54,
        child: ElevatedButton(
          onPressed: widget.busy ? null : widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: _pressed ? 0 : 3,
            shadowColor: const Color(0x40078A55),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: widget.busy
                ? const Row(
                    key: ValueKey('loading'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Please wait…',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  )
                : Row(
                    key: const ValueKey('ready'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.register ? 'Create my account' : 'Sign in',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 9),
                      const Icon(Icons.arrow_forward_rounded, size: 19),
                    ],
                  ),
          ),
        ),
      ),
    ),
  );
}

class _HeroArtwork extends StatelessWidget {
  const _HeroArtwork({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 154,
    child: AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final drift = MediaQuery.of(context).disableAnimations
            ? 0.0
            : (controller.value - .5) * 8;
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 22,
              top: 20 + drift,
              child: _orb(62, const Color(0xFFDCEFE2)),
            ),
            Positioned(
              right: 28,
              bottom: 13 - drift,
              child: _orb(82, const Color(0xFFEAF4EC)),
            ),
            Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE8F4E9), Color(0xFFD1E9D8)],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .8),
                  width: 5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x18174C3C),
                    blurRadius: 22,
                    offset: Offset(0, 9),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: Offset(0, drift),
              child: Container(
                width: 106,
                height: 106,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1D7651), Color(0xFF0D503C)],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.recycling_rounded,
                      size: 62,
                      color: Colors.white,
                    ),
                    Positioned(
                      right: 11,
                      bottom: 15,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE9B76A),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.eco_rounded,
                          size: 15,
                          color: AppColors.forest,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 66,
              bottom: 21,
              child: _sparkle(7, AppColors.primary, drift),
            ),
            Positioned(
              right: 78,
              top: 20,
              child: _sparkle(5, const Color(0xFFE9B76A), -drift),
            ),
            Positioned(
              right: 12,
              top: 51,
              child: Transform.rotate(
                angle: -.3 + drift * .015,
                child: const Icon(
                  Icons.eco_rounded,
                  size: 24,
                  color: Color(0xFF6B9D75),
                ),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 42,
              child: Transform.rotate(
                angle: .6,
                child: const Icon(
                  Icons.eco_rounded,
                  size: 20,
                  color: Color(0xFF8DB697),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _orb(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withValues(alpha: .86),
    ),
  );

  Widget _sparkle(double size, Color color, double drift) =>
      Transform.translate(
        offset: Offset(0, drift * .5),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      );
}
