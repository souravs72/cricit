import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../l10n/l10n.dart';
import '../../feed/data/fixture_feed.dart';
import '../../feed/presentation/news_card_view.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _hdImages = true;
  String _favoriteTeam = 'India';

  void _showEditProfileDialog(BuildContext context, String currentName) {
    final nameCtrl = TextEditingController(text: currentName.isEmpty ? 'Cricket Fan' : currentName);
    final bioCtrl = TextEditingController(text: 'Passionate about Indian cricket, Ranji Trophy & IPL');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + CricitSpace.lg,
          left: CricitSpace.lg,
          right: CricitSpace.lg,
          top: CricitSpace.lg,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: CricitSpace.md),
            const Text(
              'Edit Profile',
              style: TextStyle(
                fontFamily: CricitFonts.display,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: CricitSpace.md),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: CricitSpace.md),
            TextField(
              controller: bioCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Your Bio',
                prefixIcon: Icon(Icons.edit_note),
              ),
            ),
            const SizedBox(height: CricitSpace.lg),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: CricitColors.outfield,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                ref.read(settingsProvider.notifier).setDisplayName(nameCtrl.text.trim());
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully!')),
                );
              },
              child: const Text('Save Profile'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPreferencesSheet(BuildContext context) {
    final teams = ['India', 'CSK', 'MI', 'RCB', 'KKR', 'GT', 'RR', 'Nxtspot Grassroots'];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(CricitSpace.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Your Cricket Preferences',
              style: TextStyle(
                fontFamily: CricitFonts.display,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: CricitSpace.xs),
            const Text(
              'Select your favorite teams to prioritize their stories in My Feed.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: CricitSpace.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in teams)
                  FilterChip(
                    label: Text(t),
                    selected: _favoriteTeam == t,
                    onSelected: (val) {
                      setState(() => _favoriteTeam = t);
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final savedCards = fixtureCards()
        .where((c) => settings.bookmarks.contains(c.id))
        .toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: CricitSpace.md, vertical: CricitSpace.sm),
        children: [
          // User Profile Card Header (from Inshorts Page 7)
          Container(
            padding: const EdgeInsets.all(CricitSpace.md),
            decoration: BoxDecoration(
              color: isDark ? CricitColors.surfaceDark : CricitColors.surface,
              borderRadius: BorderRadius.circular(CricitRadius.md),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: CricitColors.outfield,
                  child: Icon(
                    Icons.person,
                    size: 34,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: CricitSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            settings.displayName.isEmpty ? '+91 98362 36167' : settings.displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            size: 16,
                            color: Color(0xFF60A5FA),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Favorite: $_favoriteTeam · Cricket Fan',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? CricitColors.inkMutedDark : CricitColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _showEditProfileDialog(context, settings.displayName),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, size: 12, color: CricitColors.outfield),
                            SizedBox(width: 4),
                            Text(
                              'Edit Profile',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: CricitColors.outfield,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!settings.signedIn)
                  FilledButton.tonal(
                    onPressed: () => context.push('/signin'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: Text(l10n.signInCta),
                  ),
              ],
            ),
          ),
          const SizedBox(height: CricitSpace.lg),

          // Saved Stories / Bookmarks Shelf
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SAVED STORIES (${savedCards.length})',
                style: const TextStyle(
                  fontFamily: CricitFonts.display,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              if (savedCards.isNotEmpty)
                const Icon(Icons.bookmark, size: 16, color: CricitColors.scoreboard),
            ],
          ),
          const SizedBox(height: CricitSpace.sm),

          if (savedCards.isEmpty)
            Container(
              padding: const EdgeInsets.all(CricitSpace.lg),
              decoration: BoxDecoration(
                color: isDark ? CricitColors.surfaceDark : CricitColors.sightscreen,
                borderRadius: BorderRadius.circular(CricitRadius.md),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 40,
                    color: Colors.grey,
                  ),
                  SizedBox(height: CricitSpace.sm),
                  Text(
                    "It's Empty Here",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Click on the bookmark icon to bookmark a 1-minute cricket read.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            ...savedCards.map(
              (c) => Card(
                margin: const EdgeInsets.only(bottom: CricitSpace.sm),
                elevation: 0,
                color: isDark ? CricitColors.surfaceDark : CricitColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(CricitRadius.md),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: c.image != null
                        ? Image.network(
                            c.image!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.grey),
                          )
                        : const ColoredBox(color: Colors.grey),
                  ),
                  title: Text(
                    c.headline,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${c.sourceName ?? "CRICIT"} · ${c.category}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.bookmark, color: CricitColors.scoreboard, size: 20),
                    tooltip: 'Remove bookmark',
                    onPressed: () => ref.read(settingsProvider.notifier).toggleBookmark(c.id),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        appBar: AppBar(),
                        body: NewsCardView(
                          card: c,
                          saved: true,
                          onToggleSave: () =>
                              ref.read(settingsProvider.notifier).toggleBookmark(c.id),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: CricitSpace.lg),

          // Options & Settings List (Page 7 from PDF)
          const Text(
            'OPTIONS & SETTINGS',
            style: TextStyle(
              fontFamily: CricitFonts.display,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: CricitSpace.sm),

          Container(
            decoration: BoxDecoration(
              color: isDark ? CricitColors.surfaceDark : CricitColors.surface,
              borderRadius: BorderRadius.circular(CricitRadius.md),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              children: [
                // Language
                ListTile(
                  leading: const Icon(Icons.translate),
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
                const Divider(height: 1),

                // Notifications
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: Text(l10n.notifications),
                  value: settings.notifications,
                  onChanged: (v) =>
                      ref.read(settingsProvider.notifier).setNotifications(v),
                ),
                const Divider(height: 1),

                // Preferences
                ListTile(
                  leading: const Icon(Icons.tune),
                  title: const Text('Your Preferences'),
                  subtitle: Text('Favorite: $_favoriteTeam'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showPreferencesSheet(context),
                ),
                const Divider(height: 1),

                // HD Images
                SwitchListTile(
                  secondary: const Icon(Icons.hd_outlined),
                  title: const Text('HD Images'),
                  subtitle: const Text('Save data on slower mobile networks'),
                  value: _hdImages,
                  onChanged: (v) => setState(() => _hdImages = v),
                ),
                const Divider(height: 1),

                // Night Mode
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: Text(l10n.nightMode),
                  trailing: DropdownButton<ThemeMode>(
                    value: settings.themeMode,
                    underline: const SizedBox(),
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
                const Divider(height: 1),

                // Autoplay
                ListTile(
                  leading: const Icon(Icons.play_circle_outline),
                  title: Text(l10n.autoplay),
                  trailing: DropdownButton<bool>(
                    value: settings.autoplay,
                    underline: const SizedBox(),
                    onChanged: (v) {
                      if (v != null) {
                        ref.read(settingsProvider.notifier).setAutoplay(v);
                      }
                    },
                    items: const [
                      DropdownMenuItem(value: false, child: Text('Off')),
                      DropdownMenuItem(value: true, child: Text('Wi-Fi / Mobile')),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Text Size
                ListTile(
                  leading: const Icon(Icons.text_fields),
                  title: Text(l10n.textSize),
                  trailing: DropdownButton<double>(
                    value: settings.textScale,
                    underline: const SizedBox(),
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
                const Divider(height: 1),

                // Share App
                ListTile(
                  leading: const Icon(Icons.share_outlined),
                  title: const Text('Share this app'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Share.share(
                      'Download CRICIT — 1-minute cricket reads & viral video shorts from BCCI, IPL & Grassroots! https://cricit.app',
                      subject: 'CRICIT App',
                    );
                  },
                ),
              ],
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
              child: Text(
                l10n.deleteAccount,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
          const SizedBox(height: CricitSpace.xxl),
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
