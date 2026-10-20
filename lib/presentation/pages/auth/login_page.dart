import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:translate_app/core/app_links.dart';
import 'package:provider/provider.dart';
import 'package:translate_app/presentation/viewmodels/auth_viewmodel.dart';
import 'package:translate_app/presentation/widgets/app_background.dart';
import 'package:translate_app/l10n/l10n.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    const Color ip = Colors.white;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.signIn, style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: ip,
        elevation: 0,
        centerTitle: true,
      ),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                // Content sits a little below the middle of the screen.
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            const Spacer(flex: 5),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                              ),
                              child: const Icon(
                                Icons.lock_person_rounded,
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              l10n.welcomeBack,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: ip,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Google Sign In Button
                            _buildGoogleButton(
                              onPressed: authViewModel.isLoading
                                  ? null
                                  : () async {
                                      final success = await authViewModel
                                          .signInWithGoogle();
                                      if (success && context.mounted) {
                                        Navigator.of(
                                          context,
                                        ).popUntil((route) => route.isFirst);
                                      } else if (!success && context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              authViewModel.error ??
                                                  l10n.googleLoginFailed,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                            ),

                            if (_showApple) ...[
                              const SizedBox(height: 12),
                              _buildAppleButton(
                                onPressed: authViewModel.isLoading
                                    ? null
                                    : () async {
                                        final success = await authViewModel
                                            .signInWithApple();
                                        if (!context.mounted) return;
                                        if (success) {
                                          Navigator.of(
                                            context,
                                          ).popUntil((route) => route.isFirst);
                                        } else if (authViewModel.error !=
                                            null) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                authViewModel.error!,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                              ),
                            ],

                            const Spacer(flex: 3),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Fine print at the bottom, out of the buttons' way.
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 8, 32, 12),
                child: _buildLegalNote(ip),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Sign in with Apple is native on Apple devices only.
  static bool get _showApple =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  Widget _buildAppleButton({required VoidCallback? onPressed}) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.apple, color: Colors.white, size: 28),
        label: Text(
          l10n.continueWithApple,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildLegalNote(Color ip) {
    final base = TextStyle(color: ip.withValues(alpha: 0.45), fontSize: 12);
    final link = base.copyWith(decoration: TextDecoration.underline);
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: l10n.legalPrefix),
          TextSpan(
            text: l10n.termsOfUse,
            style: link,
            recognizer: TapGestureRecognizer()
              ..onTap = () => AppLinks.open(AppLinks.termsOfUse),
          ),
          TextSpan(text: l10n.legalAnd),
          TextSpan(
            text: l10n.privacyPolicy,
            style: link,
            recognizer: TapGestureRecognizer()
              ..onTap = () => AppLinks.open(AppLinks.privacyPolicy),
          ),
          TextSpan(text: l10n.legalSuffix),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildGoogleButton({required VoidCallback? onPressed}) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Image.asset('assets/images/google.png', height: 24),
        label: Text(
          l10n.continueWithGoogle,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
