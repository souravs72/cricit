import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../l10n/l10n.dart';
import '../data/auth_repository.dart';
import 'phone_sign_in_screen.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phone});

  final String phone;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _controller = TextEditingController();
  String? _error;
  var _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final l10n = L10n.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await authRepository.verifyOtp(widget.phone, _controller.text.trim());
      if (!mounted) return;
      await ref
          .read(settingsProvider.notifier)
          .completeOnboarding(signedIn: true);
      if (mounted) context.go('/setup');
    } on AuthException catch (e) {
      setState(() {
        _error = switch (e.message) {
          'otp' => l10n.wrongOtp,
          'locked' => l10n.tooManyAttempts,
          'phone' => l10n.phoneInvalid,
          _ => l10n.authOffline,
        };
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(CricitSpace.lg),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.otpTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: CricitSpace.sm),
                Text(
                  l10n.otpBody,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: CricitSpace.lg),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  enableInteractiveSelection: true,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.otpLabel,
                    errorText: _error,
                    counterText: '',
                  ),
                  onSubmitted: (_) => _verify(),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _busy ? null : _verify,
                  child: Text(l10n.verifyCode),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
