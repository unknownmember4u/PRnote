import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prnote/core/theme/theme_provider.dart';
import 'package:prnote/core/constants/app_constants.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          physics: const BouncingScrollPhysics(),
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 24),
              child: Text(
                'Settings',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: theme.textTheme.displayLarge?.color,
                ),
              ),
            ),

            // App info card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFC107).withValues(alpha: 0.15),
                    const Color(0xFF5C6BC0).withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/splash_logo.png',
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'PR',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFFFC107),
                              ),
                            ),
                            TextSpan(
                              text: 'note',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w300,
                                color: theme.textTheme.titleLarge?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Version ${AppConstants.appVersion}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Appearance section
            _buildSectionHeader('Appearance', theme),
            const SizedBox(height: 12),
            _buildThemeSelector(context, ref, currentTheme, theme),
            const SizedBox(height: 24),

            // General section
            _buildSectionHeader('General', theme),
            const SizedBox(height: 12),
            _buildSettingsTile(
              context,
              icon: Icons.timer_outlined,
              title: 'Auto-save interval',
              subtitle: '${AppConstants.autoSaveInterval.inSeconds} seconds',
              theme: theme,
            ),
            _buildSettingsTile(
              context,
              icon: Icons.history_rounded,
              title: 'Version history',
              subtitle: 'Keep track of note changes',
              theme: theme,
            ),
            const SizedBox(height: 24),

            // Data section
            _buildSectionHeader('Data', theme),
            const SizedBox(height: 12),
            _buildSettingsTile(
              context,
              icon: Icons.cloud_off_outlined,
              title: 'Offline storage',
              subtitle: 'All data stored locally on device',
              theme: theme,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF26A69A).withValues(alpha: 0.15),
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
            _buildSettingsTile(
              context,
              icon: Icons.delete_sweep_outlined,
              title: 'Clear deleted notes',
              subtitle: 'Permanently remove trashed notes',
              theme: theme,
              iconColor: theme.colorScheme.error,
            ),
            const SizedBox(height: 24),

            // About section
            _buildSectionHeader('About', theme),
            const SizedBox(height: 12),
            _buildSettingsTile(
              context,
              icon: Icons.info_outline_rounded,
              title: 'About PRnote',
              subtitle: 'A powerful offline-first note-taking app',
              theme: theme,
            ),
            _buildSettingsTile(
              context,
              icon: Icons.code_rounded,
              title: 'Open source licenses',
              subtitle: 'Third-party software',
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: theme.textTheme.bodySmall?.color,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildThemeSelector(
      BuildContext context, WidgetRef ref, AppThemeMode current, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          _buildThemeOption(
            context, ref, 'Light', Icons.light_mode_rounded,
            AppThemeMode.light, current == AppThemeMode.light, theme,
          ),
          _buildThemeOption(
            context, ref, 'Dark', Icons.dark_mode_rounded,
            AppThemeMode.dark, current == AppThemeMode.dark, theme,
          ),
          _buildThemeOption(
            context, ref, 'AMOLED', Icons.brightness_2_rounded,
            AppThemeMode.amoled, current == AppThemeMode.amoled, theme,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref,
    String label,
    IconData icon,
    AppThemeMode mode,
    bool isSelected,
    ThemeData theme,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(themeProvider.notifier).setTheme(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.textTheme.bodySmall?.color,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeData theme,
    Widget? trailing,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (iconColor ?? theme.colorScheme.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 22,
              color: iconColor ?? theme.colorScheme.primary,
            ),
          ),
          title: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          trailing: trailing ??
              Icon(
                Icons.chevron_right_rounded,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
              ),
        ),
      ),
    );
  }
}
