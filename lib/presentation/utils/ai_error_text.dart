import 'package:translate_app/core/errors/app_exception.dart';

/// Title and message for a failed AI request, shared by all translation screens.
({String title, String message}) aiErrorText(AppException? e) {
  if (e is NetworkException) {
    return (
      title: 'Connection Error',
      message: 'No internet connection. Check your connection and try again.',
    );
  }
  final kind = e is AiServiceException ? e.kind : AiFailure.failed;
  return switch (kind) {
    AiFailure.unavailable => (
      title: 'Service Unavailable',
      message:
          'Translation is temporarily unavailable. Please try again later.',
    ),
    AiFailure.busy => (
      title: 'AI Is Busy',
      message: 'Too many requests right now. Try again in a few seconds.',
    ),
    AiFailure.timeout => (
      title: 'Took Too Long',
      message: 'The translation took too long. Please try again.',
    ),
    AiFailure.blocked => (
      title: "Can't Translate This",
      message: "This text couldn't be translated.",
    ),
    AiFailure.failed => (
      title: 'Something Went Wrong',
      message: 'Translation could not be completed. Please try again.',
    ),
  };
}
