import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../l10n/l10n.dart';
import '../data/auth_repository.dart';

final authRepository = AuthRepository();

class PhoneSignInScreen extends StatefulWidget {
  const PhoneSignInScreen({super.key});

  @override
  State<PhoneSignInScreen> createState() => _PhoneSignInScreenState();
}

class _PhoneSignInScreenState extends State<PhoneSignInScreen> {
  final _controller = TextEditingController();
  String? _error;
  var _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = L10n.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await authRepository.sendOtp(_controller.text.trim());
      if (!mounted) return;
      await context.push('/otp?phone=${_controller.text.trim()}');
    } on AuthException catch (e) {
      setState(() {
        _error = switch (e.message) {
          'phone' => l10n.phoneInvalid,
          'locked' => l10n.tooManyAttempts,
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
                  l10n.phoneTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: CricitSpace.sm),
                Text(
                  l10n.phoneBody,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: CricitSpace.lg),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  enableInteractiveSelection: true,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.phoneLabel,
                    hintText: l10n.phoneHint,
                    prefix: Text(
                      '+91',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    errorText: _error,
                    counterText: '',
                  ),
                  onSubmitted: (_) => _send(),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _busy ? null : _send,
                  child: Text(l10n.sendCode),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
