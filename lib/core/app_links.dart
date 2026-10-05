import 'package:url_launcher/url_launcher.dart';

/// Links the App Store asks for (privacy, terms, support).
class AppLinks {
  static const privacyPolicy = 'https://translateapp-bd410.web.app/privacy';

  // Apple's standard licence agreement; we have no custom terms.
  static const termsOfUse =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

  // TODO: replace with the real support address before release.
  static const supportEmail = 'support@example.com';

  static const manageSubscriptions =
      'https://apps.apple.com/account/subscriptions';

  static Future<bool> open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);

  static Future<bool> emailSupport({String body = ''}) => launchUrl(
    Uri(
      scheme: 'mailto',
      path: supportEmail,
      query:
          'subject=${Uri.encodeComponent('Context Translate support')}'
          '&body=${Uri.encodeComponent(body)}',
    ),
  );
}
