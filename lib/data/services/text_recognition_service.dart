import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:translate_app/core/errors/app_exception.dart';
import 'package:translate_app/data/ocr/ocr_core.dart';

/// One PaddleOCR recognition model per writing system.
enum OcrScript { latin, cyrillic, cjk, korean, arabic, devanagari, greek }

class OcrLine {
  final String text;

  /// TL, TR, BR, BL, relative to the photo (0-1).
  final List<Offset> corners;

  final LabelColors colors;

  const OcrLine(this.text, this.corners, this.colors);
}

/// On-device OCR, same models and code on iOS and Android (assets/ocr).
class TextRecognitionService {
  static const String _assets = 'assets/ocr';
  // PaddleOCR's drop_score.
  static const double _minConfidence = 0.5;

  final OnnxRuntime _ort = OnnxRuntime();
  OrtSession? _detector;
  OcrScript? _recognizerScript;
  OrtSession? _recognizer;
  List<String>? _dictionary;

  /// null: no model for this language (Hebrew).
  static OcrScript? scriptFor(String language) {
    switch (language) {
      case 'Russian':
        return OcrScript.cyrillic;
      case 'Chinese':
      case 'Japanese':
        return OcrScript.cjk;
      case 'Korean':
        return OcrScript.korean;
      case 'Arabic':
      case 'Persian':
      case 'Urdu':
        return OcrScript.arabic;
      case 'Hindi':
        return OcrScript.devanagari;
      case 'Greek':
        return OcrScript.greek;
      case 'Hebrew':
        return null;
      default:
        return OcrScript.latin;
    }
  }

  Future<List<OcrLine>> recognize(RgbaImage image, OcrScript script) async {
    try {
      final detector = _detector ??= await _ort.createSessionFromAsset(
        '$_assets/det.onnx',
      );
      final detInput = await _prepareDetection(image);
      final probabilities = await _runDetection(detector, detInput);
      final prepared = await _prepareRecognition(
        image,
        probabilities,
        detInput.width,
        detInput.height,
      );
      if (prepared.quads.isEmpty) return [];

      final (recognizer, dictionary) = await _loadRecognizer(script);
      final texts = List<RecognizedText?>.filled(prepared.quads.length, null);
      for (final batch in prepared.batches) {
        final (indices, scores, steps) = await _runRecognition(
          recognizer,
          batch,
        );
        for (var b = 0; b < batch.quadIndexes.length; b++) {
          texts[batch.quadIndexes[b]] = decodeCtc(
            indices,
            scores,
            b * steps,
            steps,
            dictionary,
            rightToLeft: script == OcrScript.arabic,
          );
        }
      }

      return [
        for (var i = 0; i < prepared.quads.length; i++)
          if (texts[i] != null &&
              texts[i]!.text.isNotEmpty &&
              texts[i]!.confidence >= _minConfidence)
            OcrLine(texts[i]!.text, [
              for (final c in prepared.quads[i].corners)
                Offset(c.x / image.width, c.y / image.height),
            ], prepared.colors[i]),
      ];
    } catch (e) {
      throw GeneralException(
        'Could not read text from the photo',
        details: e.toString(),
      );
    }
  }

  // Pixel work runs in isolates; static so closures don't capture sessions.
  static Future<DetInput> _prepareDetection(RgbaImage image) =>
      Isolate.run(() => buildDetInput(image));

  static Future<
    ({List<TextQuad> quads, List<RecBatch> batches, List<LabelColors> colors})
  >
  _prepareRecognition(
    RgbaImage image,
    Float32List probabilities,
    int mapWidth,
    int mapHeight,
  ) => Isolate.run(() {
    final quads = findTextQuads(
      probabilities,
      mapWidth,
      mapHeight,
      image.width,
      image.height,
    );
    return (
      quads: quads,
      batches: buildRecBatches(image, quads),
      colors: [for (final q in quads) sampleLabelColors(image, q)],
    );
  });

  static Future<Float32List> _runDetection(
    OrtSession detector,
    DetInput input,
  ) async {
    final tensor = await OrtValue.fromList(input.data, [
      1,
      3,
      input.height,
      input.width,
    ]);
    Map<String, OrtValue>? outputs;
    try {
      outputs = await detector.run({detector.inputNames.first: tensor});
      final values = await outputs.values.first.asFlattenedList();
      return values is Float32List
          ? values
          : Float32List.fromList([
              for (final v in values) (v as num).toDouble(),
            ]);
    } finally {
      await _dispose(tensor, outputs);
    }
  }

  static Future<(List<int>, List<double>, int)> _runRecognition(
    OrtSession recognizer,
    RecBatch batch,
  ) async {
    final tensor = await OrtValue.fromList(batch.data, [
      batch.quadIndexes.length,
      3,
      recHeight,
      batch.width,
    ]);
    Map<String, OrtValue>? outputs;
    try {
      outputs = await recognizer.run({recognizer.inputNames.first: tensor});
      final indicesValue = outputs['indices']!;
      final indices = [
        for (final v in await indicesValue.asFlattenedList())
          (v as num).toInt(),
      ];
      final scores = [
        for (final v in await outputs['scores']!.asFlattenedList())
          (v as num).toDouble(),
      ];
      return (indices, scores, indicesValue.shape.last);
    } finally {
      await _dispose(tensor, outputs);
    }
  }

  static Future<void> _dispose(
    OrtValue input,
    Map<String, OrtValue>? outputs,
  ) async {
    await input.dispose();
    for (final output in outputs?.values ?? const <OrtValue>[]) {
      await output.dispose();
    }
  }

  // Only one recognition model is kept in memory.
  Future<(OrtSession, List<String>)> _loadRecognizer(OcrScript script) async {
    if (_recognizerScript != script ||
        _recognizer == null ||
        _dictionary == null) {
      await _recognizer?.close();
      _recognizer = null;
      _recognizer = await _ort.createSessionFromAsset(
        '$_assets/rec_${script.name}.onnx',
      );
      _dictionary = (await rootBundle.loadString(
        '$_assets/dict_${script.name}.txt',
      )).split('\n');
      _recognizerScript = script;
    }
    return (_recognizer!, _dictionary!);
  }

  Future<void> dispose() async {
    await _detector?.close();
    await _recognizer?.close();
    _detector = null;
    _recognizer = null;
  }
}
