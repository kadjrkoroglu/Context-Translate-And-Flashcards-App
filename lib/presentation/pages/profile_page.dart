import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:translate_app/data/services/sync_service.dart';
import 'package:translate_app/presentation/viewmodels/auth_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/decks_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/favorite_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/history_viewmodel.dart';
import 'package:translate_app/presentation/widgets/app_background.dart';
import 'package:translate_app/presentation/pages/auth/login_page.dart';
import 'package:translate_app/theme/theme_provider.dart';
import 'package:translate_app/theme/theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final themeProvider = context.watch<ThemeProvider>();
    final syncService = context.watch<SyncService>();
    final user = authViewModel.user;
    final bool isAuthenticated = authViewModel.isAuthenticated;

    final glassTheme = Theme.of(context).extension<GlassThemeExtension>()!;
    const Color textColor = Colors.white;
    final Color subTextColor = textColor.withValues(alpha: 0.6);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Profile',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          foregroundColor: textColor,
          actions: [
            if (isAuthenticated)
              IconButton(
                onPressed: () => _showLogoutDialog(context, authViewModel),
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                tooltip: 'Sign Out',
              ),
          ],
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: glassTheme.baseGlassColor,
                  border: Border(
                    bottom: BorderSide(
                      color: glassTheme.borderGlassColor,
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildProfileAvatar(user, isAuthenticated, glassTheme, textColor),
              const SizedBox(height: 20),
              Text(
                isAuthenticated ? (user?.displayName ?? 'User') : 'Guest',
                style: const TextStyle(
                  color: textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              if (isAuthenticated)
                Text(
                  user?.email ?? '',
                  style: TextStyle(color: subTextColor, fontSize: 13),
                )
              else
                Text(
                  'Sign in to sync your progress',
                  style: TextStyle(
                    color: subTextColor.withValues(alpha: 0.5),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              const SizedBox(height: 40),
              if (isAuthenticated)
                _buildSyncCard(
                  context,
                  glassTheme,
                  textColor,
                  subTextColor,
                  syncService,
                )
              else
                _buildSignInCTA(context, glassTheme, textColor, subTextColor),
              const SizedBox(height: 24),
              _buildSimpleTile(
                Icons.dark_mode_outlined,
                'Dark Mode',
                textColor,
                glassTheme,
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (value) => themeProvider.toggleTheme(value),
                  activeThumbColor: Colors.white,
                  activeTrackColor: Colors.white24,
                ),
              ),
              _buildSimpleTile(
                Icons.help_outline_rounded,
                'Help & Support',
                textColor,
                glassTheme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthViewModel vm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await vm.signOut();
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(
    dynamic user,
    bool isAuthenticated,
    GlassThemeExtension glass,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: glass.borderGlassColor, width: 2),
      ),
      child: CircleAvatar(
        radius: 40,
        backgroundColor: Colors.white10,
        backgroundImage: (isAuthenticated && user?.photoURL != null)
            ? NetworkImage(user!.photoURL!)
            : null,
        child: (!isAuthenticated || user?.photoURL == null)
            ? Icon(
                Icons.person_outline_rounded,
                size: 40,
                color: textColor.withValues(alpha: 0.7),
              )
            : null,
      ),
    );
  }

  Widget _buildSyncCard(
    BuildContext context,
    GlassThemeExtension glass,
    Color textColor,
    Color subTextColor,
    SyncService syncService,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: glass.baseGlassColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: glass.borderGlassColor),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _buildIconCircle(
                    Icons.cloud_done_rounded,
                    Colors.greenAccent,
                    glass,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cloud Sync',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Sync your data across devices',
                          style: TextStyle(fontSize: 11, color: subTextColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: syncService.isSyncing
                      ? null
                      : () => _handleSync(context, syncService),
                  icon: syncService.isSyncing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.sync_rounded, size: 20),
                  label: Text(
                    syncService.isSyncing ? 'Syncing...' : 'Sync Now',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: syncService.isSyncing
                        ? Colors.white24
                        : Colors.white,
                    foregroundColor: syncService.isSyncing
                        ? Colors.white70
                        : Colors.black87,
                    disabledBackgroundColor: Colors.white24,
                    disabledForegroundColor: Colors.white70,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              if (syncService.syncError != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Sync failed. Please try again.',
                  style: TextStyle(
                    color: Colors.redAccent.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSync(
    BuildContext context,
    SyncService syncService,
  ) async {
    final authError = await syncService.syncAll();

    if (!context.mounted) return;

    // If user is not logged in, show warning and return early
    if (authError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                authError,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Refresh all viewmodels after sync
    context.read<DecksViewModel>().loadDecks();
    context.read<FavoriteViewModel>().loadFavorites();
    context.read<HistoryViewModel>().loadHistory();

    if (syncService.syncError == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                'Sync completed successfully!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sync failed. Please check your connection and try again.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Widget _buildSignInCTA(
    BuildContext context,
    GlassThemeExtension glass,
    Color textColor,
    Color subTextColor,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: glass.baseGlassColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: glass.borderGlassColor),
          ),
          child: Column(
            children: [
              Text(
                'Synchronize',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to sync your decks, favorites and history across all your devices.',
                textAlign: TextAlign.center,
                style: TextStyle(color: subTextColor, fontSize: 13),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleTile(
    IconData icon,
    String title,
    Color textColor,
    GlassThemeExtension glass, {
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: glass.baseGlassColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: glass.borderGlassColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor.withValues(alpha: 0.7), size: 22),
          const SizedBox(width: 16),
          Text(title, style: TextStyle(color: textColor, fontSize: 15)),
          const Spacer(),
          trailing ??
              Icon(
                Icons.chevron_right_rounded,
                color: textColor.withValues(alpha: 0.2),
              ),
        ],
      ),
    );
  }

  Widget _buildIconCircle(
    IconData icon,
    Color color,
    GlassThemeExtension glass,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: glass.baseGlassColor,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }
}
