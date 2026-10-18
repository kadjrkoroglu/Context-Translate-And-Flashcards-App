import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
// import 'dart:ui';
import 'package:translate_app/core/app_links.dart';
import 'package:provider/provider.dart';
import 'package:translate_app/presentation/viewmodels/auth_viewmodel.dart';
import 'package:translate_app/presentation/widgets/app_background.dart';
import 'package:translate_app/l10n/l10n.dart';
// import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Email sign-in is off for now; Apple and Google only.
  // final _emailController = TextEditingController();
  // final _passwordController = TextEditingController();
  // bool _isPasswordVisible = false;

  // @override
  // void dispose() {
  // _emailController.dispose();
  // _passwordController.dispose();
  // super.dispose();
  // }

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
                            // Icon with Glass Effect
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

                            // // Email Field
                            // _buildTextField(
                            // controller: _emailController,
                            // hint: 'Email',
                            // icon: Icons.email_outlined,
                            // keyboardType: TextInputType.emailAddress,
                            // ),
                            // const SizedBox(height: 16),

                            // // Password Field
                            // _buildTextField(
                            // controller: _passwordController,
                            // hint: 'Password',
                            // icon: Icons.lock_outline,
                            // obscureText: !_isPasswordVisible,
                            // suffixIcon: IconButton(
                            // icon: Icon(
                            // _isPasswordVisible
                            // ? Icons.visibility_off
                            // : Icons.visibility,
                            // color: Colors.white70,
                            // ),
                            // onPressed: () => setState(
                            // () => _isPasswordVisible = !_isPasswordVisible,
                            // ),
                            // ),
                            // ),
                            // const SizedBox(height: 24),

                            // // Login Button
                            // _buildGlassButton(
                            // onPressed: authViewModel.isLoading
                            // ? null
                            // : () async {
                            // final success = await authViewModel.signIn(
                            // _emailController.text.trim(),
                            // _passwordController.text.trim(),
                            // );
                            // if (success && context.mounted) {
                            // Navigator.of(
                            // context,
                            // ).popUntil((route) => route.isFirst);
                            // } else if (!success && context.mounted) {
                            // ScaffoldMessenger.of(context).showSnackBar(
                            // SnackBar(
                            // content: Text(
                            // authViewModel.error ?? 'Login failed',
                            // ),
                            // ),
                            // );
                            // }
                            // },
                            // child: authViewModel.isLoading
                            // ? const SizedBox(
                            // height: 20,
                            // width: 20,
                            // child: CircularProgressIndicator(
                            // strokeWidth: 2,
                            // color: Colors.white,
                            // ),
                            // )
                            // : const Text(
                            // l10n.signIn,
                            // style: TextStyle(
                            // fontWeight: FontWeight.bold,
                            // fontSize: 16,
                            // ),
                            // ),
                            // ),

                            // const SizedBox(height: 24),

                            // Row(
                            // children: [
                            // const Expanded(child: Divider(color: Colors.white24)),
                            // Padding(
                            // padding: const EdgeInsets.symmetric(horizontal: 16),
                            // child: Text(
                            // 'OR',
                            // style: TextStyle(color: ip.withValues(alpha: 0.4)),
                            // ),
                            // ),
                            // const Expanded(child: Divider(color: Colors.white24)),
                            // ],
                            // ),

                            // const SizedBox(height: 24),

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

                            // const SizedBox(height: 32),

                            // // Register Link
                            // Row(
                            // mainAxisAlignment: MainAxisAlignment.center,
                            // children: [
                            // Text(
                            // "Don't have an account?",
                            // style: TextStyle(color: ip.withValues(alpha: 0.7)),
                            // ),
                            // TextButton(
                            // onPressed: () {
                            // Navigator.push(
                            // context,
                            // MaterialPageRoute(
                            // builder: (context) => const RegisterPage(),
                            // ),
                            // );
                            // },
                            // style: TextButton.styleFrom(
                            // padding: const EdgeInsets.symmetric(horizontal: 4),
                            // ),
                            // child: const Text(
                            // 'Register',
                            // style: TextStyle(
                            // color: Colors.blue,
                            // fontWeight: FontWeight.bold,
                            // ),
                            // ),
                            // ),
                            // ],
                            // ),
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

  // Widget _buildTextField({
  // required TextEditingController controller,
  // required String hint,
  // required IconData icon,
  // bool obscureText = false,
  // TextInputType? keyboardType,
  // Widget? suffixIcon,
  // }) {
  // return ClipRRect(
  // borderRadius: BorderRadius.circular(16),
  // child: BackdropFilter(
  // filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
  // child: Container(
  // decoration: BoxDecoration(
  // color: Colors.white.withValues(alpha: 0.1),
  // borderRadius: BorderRadius.circular(16),
  // border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
  // ),
  // child: TextField(
  // controller: controller,
  // obscureText: obscureText,
  // keyboardType: keyboardType,
  // style: const TextStyle(color: Colors.white),
  // cursorColor: Colors.white,
  // decoration: InputDecoration(
  // hintText: hint,
  // hintStyle: const TextStyle(color: Colors.white60),
  // prefixIcon: Icon(icon, color: Colors.white70),
  // suffixIcon: suffixIcon,
  // border: InputBorder.none,
  // contentPadding: const EdgeInsets.symmetric(
  // horizontal: 20,
  // vertical: 16,
  // ),
  // ),
  // ),
  // ),
  // ),
  // );
  // }

  // Widget _buildGlassButton({
  // required VoidCallback? onPressed,
  // required Widget child,
  // }) {
  // return Container(
  // width: double.infinity,
  // height: 56,
  // decoration: BoxDecoration(
  // borderRadius: BorderRadius.circular(16),
  // gradient: LinearGradient(
  // colors: [Colors.blue.shade600, Colors.blue.shade800],
  // ),
  // ),
  // child: ElevatedButton(
  // onPressed: onPressed,
  // style: ElevatedButton.styleFrom(
  // backgroundColor: Colors.transparent,
  // foregroundColor: Colors.white,
  // shadowColor: Colors.transparent,
  // shape: RoundedRectangleBorder(
  // borderRadius: BorderRadius.circular(16),
  // ),
  // ),
  // child: child,
  // ),
  // );
  // }

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
