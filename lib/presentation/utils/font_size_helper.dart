class FontSizeHelper {
  /// - Short texts (< 50 chars): 26.0 px
  /// - Medium texts (50 - 119 chars): 21.0 px
  /// - Long texts (120+ chars): 17.0 px
  static double getDynamicFontSize(int textLength) {
    if (textLength < 50) {
      return 26.0;
    } else if (textLength < 120) {
      return 21.0;
    } else {
      return 17.0;
    }
  }
}
