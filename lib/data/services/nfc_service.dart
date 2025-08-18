// lib/data/services/nfc_service.dart
import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

class NfcService {
  static const MethodChannel _channel = MethodChannel('nfc_channel');
  
  Future<NFCAvailability> checkAvailability() async {
    return await FlutterNfcKit.nfcAvailability;
  }

  Future<String?> readNfcTag() async {
    try {
      final availability = await checkAvailability();
      if (availability != NFCAvailability.available) {
        throw Exception('NFC not available');
      }

      final tag = await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 10),
        iosMultipleTagMessage: "Multiple tags found!",
        iosAlertMessage: "Scan your NFC tag",
      );

      if (tag.ndefAvailable ?? false) {
        final records = await FlutterNfcKit.readNDEFRecords();
        for (var record in records) {
          final uri = record.uri?.toString();
          if (uri != null && uri.startsWith('rocketnotes://')) {
            await FlutterNfcKit.finish();
            return uri;
          }
        }
      }
      
      await FlutterNfcKit.finish();
      return null;
    } catch (e) {
      print('Error reading NFC: $e');
      return null;
    }
  }

  String? extractModeFromUri(String uri) {
    if (uri.contains('rocketnotes://work')) {
      return 'work';
    } else if (uri.contains('rocketnotes://personal')) {
      return 'personal';
    }
    return null;
  }
}
