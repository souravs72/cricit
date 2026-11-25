import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<void> _openStream() async {
    await HapticFeedback.lightImpact();
    final uri = Uri.parse(authRepository.channelUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _resend() async {
    await HapticFeedback.selectionClick();
    setState(() => _busy = true);
    try {
      await authRepository.sendOtp(widget.phone);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New 6-digit verification code dispatched!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      // Ignored
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeCode = authRepository.activeOtp;

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
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: CricitSpace.xs),
                Text(
                  'Sent to +91 ${widget.phone}. Enter the 6-digit code below.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? CricitColors.inkMutedDark
                        : CricitColors.inkMuted,
                  ),
                ),
                const SizedBox(height: CricitSpace.md),

                // Free Real-Time Message Notification Channel Card
                Container(
                  padding: const EdgeInsets.all(CricitSpace.md),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF132A1E)
                        : const Color(0xFFEBF7F0),
                    borderRadius: BorderRadius.circular(CricitRadius.md),
                    border: Border.all(
                      color: CricitColors.outfield.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: CricitColors.outfield,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_active,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Free Live Message Stream (ntfy.sh)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: CricitColors.outfield,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your real OTP has been broadcast to your private notification channel. Open to view or receive real notifications on your device.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: isDark ? Colors.white70 : CricitColors.ink,
                        ),
                      ),
                      const SizedBox(height: CricitSpace.sm),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _openStream,
                              icon: const Icon(Icons.open_in_new, size: 14),
                              label: const Text(
                                'View Incoming Message',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                side: const BorderSide(
                                  color: CricitColors.outfield,
                                ),
                                foregroundColor: CricitColors.outfield,
                              ),
                            ),
                          ),
                          if (activeCode != null) ...[
                            const SizedBox(width: CricitSpace.sm),
                            FilledButton.tonal(
                              onPressed: () {
                                _controller.text = activeCode;
                                _verify();
                              },
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                backgroundColor: CricitColors.scoreboard,
                                foregroundColor: CricitColors.ink,
                              ),
                              child: Text(
                                'Auto-Fill $activeCode',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: CricitSpace.md),

                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  enableInteractiveSelection: true,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.otpLabel,
                    hintText: '6-digit OTP code',
                    errorText: _error,
                    counterText: '',
                  ),
                  onSubmitted: (_) => _verify(),
                ),
                const SizedBox(height: CricitSpace.sm),

                // Resend Code action
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _busy ? null : _resend,
                    icon: const Icon(Icons.refresh, size: 14),
                    label: const Text('Resend Code'),
                  ),
                ),

                const Spacer(),
                FilledButton(
                  onPressed: _busy ? null : _verify,
                  style: FilledButton.styleFrom(
                    backgroundColor: CricitColors.outfield,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.verifyCode),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
