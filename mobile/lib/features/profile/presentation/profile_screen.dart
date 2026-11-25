import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/env.dart';
import '../../../app/theme.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/time/story_time.dart';
import '../../../core/widgets/arrive.dart';
import '../../../core/widgets/youtube_poster.dart';
import '../../../l10n/l10n.dart';
import '../../feed/data/fixture_feed.dart';
import '../../feed/domain/news_card.dart';
import '../../feed/presentation/feed_controller.dart';
import '../../feed/presentation/news_card_view.dart';

const _bioKey = 'profile_bio';
const _teamKey = 'favorite_team';
const _hdKey = 'hd_images';

/// Profile page (brief p.7): who you are, an Edit profile sheet, your saved
/// stories, and an Options page behind the gear.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

enum _SavedFilter { all, articles, reels }

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  var _filter = _SavedFilter.all;
  var _bio = '';
  var _team = '';

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (!mounted) return;
      setState(() {
        _bio = p.getString(_bioKey) ?? '';
        _team = p.getString(_teamKey) ?? '';
      });
    });
  }

  /// Saved cards come from whatever the feeds have loaded (and the dev
  /// fixtures outside production), so saving works offline too.
  List<NewsCard> _savedCards(Set<String> ids) {
    final pool = <String, NewsCard>{};
    for (final tab in const ['feed', 'video', 'domestic', 'nxtspot']) {
      for (final c in ref.watch(feedControllerProvider(tab)).cards) {
        pool.putIfAbsent(c.id, () => c);
      }
    }
    if (!Env.isProd) {
      for (final c in fixtureCards()) {
        pool.putIfAbsent(c.id, () => c);
      }
    }
    return [
      for (final id in ids)
        if (pool[id] != null && !pool[id]!.isAd) pool[id]!,
    ];
  }

  Future<void> _editProfile(BuildContext context, AppSettings settings) async {
    final saved = await showModalBottomSheet<(String, String, String)>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _EditProfileSheet(
        name: settings.displayName,
        bio: _bio,
        team: _team,
      ),
    );
    if (saved == null || !mounted) return;
    final (name, bio, team) = saved;
    await ref.read(settingsProvider.notifier).setDisplayName(name);
    final p = await SharedPreferences.getInstance();
    await p.setString(_bioKey, bio);
    await p.setString(_teamKey, team);
    if (!mounted) return;
    setState(() {
      _bio = bio;
      _team = team;
    });
  }

  void _openOptions(BuildContext context) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const OptionsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final saved = _savedCards(settings.bookmarks);
    final articles = saved.where((c) => !c.isVideo).toList();
    final reels = saved.where((c) => c.isVideo).toList();
    final shown = switch (_filter) {
      _SavedFilter.all => saved,
      _SavedFilter.articles => articles,
      _SavedFilter.reels => reels,
    };
    final name =
        settings.displayName.isEmpty ? l10n.guest : settings.displayName;
    final subtitle = [
      if (_team.isNotEmpty) _team,
      if (_bio.isNotEmpty) _bio,
    ].join(' · ');

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: CricitSpace.xs,
                  right: CricitSpace.xs,
                ),
                child: IconButton(
                  tooltip: l10n.options,
                  onPressed: () => _openOptions(context),
                  icon: const Icon(Icons.settings_outlined),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Arrive(
              child: Column(
                children: [
                  _Avatar(name: settings.displayName),
                  const SizedBox(height: CricitSpace.md),
                  Text(name, style: theme.textTheme.headlineLarge),
                  const SizedBox(height: CricitSpace.xs),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: CricitSpace.xl,
                    ),
                    child: Text(
                      subtitle.isNotEmpty
                          ? subtitle
                          : settings.signedIn
                              ? l10n.signedInAs
                              : l10n.signInCta,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: CricitSpace.md),
                  Wrap(
                    spacing: CricitSpace.sm,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _editProfile(context, settings),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: Text(l10n.editProfile),
                      ),
                      if (!settings.signedIn)
                        FilledButton(
                          onPressed: () => context.push('/signin'),
                          child: Text(l10n.continueWithPhone),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Arrive(
              index: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  CricitSpace.md,
                  CricitSpace.xl,
                  CricitSpace.md,
                  CricitSpace.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.savedStories, style: theme.textTheme.titleLarge),
                    const SizedBox(height: CricitSpace.sm + 4),
                    _FilterBar(
                      value: _filter,
                      counts: {
                        _SavedFilter.all: saved.length,
                        _SavedFilter.articles: articles.length,
                        _SavedFilter.reels: reels.length,
                      },
                      labels: {
                        _SavedFilter.all: l10n.allSaved,
                        _SavedFilter.articles: l10n.articles,
                        _SavedFilter.reels: l10n.reels,
                      },
                      onChanged: (f) {
                        HapticFeedback.selectionClick();
                        setState(() => _filter = f);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (shown.isEmpty)
            SliverToBoxAdapter(
              child: Arrive(
                index: 3,
                child: _SavedEmpty(
                  title: l10n.noSaved,
                  body: l10n.noSavedBody,
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: shown.length,
              itemBuilder: (context, i) {
                final card = shown[i];
                return Arrive(
                  key: ValueKey('saved-${_filter.name}-${card.id}'),
                  index: 3 + i,
                  child: Dismissible(
                    key: ValueKey('dismiss-${card.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: CricitSpace.lg),
                      color: theme.colorScheme.error.withValues(alpha: 0.12),
                      child: Icon(
                        Icons.bookmark_remove_outlined,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    onDismissed: (_) {
                      HapticFeedback.mediumImpact();
                      ref
                          .read(settingsProvider.notifier)
                          .toggleBookmark(card.id);
                    },
                    child: _SavedTile(card: card),
                  ),
                );
              },
            ),
          const SliverToBoxAdapter(child: SizedBox(height: CricitSpace.xxl)),
        ],
      ),
    );
  }
}

/// Initials on outfield green, ringed in scoreboard amber.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final initials = parts.isEmpty
        ? null
        : parts.take(2).map((p) => p[0].toUpperCase()).join();
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: CricitColors.scoreboard,
      ),
      child: CircleAvatar(
        radius: 44,
        backgroundColor: CricitColors.outfield,
        child: initials == null
            ? const Icon(
                Icons.person_rounded,
                size: 44,
                color: CricitColors.onOutfield,
              )
            : Text(
                initials,
                style: const TextStyle(
                  fontFamily: CricitFonts.display,
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                  color: CricitColors.onOutfield,
                ),
              ),
      ),
    );
  }
}

/// Segmented All / Articles / Reels switch with a sliding thumb and counts.
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.value,
    required this.counts,
    required this.labels,
    required this.onChanged,
  });

  final _SavedFilter value;
  final Map<_SavedFilter, int> counts;
  final Map<_SavedFilter, String> labels;
  final ValueChanged<_SavedFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    const values = _SavedFilter.values;
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CricitRadius.full),
        border: Border.all(color: theme.dividerColor),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth / values.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                left: w * values.indexOf(value),
                top: 0,
                bottom: 0,
                width: w,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(CricitRadius.full),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final f in values)
                    Expanded(
                      child: Semantics(
                        selected: f == value,
                        button: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onChanged(f),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontFamily: CricitFonts.body,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: f == value
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              child: Text('${labels[f]} ${counts[f]}'),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SavedTile extends StatelessWidget {
  const _SavedTile({required this.card});

  final NewsCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumb = card.image ??
        (card.videoId == null ? null : youTubePosterUrl(card.videoId!));
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CricitSpace.md,
        vertical: CricitSpace.sm,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(CricitRadius.md - 4),
            child: SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (thumb == null)
                    ColoredBox(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    )
                  else
                    CachedNetworkImage(
                      imageUrl: thumb,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => ColoredBox(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  if (card.isVideo)
                    const Center(
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: CricitSpace.md - 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.headline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(height: 1.3),
                ),
                const SizedBox(height: CricitSpace.xs),
                Row(
                  children: [
                    SourceMonogram(name: card.sourceName ?? 'CRICIT', size: 16),
                    const SizedBox(width: CricitSpace.xs + 2),
                    Flexible(
                      child: Text(
                        '${card.sourceName ?? 'CRICIT'} · ${storyTimeLabel(card.publishedAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedEmpty extends StatelessWidget {
  const _SavedEmpty({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CricitSpace.xl,
        vertical: CricitSpace.xl,
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bookmark_border_rounded,
              size: 30,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: CricitSpace.md),
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: CricitSpace.xs),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Edit profile (brief p.7): name, bio and your team. Pops (name, bio, team).
class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({
    required this.name,
    required this.bio,
    required this.team,
  });

  final String name;
  final String bio;
  final String team;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  static const _teams = [
    'India',
    'Mumbai',
    'Karnataka',
    'Tamil Nadu',
    'Delhi',
    'Bengal',
    'Vidarbha',
    'CSK',
    'MI',
    'RCB',
    'KKR',
  ];
  late final _name = TextEditingController(text: widget.name);
  late final _bio = TextEditingController(text: widget.bio);
  late var _team = widget.team;

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        CricitSpace.lg,
        0,
        CricitSpace.lg,
        MediaQuery.of(context).viewInsets.bottom + CricitSpace.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.editProfile, style: theme.textTheme.headlineMedium),
          const SizedBox(height: CricitSpace.md),
          TextField(
            controller: _name,
            maxLength: 30,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l10n.nameLabel),
          ),
          const SizedBox(height: CricitSpace.sm),
          TextField(
            controller: _bio,
            maxLength: 150,
            maxLines: 3,
            minLines: 2,
            decoration: InputDecoration(labelText: l10n.bioLabel),
          ),
          const SizedBox(height: CricitSpace.sm),
          Wrap(
            spacing: CricitSpace.sm,
            runSpacing: CricitSpace.xs,
            children: [
              for (final t in _teams)
                ChoiceChip(
                  label: Text(t),
                  selected: _team == t,
                  onSelected: (on) {
                    HapticFeedback.selectionClick();
                    setState(() => _team = on ? t : '');
                  },
                ),
            ],
          ),
          const SizedBox(height: CricitSpace.lg),
          FilledButton(
            onPressed: () => Navigator.of(context)
                .pop((_name.text.trim(), _bio.text.trim(), _team)),
            child: Text(l10n.submit),
          ),
        ],
      ),
    );
  }
}

/// Options (brief p.7): language, notifications, preferences, HD images,
/// night mode, autoplay, text size, share, account.
class OptionsScreen extends ConsumerStatefulWidget {
  const OptionsScreen({super.key});

  @override
  ConsumerState<OptionsScreen> createState() => _OptionsScreenState();
}

class _OptionsScreenState extends ConsumerState<OptionsScreen> {
  var _hd = true;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _hd = p.getBool(_hdKey) ?? true);
    });
  }

  Future<void> _setHd(bool v) async {
    setState(() => _hd = v);
    final p = await SharedPreferences.getInstance();
    await p.setBool(_hdKey, v);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    Widget group(int i, List<Widget> children) => Arrive(
          index: i,
          child: Container(
            margin: const EdgeInsets.fromLTRB(
              CricitSpace.md,
              0,
              CricitSpace.md,
              CricitSpace.md,
            ),
            child: Material(
              color: theme.colorScheme.surface,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(CricitRadius.md),
                side: BorderSide(color: theme.dividerColor),
              ),
              child: Column(
                children: [
                  for (var n = 0; n < children.length; n++) ...[
                    if (n > 0)
                      Divider(height: 1, indent: 56, color: theme.dividerColor),
                    children[n],
                  ],
                ],
              ),
            ),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.options)),
      body: ListView(
        padding: const EdgeInsets.only(top: CricitSpace.sm),
        children: [
          group(0, [
            _OptionRow(
              icon: Icons.translate_rounded,
              title: l10n.language,
              below: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: 'en', label: Text(l10n.english)),
                  const ButtonSegment(
                    value: 'hi',
                    label: Text(
                      'हिन्दी',
                      style: TextStyle(fontFamily: CricitFonts.hindi),
                    ),
                  ),
                ],
                selected: {settings.language},
                onSelectionChanged: (s) => notifier.setLanguage(s.first),
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.notifications_none_rounded),
              title: Text(l10n.notifications),
              value: settings.notifications,
              onChanged: notifier.setNotifications,
            ),
          ]),
          group(1, [
            SwitchListTile(
              secondary: const Icon(Icons.hd_outlined),
              title: Text(l10n.hdImages),
              value: _hd,
              onChanged: _setHd,
            ),
            _OptionRow(
              icon: Icons.dark_mode_outlined,
              title: l10n.nightMode,
              below: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(l10n.systemTheme),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(l10n.lightTheme),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(l10n.darkTheme),
                  ),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (s) => notifier.setThemeMode(s.first),
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.play_circle_outline_rounded),
              title: Text(l10n.autoplay),
              value: settings.autoplay,
              onChanged: notifier.setAutoplay,
            ),
            _OptionRow(
              icon: Icons.format_size_rounded,
              title: l10n.textSize,
              below: SegmentedButton<double>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: 0.9, label: Text(l10n.textSizeS)),
                  ButtonSegment(value: 1.0, label: Text(l10n.textSizeM)),
                  ButtonSegment(value: 1.15, label: Text(l10n.textSizeL)),
                ],
                selected: {settings.textScale},
                onSelectionChanged: (s) => notifier.setTextScale(s.first),
              ),
            ),
          ]),
          group(2, [
            ListTile(
              leading: const Icon(Icons.ios_share_rounded),
              title: Text(l10n.shareApp),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                HapticFeedback.lightImpact();
                Share.share(
                  'CRICIT: cricket news in one-minute cards, short videos and grassroots cricket. https://cricit.app',
                  subject: 'CRICIT',
                );
              },
            ),
          ]),
          if (settings.signedIn)
            group(3, [
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: Text(l10n.signOut),
                onTap: () {
                  notifier.signOut();
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  l10n.deleteAccount,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onTap: () => _confirmDelete(context, l10n),
              ),
            ]),
          const SizedBox(height: CricitSpace.xl),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, L10n l10n) async {
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
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      unawaited(ref.read(settingsProvider.notifier).deleteAccount());
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.title,
    this.below,
  });

  final IconData icon;
  final String title;
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CricitSpace.md,
        CricitSpace.sm + 4,
        CricitSpace.md,
        CricitSpace.sm + 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: CricitSpace.md),
              Expanded(
                child: Text(title, style: theme.textTheme.titleMedium),
              ),
            ],
          ),
          if (below != null) ...[
            const SizedBox(height: CricitSpace.sm + 2),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: SizedBox(width: double.infinity, child: below),
            ),
          ],
        ],
      ),
    );
  }
}
