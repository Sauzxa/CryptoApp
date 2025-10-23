import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/colors.dart';

class ThemeToggleSwitch extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final bool showAsListTile;

  const ThemeToggleSwitch({
    super.key,
    this.title,
    this.subtitle,
    this.icon,
    this.showAsListTile = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        if (showAsListTile) {
          return ListTile(
            leading: icon != null
                ? Icon(icon, color: Theme.of(context).iconTheme.color)
                : Icon(
                    themeProvider.isDarkMode
                        ? Icons.dark_mode
                        : Icons.light_mode,
                    color: Theme.of(context).iconTheme.color,
                  ),
            title: Text(
              title ?? 'Theme',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: subtitle != null
                ? Text(subtitle!, style: Theme.of(context).textTheme.bodySmall)
                : Text(
                    'Currently using ${themeProvider.themeModeString} mode',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
            trailing: Switch(
              value: themeProvider.isDarkMode,
              onChanged: (value) => themeProvider.toggleTheme(),
              activeColor: AppColors.primaryPurple,
              activeTrackColor: AppColors.primaryPurple.withOpacity(0.3),
              inactiveThumbColor: Colors.grey[300],
              inactiveTrackColor: Colors.grey[200],
            ),
            onTap: () => themeProvider.toggleTheme(),
          );
        } else {
          return Switch(
            value: themeProvider.isDarkMode,
            onChanged: (value) => themeProvider.toggleTheme(),
            activeColor: AppColors.primaryPurple,
            activeTrackColor: AppColors.primaryPurple.withOpacity(0.3),
            inactiveThumbColor: Colors.grey[300],
            inactiveTrackColor: Colors.grey[200],
          );
        }
      },
    );
  }
}

class ThemeToggleButton extends StatelessWidget {
  final String? tooltip;
  final EdgeInsetsGeometry? padding;

  const ThemeToggleButton({super.key, this.tooltip, this.padding});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return IconButton(
          onPressed: () => themeProvider.toggleTheme(),
          icon: Icon(
            themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            color: Theme.of(context).iconTheme.color,
          ),
          tooltip: tooltip ?? 'Toggle theme',
          padding: padding,
        );
      },
    );
  }
}

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Theme', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ThemeOption(
                    title: 'Light',
                    icon: Icons.light_mode,
                    isSelected: !themeProvider.isDarkMode,
                    onTap: () => themeProvider.setThemeMode(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ThemeOption(
                    title: 'Dark',
                    icon: Icons.dark_mode,
                    isSelected: themeProvider.isDarkMode,
                    onTap: () => themeProvider.setThemeMode(true),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryPurple.withOpacity(0.1)
              : Theme.of(context).cardTheme.color,
          border: Border.all(
            color: isSelected ? AppColors.primaryPurple : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? AppColors.primaryPurple
                  : Theme.of(context).iconTheme.color,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isSelected
                    ? AppColors.primaryPurple
                    : Theme.of(context).textTheme.titleMedium?.color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
