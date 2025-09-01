// Stub file for non-web platforms where Tesseract.js is not available

class TesseractWorker {
  // Stub implementation - not used on mobile
}

class TesseractResult {
  // Stub implementation - not used on mobile
}

class TesseractData {
  // Stub implementation - not used on mobile
}

TesseractWorker createWorker(String? options) {
  throw UnsupportedError('Tesseract.js is only available on web platform');
}

Future<T> promiseToFuture<T>(dynamic promise) {
  throw UnsupportedError('Promise conversion is only available on web platform');
}
