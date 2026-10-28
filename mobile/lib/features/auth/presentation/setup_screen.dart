import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../l10n/l10n.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _done() async {
    await ref
        .read(settingsProvider.notifier)
        .setDisplayName(_controller.text.trim());
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(CricitSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.setupTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: CricitSpace.sm),
              Text(
                l10n.setupBody,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: CricitSpace.lg),
              TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                decoration: InputDecoration(labelText: l10n.nameLabel),
                onSubmitted: (_) => _done(),
              ),
              const Spacer(),
              FilledButton(onPressed: _done, child: Text(l10n.saveAndContinue)),
              const SizedBox(height: CricitSpace.sm),
              TextButton(
                onPressed: () => context.go('/home'),
                child: Text(l10n.skipForNow),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
