import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/database/database_helper.dart';
import '../../../providers/app_providers.dart';
import '../splash/splash_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _pageTurnAnimation = true;
  bool _showProgressBar = false;
  int _totalStorageUsed = 0;
  String _appVersion = '1.0.0';
  String _buildNumber = '1';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadReaderSettings();
      _loadStorageInfo();
      _loadPackageInfo();
    });
  }

  Future<void> _loadReaderSettings() async {
    final prefs = await getPrefs();
    if (!mounted) return;
    setState(() {
      _pageTurnAnimation = prefs.getBool(AppConstants.keyPageTurnAnimation) ?? true;
      _showProgressBar = prefs.getBool(AppConstants.keyShowProgressBar) ?? false;
    });
  }

  Future<void> _loadStorageInfo() async {
    try {
      final total = await DatabaseHelper.getDownloadedStorageUsed();
      if (mounted) setState(() => _totalStorageUsed = total);
    } catch (_) {}
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = info.version;
          _buildNumber = info.buildNumber;
        });
      }
    } catch (_) {}
  }

  Future<void> _savePageTurnAnimation(bool value) async {
    final prefs = await getPrefs();
    await prefs.setBool(AppConstants.keyPageTurnAnimation, value);
  }

  Future<void> _saveShowProgressBar(bool value) async {
    final prefs = await getPrefs();
    await prefs.setBool(AppConstants.keyShowProgressBar, value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      body: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsetsDirectional.only(
                start: AppConstants.responsiveMargin(context),
                top: 12,
                end: AppConstants.responsiveMargin(context),
                bottom: 0,
              ),
              child: Column(
                children: [
                  Center(
                    child: SizedBox(
                      height: 40,
                      child: Image.asset(
                        'assets/logos/header_logo_full.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                           LucideIcons.bookOpen,
                          size: 32,
                          color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.stackSm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(bottom: AppConstants.stackMd),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Text(
                      l10n.settingsTitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headlineLarge(context).copyWith(
                        color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Settings Sections ──
          SliverPadding(
            padding: EdgeInsets.all(AppConstants.responsiveMargin(context)),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Account ──
                _SettingsSection(
                  title: l10n.account,
                   icon: LucideIcons.user,
                  children: [
                    // User Info
                    if (authState.status == AuthStatus.authenticated) ...[
                      _buildUserInfo(context, authState),
                      const SizedBox(height: 12),
                      _SettingsTile(
                        label: l10n.googleDrive,
                        subtitle: l10n.connected,
                         trailing: Icon(LucideIcons.checkCircle,
                            color: isDark ? AppColors.darkSuccess : AppColors.success, size: 20),
                      ),
                    ] else if (authState.status == AuthStatus.unknown)
                      _SettingsTile(
                        label: l10n.googleAccount,
                        subtitle: '',
                        trailing: const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else if (authState.status == AuthStatus.unauthenticated)
                      _SettingsTile(
                        label: l10n.googleAccount,
                        subtitle: l10n.notConnected,
                        trailing: OutlinedButton(
                          onPressed: () => _signIn(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
                          child: Text(
                            l10n.signIn,
                            style: AppTextStyles.labelMedium(context).copyWith(
                              color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: AppConstants.stackMd),

                // ── Appearance ──
                _SettingsSection(
                  title: l10n.appearance,
                   icon: LucideIcons.palette,
                  children: [
                    // Theme
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.theme,
                            style: AppTextStyles.bodyMedium(context).copyWith(
                              color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _ThemeOption(
                                  label: l10n.lightMode,
                                  isSelected: themeMode == ThemeMode.light,
                                  onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _ThemeOption(
                                  label: l10n.darkMode,
                                  isSelected: themeMode == ThemeMode.dark,
                                  onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _ThemeOption(
                                  label: l10n.systemDefault,
                                  isSelected: themeMode == ThemeMode.system,
                                  onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Language
                    _SettingsTile(
                      label: l10n.language,
                      subtitle: locale.languageCode == 'ar'
                          ? 'العربية'
                          : locale.languageCode == 'fr'
                              ? 'Français'
                              : 'English',
                      trailing: DropdownButton<Locale>(
                        value: locale,
                        underline: const SizedBox(),
                        dropdownColor: isDark
                            ? AppColors.darkSurfaceContainerHigh
                            : AppColors.surfaceContainerLow,
                        items: const [
                          DropdownMenuItem(value: Locale('ar'), child: Text('العربية')),
                          DropdownMenuItem(value: Locale('en'), child: Text('English')),
                          DropdownMenuItem(value: Locale('fr'), child: Text('Français')),
                        ],
                        onChanged: (newLocale) {
                          if (newLocale != null) {
                            ref.read(localeProvider.notifier).setLocale(newLocale);
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppConstants.stackMd),

                // ── Reader ──
                _SettingsSection(
                  title: l10n.reader,
                   icon: LucideIcons.bookOpen,
                  children: [
                    _SettingsSwitch(
                      label: l10n.pageTurnAnimation,
                      value: _pageTurnAnimation,
                      onChanged: (v) {
                        setState(() => _pageTurnAnimation = v);
                        _savePageTurnAnimation(v);
                      },
                    ),
                    _SettingsSwitch(
                      label: l10n.showProgressBar,
                      value: _showProgressBar,
                      onChanged: (v) {
                        setState(() => _showProgressBar = v);
                        _saveShowProgressBar(v);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: AppConstants.stackMd),

                // ── Storage ──
                _SettingsSection(
                  title: l10n.storage,
                   icon: LucideIcons.hardDrive,
                  children: [
                    _SettingsTile(
                      label: l10n.storage,
                      subtitle: _formatStorageSize(_totalStorageUsed),
                    ),
                  ],
                ),

                const SizedBox(height: AppConstants.stackMd),

                // ── About ──
                _SettingsSection(
                  title: l10n.about,
                   icon: LucideIcons.info,
                  children: [
                    _SettingsTile(
                      label: l10n.versionLabel,
                      subtitle: _appVersion,
                    ),
                    _SettingsTile(
                      label: l10n.buildLabel,
                      subtitle: _buildNumber,
                    ),
                  ],
                ),

                const SizedBox(height: AppConstants.stackMd),

                // ── Sign Out ──
                if (authState.status == AuthStatus.authenticated)
                  Center(
                    child: OutlinedButton(
                      onPressed: () => _signOut(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isDark ? AppColors.darkError : AppColors.error),
                        foregroundColor: isDark ? AppColors.darkError : AppColors.error,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: Text(
                        l10n.signOut,
                        style: AppTextStyles.labelMedium(context),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context, AuthState authState) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
        border: Border.all(
          color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceContainerHighest : AppColors.surfaceContainerHighest,
              border: Border.all(
                color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                width: 1,
              ),
            ),
            child: authState.photo != null
                ? Image.network(
                    authState.photo!,
                    fit: BoxFit.cover,
                     errorBuilder: (context, error, stackTrace) => Icon(LucideIcons.user,
                        color: isDark ? AppColors.darkOnSurface : AppColors.onSurface),
                  )
                 : Icon(LucideIcons.user,
                    color: isDark ? AppColors.darkOnSurface : AppColors.onSurface),
          ),
          const SizedBox(width: 16),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authState.name ?? l10n.defaultUserName,
                  style: AppTextStyles.titleLarge(context).copyWith(
                    color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  authState.email ?? '',
                  style: AppTextStyles.labelSmall(context).copyWith(
                    color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signIn() async {
    final l10n = AppLocalizations.of(context);
    await ref.read(authProvider.notifier).signIn();
    if (!mounted) return;
    final authState = ref.read(authProvider);
    if (authState.status == AuthStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.error ?? l10n.signInFailed),
          backgroundColor: AppColors.error,
        ),
      );
    } else if (authState.status == AuthStatus.unauthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.signingCancelled)),
      );
    } else if (authState.status == AuthStatus.authenticated) {
      ref.invalidate(booksProvider);
      ref.invalidate(continueReadingProvider);
    }
  }

  Future<void> _signOut() async {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.signOut),
        content: Text(l10n.signOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.signOut, style: TextStyle(color: isDark ? AppColors.darkError : AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(authProvider.notifier).signOut();
        // Invalidate dependent providers so they reset to empty
        ref.invalidate(booksProvider);
        ref.invalidate(continueReadingProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.signedOut)),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const SplashScreen(),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.genericError), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  String _formatStorageSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

// ════════════════════════════════════════════
// SETTINGS SECTION
// ════════════════════════════════════════════
class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
        border: Border.all(
          color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top highlight ──
          Container(
            height: 1,
            width: double.infinity,
            color: isDark
                ? AppColors.darkOnSurface.withValues(alpha: 0.12)
                : AppColors.onSurface.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 12),
          // ── Section Title ──
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isDark ? AppColors.darkTertiary : AppColors.antiqueGold,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.titleMedium(context).copyWith(
                    color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════
// SETTINGS TILE
// ════════════════════════════════════════════
class _SettingsTile extends StatelessWidget {
  final String label;
  final String? subtitle;
  final Widget? trailing;

  const _SettingsTile({
    required this.label,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTextStyles.labelSmall(context).copyWith(
                        color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                      ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════
// SETTINGS SWITCH
// ════════════════════════════════════════════
class _SettingsSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
            activeTrackColor: isDark ? AppColors.darkSurfaceContainerHighest : AppColors.surfaceContainerHighest,
            inactiveThumbColor: isDark ? AppColors.darkOutline : AppColors.outline,
            inactiveTrackColor: isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerHigh,
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════
// THEME OPTION
// ════════════════════════════════════════════
class _ThemeOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.darkOnSurface : AppColors.onSurface)
                : (isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant),
            width: isSelected ? 1 : 0.5,
          ),
          color: isDark ? AppColors.darkSurface : AppColors.surface,
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall(context).copyWith(
            color: isSelected
                ? (isDark ? AppColors.darkOnSurface : AppColors.onSurface)
                : (isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}
