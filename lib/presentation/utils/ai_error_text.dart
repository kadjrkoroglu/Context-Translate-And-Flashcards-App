import 'package:translate_app/core/errors/app_exception.dart';
import 'package:translate_app/l10n/l10n.dart';

/// Title and message for a failed AI request, shared by all translation screens.
({String title, String message}) aiErrorText(AppException? e) {
  if (e is NetworkException) {
    return (title: l10n.errConnectionTitle, message: l10n.errConnectionMsg);
  }
  final kind = e is AiServiceException ? e.kind : AiFailure.failed;
  return switch (kind) {
    AiFailure.unavailable => (
      title: l10n.errUnavailableTitle,
      message: l10n.errUnavailableMsg,
    ),
    AiFailure.busy => (title: l10n.errBusyTitle, message: l10n.errBusyMsg),
    AiFailure.timeout => (
      title: l10n.errTimeoutTitle,
      message: l10n.errTimeoutMsg,
    ),
    AiFailure.blocked => (
      title: l10n.errBlockedTitle,
      message: l10n.errBlockedMsg,
    ),
    AiFailure.failed => (
      title: l10n.errFailedTitle,
      message: l10n.errFailedMsg,
    ),
  };
}
