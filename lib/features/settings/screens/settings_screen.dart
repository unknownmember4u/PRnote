import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prnote/core/theme/theme_provider.dart';
import 'package:prnote/core/constants/app_constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prnote/core/widgets/prnote_logo.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, topPadding + (size.height * 0.02), 16, 100),
        physics: const BouncingScrollPhysics(),
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              'Settings',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: theme.textTheme.displayLarge?.color,
                letterSpacing: -0.3,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 20),
            child: Text(
              'Customize your experience',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
            ),
          ),

          // App info card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.12),
                  theme.colorScheme.secondary.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                const PRnoteLogo(fontSize: 22.0),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'v${AppConstants.appVersion}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Appearance section
          _buildSectionHeader('Appearance', Icons.palette_outlined, theme),
          const SizedBox(height: 12),
          _buildThemeSelector(context, ref, currentTheme, theme, isLight),
          const SizedBox(height: 28),

          // General section
          _buildSectionHeader('General', Icons.tune_rounded, theme),
          const SizedBox(height: 12),
          _SettingsGroup(
            theme: theme,
            isLight: isLight,
            children: [
              _SettingsTile(
                icon: Icons.timer_outlined,
                title: 'Auto-save interval',
                subtitle: '${AppConstants.autoSaveInterval.inSeconds} seconds',
                theme: theme,
              ),
              _divider(theme),
              _SettingsTile(
                icon: Icons.history_rounded,
                title: 'Version history',
                subtitle: 'Keep track of note changes',
                theme: theme,
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Data section
          _buildSectionHeader('Data', Icons.storage_rounded, theme),
          const SizedBox(height: 12),
          _SettingsGroup(
            theme: theme,
            isLight: isLight,
            children: [
              _SettingsTile(
                icon: Icons.cloud_off_outlined,
                title: 'Offline storage',
                subtitle: 'All data stored locally on device',
                theme: theme,
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF26A69A).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Active',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF26A69A),
                    ),
                  ),
                ),
              ),
              _divider(theme),
              _SettingsTile(
                icon: Icons.delete_sweep_outlined,
                title: 'Clear deleted notes',
                subtitle: 'Permanently remove trashed notes',
                theme: theme,
                iconColor: theme.colorScheme.error,
              ),
            ],
          ),
          const SizedBox(height: 28),

          // About section
          _buildSectionHeader('About', Icons.info_outline_rounded, theme),
          const SizedBox(height: 12),
          _SettingsGroup(
            theme: theme,
            isLight: isLight,
            children: [
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'About PRnote',
                subtitle: 'A powerful offline-first note-taking app',
                theme: theme,
              ),
              _divider(theme),
              _SettingsTile(
                icon: Icons.code_rounded,
                title: 'Open source licenses',
                subtitle: 'Third-party software',
                theme: theme,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _divider(ThemeData theme) {
    return Divider(
      height: 1,
      indent: 56,
      color: theme.dividerColor.withValues(alpha: 0.2),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(icon, size: 14,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5)),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(
      BuildContext context, WidgetRef ref, AppThemeMode current, ThemeData theme, bool isLight) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6, offset: const Offset(0, 2)),
              ]
            : null,
      ),
      child: Row(
        children: [
          _buildThemeOption(
            context, ref, 'Light', Icons.wb_sunny_rounded,
            AppThemeMode.light, current == AppThemeMode.light, theme,
          ),
          _buildThemeOption(
            context, ref, 'AMOLED', Icons.dark_mode_rounded,
            AppThemeMode.amoled, current == AppThemeMode.amoled, theme,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, WidgetRef ref,
    String label, IconData icon,
    AppThemeMode mode, bool isSelected, ThemeData theme,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(themeProvider.notifier).setTheme(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            border: isSelected
                ? Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3))
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Settings Group Card ────────────────────────────
class _SettingsGroup extends StatelessWidget {
  final ThemeData theme;
  final bool isLight;
  final List<Widget> children;

  const _SettingsGroup({
    required this.theme,
    required this.isLight,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: isLight ? 0.3 : 0.2),
          width: 0.5,
        ),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: children),
      ),
    );
  }
}

// ─── Settings Tile ──────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final ThemeData theme;
  final Widget? trailing;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.theme,
    this.trailing,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.55),
          ),
        ),
        trailing: trailing ??
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.3),
            ),
      ),
    );
  }
}
