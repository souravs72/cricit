import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../l10n/l10n.dart';
import '../../feed/data/fixture_feed.dart';
import '../../feed/presentation/news_card_view.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final settings = ref.watch(settingsProvider);
    final t = Theme.of(context).textTheme;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(CricitSpace.md),
        children: [
          Text(l10n.profileTitle, style: t.headlineMedium),
          const SizedBox(height: CricitSpace.md),
          if (settings.signedIn)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                settings.displayName.isEmpty
                    ? l10n.signedInAs
                    : settings.displayName,
              ),
              subtitle: Text(l10n.signedInAs),
            )
          else
            FilledButton(
              onPressed: () => context.push('/signin'),
              child: Text(l10n.signInCta),
            ),
          const SizedBox(height: CricitSpace.lg),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.language),
            trailing: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'en', label: Text(l10n.english)),
                ButtonSegment(value: 'hi', label: Text(l10n.hindi)),
              ],
              selected: {settings.language},
              onSelectionChanged: (s) =>
                  ref.read(settingsProvider.notifier).setLanguage(s.first),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.notifications),
            value: settings.notifications,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setNotifications(v),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.nightMode),
            trailing: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              onChanged: (v) {
                if (v != null) {
                  ref.read(settingsProvider.notifier).setThemeMode(v);
                }
              },
              items: [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text(l10n.systemTheme),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text(l10n.lightTheme),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text(l10n.darkTheme),
                ),
              ],
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.textSize),
            trailing: DropdownButton<double>(
              value: settings.textScale,
              onChanged: (v) {
                if (v != null) {
                  ref.read(settingsProvider.notifier).setTextScale(v);
                }
              },
              items: [
                DropdownMenuItem(value: 0.9, child: Text(l10n.textSizeS)),
                DropdownMenuItem(value: 1.0, child: Text(l10n.textSizeM)),
                DropdownMenuItem(value: 1.15, child: Text(l10n.textSizeL)),
              ],
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.autoplay),
            value: settings.autoplay,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setAutoplay(v),
          ),
          const SizedBox(height: CricitSpace.md),
          Text(l10n.savedStories, style: t.titleLarge),
          const SizedBox(height: CricitSpace.sm),
          if (settings.bookmarks.isEmpty)
            Text(l10n.noSavedBody, style: t.bodyLarge)
          else
            ...fixtureCards()
                .where((c) => settings.bookmarks.contains(c.id))
                .map(
                  (c) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(c.headline),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => Scaffold(
                          appBar: AppBar(),
                          body: NewsCardView(
                            card: c,
                            saved: true,
                            onToggleSave: () => ref
                                .read(settingsProvider.notifier)
                                .toggleBookmark(c.id),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
          if (settings.signedIn) ...[
            const SizedBox(height: CricitSpace.lg),
            OutlinedButton(
              onPressed: () => ref.read(settingsProvider.notifier).signOut(),
              child: Text(l10n.signOut),
            ),
            const SizedBox(height: CricitSpace.sm),
            TextButton(
              onPressed: () => _confirmDelete(context, ref, l10n),
              child: Text(l10n.deleteAccount),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    L10n l10n,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAccount),
        content: Text(l10n.deleteAccountBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(settingsProvider.notifier).deleteAccount();
    }
  }
}
