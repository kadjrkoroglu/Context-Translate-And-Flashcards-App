import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:translate_app/data/services/sync_service.dart';
import 'package:translate_app/presentation/viewmodels/auth_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/decks_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/favorite_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/history_viewmodel.dart';
import 'package:translate_app/presentation/widgets/app_background.dart';
import 'package:translate_app/presentation/widgets/restart_required_dialog.dart';
import 'package:translate_app/presentation/pages/auth/login_page.dart';
import 'package:translate_app/core/app_links.dart';
import 'package:translate_app/data/services/local_storage_service.dart';
import 'package:translate_app/data/services/settings_service.dart';
import 'package:translate_app/domain/entities/entitlements_entity.dart';
import 'package:translate_app/presentation/pages/help_page.dart';
import 'package:translate_app/presentation/pages/upgrade_page.dart';
import 'package:translate_app/presentation/viewmodels/entitlements_viewmodel.dart';
import 'package:translate_app/theme/theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SyncService>().checkUnsyncedChanges();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
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
              const SizedBox(height: 12),
              const _PlanBadge(),
              const SizedBox(height: 28),
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
              _SettingsGroup(
                rows: [
                  _SettingsRow(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & FAQ',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HelpPage()),
                    ),
                  ),
                  _SettingsRow(
                    icon: Icons.mail_outline_rounded,
                    title: 'Contact us',
                    onTap: () => AppLinks.emailSupport(
                      body: '\n\n---\nUser: ${user?.uid ?? '-'}',
                    ),
                  ),
                  _SettingsRow(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () => AppLinks.open(AppLinks.privacyPolicy),
                  ),
                  _SettingsRow(
                    icon: Icons.description_outlined,
                    title: 'Terms of Use',
                    onTap: () => AppLinks.open(AppLinks.termsOfUse),
                  ),
                  _SettingsRow(
                    icon: Icons.restore_rounded,
                    title: 'Restore purchases',
                    onTap: () => showSubscriptionsComingSoon(context),
                  ),
                ],
              ),
              if (isAuthenticated) ...[
                const SizedBox(height: 12),
                _SettingsGroup(
                  rows: [
                    _SettingsRow(
                      icon: Icons.delete_outline_rounded,
                      title: 'Delete account',
                      color: Colors.redAccent,
                      onTap: () =>
                          _confirmDeleteAccount(context, authViewModel),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    AuthViewModel vm,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: AlertDialog(
          backgroundColor: const Color(0xFF2D3238).withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          ),
          title: const Text(
            'Delete account?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Your account, decks, cards, favorites and history are deleted '
            'on all devices. This cannot be undone.\n\n'
            'An App Store subscription is not cancelled by this; manage it '
            'in Settings > your name > Subscriptions.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white60),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final local = context.read<LocalStorageService>();
    final settings = context.read<SettingsService>();
    final decks = context.read<DecksViewModel>();
    final history = context.read<HistoryViewModel>();
    final favorites = context.read<FavoriteViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
    final deleted = await vm.deleteAccount();
    if (deleted) {
      // Nothing of the old account stays on this phone.
      await local.clearAllData();
      await settings.setAiStudyChat(null);
      decks.loadDecks();
      history.loadHistory();
      favorites.loadFavorites();
    }
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    if (deleted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Your account was deleted.')),
      );
    } else if (vm.error != null) {
      messenger.showSnackBar(SnackBar(content: Text(vm.error!)));
    }
  }

  void _showLogoutDialog(BuildContext context, AuthViewModel vm) {
    showDialog(
      context: context,
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: AlertDialog(
          backgroundColor: const Color(0xFF2D3238).withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          ),
          title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Are you sure you want to sign out?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white60),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await vm.signOut();
                if (context.mounted) showRestartRequiredDialog(context);
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
    final bool isSyncedState =
        !syncService.isSyncing && !syncService.hasUnsyncedChanges;

    // Define values dynamically for the button
    VoidCallback? buttonOnPressed;
    Widget buttonIcon;
    String buttonText;
    Color buttonBgColor;
    Color buttonFgColor;

    if (syncService.isSyncing) {
      buttonOnPressed = null;
      buttonIcon = const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
      buttonText = 'Syncing...';
      buttonBgColor = Colors.white24;
      buttonFgColor = Colors.white70;
    } else if (isSyncedState) {
      buttonOnPressed = null; // Disabled when synced
      buttonIcon = const Icon(Icons.check_rounded, size: 20);
      buttonText = 'Synced';
      buttonBgColor = Colors.white.withValues(alpha: 0.15);
      buttonFgColor = Colors.white70;
    } else {
      buttonOnPressed = () => _handleSync(context, syncService);
      buttonIcon = const Icon(Icons.sync_rounded, size: 20);
      buttonText = 'Sync Now';
      buttonBgColor = Colors.white;
      buttonFgColor = Colors.black87;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: glass.baseGlassColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: glass.borderGlassColor),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _buildIconCircle(
                    isSyncedState
                        ? Icons.cloud_done_rounded
                        : Icons.cloud_rounded,
                    isSyncedState
                        ? Colors.greenAccent
                        : textColor.withValues(alpha: 0.7),
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
                  onPressed: buttonOnPressed,
                  icon: buttonIcon,
                  label: Text(
                    buttonText,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonBgColor,
                    foregroundColor: buttonFgColor,
                    disabledBackgroundColor: buttonBgColor,
                    disabledForegroundColor: buttonFgColor,
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

    if (syncService.syncError != null) {
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
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: glass.baseGlassColor,
            borderRadius: BorderRadius.circular(24),
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
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
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

/// Current plan; tapping it opens the plans screen.
class _PlanBadge extends StatelessWidget {
  const _PlanBadge();

  @override
  Widget build(BuildContext context) {
    final entitlements = context.watch<EntitlementsViewModel>().entitlements;
    if (entitlements == null) return const SizedBox(height: 30);
    final tier = entitlements.tier;
    final color = switch (tier) {
      AppTier.premium || AppTier.trialPremium => Colors.amberAccent,
      AppTier.standard || AppTier.trialStandard => Colors.lightBlueAccent,
      AppTier.free => Colors.white70,
    };
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UpgradePage()),
      ),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium_rounded, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              tier.label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rows in one rounded card, all the same height.
class _SettingsGroup extends StatelessWidget {
  final List<_SettingsRow> rows;

  const _SettingsGroup({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 54,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                rows[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color color;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 50,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: color.withValues(alpha: 0.75), size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: color, fontSize: 15),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
