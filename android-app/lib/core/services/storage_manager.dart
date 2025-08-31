import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class StorageManager {
  static const String SCANS_FOLDER = 'rocketbook_scans';
  static const int MAX_DAYS_KEEP = 30; // Mantieni le immagini per 30 giorni
  static const int MAX_FILES_KEEP = 100; // Massimo 100 file
  
  /// Ottieni la directory di scansione
  static Future<Directory> getScansDirectory() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String scansDir = path.join(appDir.path, SCANS_FOLDER);
    final Directory scansDirObj = Directory(scansDir);
    
    if (!await scansDirObj.exists()) {
      await scansDirObj.create(recursive: true);
    }
    
    return scansDirObj;
  }
  
  /// Pulisci le immagini vecchie per liberare spazio
  static Future<void> cleanOldImages() async {
    try {
      final Directory scansDir = await getScansDirectory();
      final List<FileSystemEntity> files = scansDir.listSync();
      
      final List<File> imageFiles = files
          .whereType<File>()
          .where((file) => _isImageFile(file.path))
          .toList();
      
      // Ordina per data di modifica (più vecchi prima)
      imageFiles.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
      
      final DateTime cutoffDate = DateTime.now().subtract(Duration(days: MAX_DAYS_KEEP));
      int deletedCount = 0;
      
      // Elimina file più vecchi di MAX_DAYS_KEEP giorni
      for (final file in imageFiles) {
        if (file.lastModifiedSync().isBefore(cutoffDate)) {
          await file.delete();
          deletedCount++;
        }
      }
      
      // Se ci sono ancora troppi file, elimina i più vecchi
      final remainingFiles = await _getRemainingImageFiles();
      if (remainingFiles.length > MAX_FILES_KEEP) {
        final filesToDelete = remainingFiles.length - MAX_FILES_KEEP;
        for (int i = 0; i < filesToDelete; i++) {
          await remainingFiles[i].delete();
          deletedCount++;
        }
      }
      
      print('🧹 STORAGE: Puliti $deletedCount file vecchi');
    } catch (e) {
      print('❌ STORAGE: Errore durante pulizia: $e');
    }
  }
  
  /// Ottieni informazioni sullo storage utilizzato
  static Future<StorageInfo> getStorageInfo() async {
    try {
      final List<File> imageFiles = await _getRemainingImageFiles();
      
      int totalBytes = 0;
      for (final file in imageFiles) {
        totalBytes += await file.length();
      }
      
      return StorageInfo(
        totalFiles: imageFiles.length,
        totalSizeBytes: totalBytes,
        totalSizeMB: totalBytes / (1024 * 1024),
        oldestFile: imageFiles.isNotEmpty 
            ? imageFiles.first.lastModifiedSync() 
            : null,
        newestFile: imageFiles.isNotEmpty 
            ? imageFiles.last.lastModifiedSync() 
            : null,
      );
    } catch (e) {
      print('❌ STORAGE: Errore durante calcolo info: $e');
      return StorageInfo(totalFiles: 0, totalSizeBytes: 0, totalSizeMB: 0);
    }
  }
  
  /// Pulisci tutto lo storage (per debug/reset)
  static Future<void> clearAllScans() async {
    try {
      final Directory scansDir = await getScansDirectory();
      if (await scansDir.exists()) {
        await scansDir.delete(recursive: true);
        await scansDir.create(recursive: true);
        print('🗑️ STORAGE: Pulita tutta la directory scansioni');
      }
    } catch (e) {
      print('❌ STORAGE: Errore durante reset: $e');
    }
  }
  
  static Future<List<File>> _getRemainingImageFiles() async {
    final Directory scansDir = await getScansDirectory();
    final List<FileSystemEntity> files = scansDir.listSync();
    
    final List<File> imageFiles = files
        .whereType<File>()
        .where((file) => _isImageFile(file.path))
        .toList();
    
    // Ordina per data di modifica
    imageFiles.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
    
    return imageFiles;
  }
  
  static bool _isImageFile(String filePath) {
    final String extension = path.extension(filePath).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.webp'].contains(extension);
  }
}

class StorageInfo {
  final int totalFiles;
  final int totalSizeBytes;
  final double totalSizeMB;
  final DateTime? oldestFile;
  final DateTime? newestFile;
  
  StorageInfo({
    required this.totalFiles,
    required this.totalSizeBytes,
    required this.totalSizeMB,
    this.oldestFile,
    this.newestFile,
  });
  
  @override
  String toString() {
    return 'Storage: $totalFiles file, ${totalSizeMB.toStringAsFixed(2)} MB';
  }
}
