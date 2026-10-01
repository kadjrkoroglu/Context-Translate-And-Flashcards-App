/// What was heard and its translation, filled in as text streams.
class LiveEntry {
  String heard;
  String translated;
  bool done;

  LiveEntry({this.heard = '', this.translated = '', this.done = false});

  bool get isEmpty => heard.isEmpty && translated.isEmpty;
}
