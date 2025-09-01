@JS()
library tesseract_bindings;

import 'dart:async';
import 'package:js/js.dart';

@JS()
external TesseractWorker createWorker(String? options);

@JS()
@anonymous
class TesseractWorker {
  external Promise load();
  external Promise loadLanguage(String language);
  external Promise initialize(String language);
  external Promise recognize(dynamic image, [String? language]);
  external Promise terminate();
}

@JS()
@anonymous
class Promise {
  external Promise then(Function onFulfilled, [Function? onRejected]);
}

@JS()
@anonymous
class TesseractResult {
  external TesseractData get data;
}

@JS()
@anonymous
class TesseractData {
  external String get text;
  external double get confidence;
  external List<TesseractWord> get words;
  external List<TesseractLine> get lines;
  external List<TesseractParagraph> get paragraphs;
}

@JS()
@anonymous
class TesseractWord {
  external String get text;
  external double get confidence;
  external TesseractBBox get bbox;
}

@JS()
@anonymous
class TesseractLine {
  external String get text;
  external double get confidence;
  external TesseractBBox get bbox;
  external List<TesseractWord> get words;
}

@JS()
@anonymous
class TesseractParagraph {
  external String get text;
  external double get confidence;
  external TesseractBBox get bbox;
  external List<TesseractLine> get lines;
}

@JS()
@anonymous
class TesseractBBox {
  external double get x0;
  external double get y0;
  external double get x1;
  external double get y1;
}

// Helper to convert Promise to Future
Future<T> promiseToFuture<T>(Promise promise) {
  final completer = Completer<T>();
  promise.then((result) {
    completer.complete(result as T);
  }, (error) {
    completer.completeError(error);
  });
  return completer.future;
}
