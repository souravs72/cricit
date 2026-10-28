import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../l10n/l10n.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: Theme.of(context).colorScheme.primary,
            child: const SizedBox(height: 4),
          ),
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(CricitSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    Text(
                      l10n.appName,
                      style: t.headlineLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: CricitSpace.md),
                    Text(l10n.welcomeTitle, style: t.titleLarge),
                    const SizedBox(height: CricitSpace.sm),
                    Text(l10n.welcomeBody, style: t.bodyLarge),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => context.push('/signin'),
                      child: Text(l10n.continueWithPhone),
                    ),
                    const SizedBox(height: CricitSpace.sm),
                    OutlinedButton(
                      onPressed: () async {
                        await ref
                            .read(settingsProvider.notifier)
                            .completeOnboarding();
                        if (context.mounted) context.go('/home');
                      },
                      child: Text(l10n.skipForNow),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
