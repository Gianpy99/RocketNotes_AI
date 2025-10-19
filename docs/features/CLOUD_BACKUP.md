# Cloud Backup System - Complete Documentation

## Overview

Sistema di backup completo su cloud per **tutti i dati dell'app**:
- 📝 **Notes**: Tutte le note con metadata
- ⚙️ **Settings**: Configurazioni app
- 🖼️ **Images**: Foto allegate e scansioni
- 🎤 **Audio**: Registrazioni vocali
- 📎 **Attachments**: Altri file allegati

## Features

### ✅ Automatic Backup
- Backup schedulato automatico (configurabile)
- Backup manuale on-demand
- Upload incrementale (solo modifiche)

### ✅ Multi-Provider Support
- **Firebase Storage** (default, già integrato)
- Google Drive (future)
- Dropbox (future)
- iCloud (future)

### ✅ Smart Sync
- Backup dei file quando salvati
- Restore completo o selettivo
- Conflict resolution
- Bandwidth-efficient

### ✅ Security
- User-scoped backups (`userId/` folder structure)
- Firebase Authentication integration
- Encrypted transmission (HTTPS)

## Architecture

### Folder Structure on Cloud

```
firebase_storage://
  └── {userId}/
      ├── notes/
      │   └── notes_backup.json         # All notes as JSON
      ├── settings/
      │   └── settings_backup.json      # App settings
      ├── images/
      │   ├── scan_001.jpg
      │   ├── photo_002.png
      │   └── ...
      ├── audio/
      │   ├── recording_001.m4a
      │   ├── voice_note_002.mp3
      │   └── ...
      ├── attachments/
      │   ├── document_001.pdf
      │   ├── file_002.txt
      │   └── ...
      └── .backup_metadata            # Last backup timestamp
```

### Service Flow

```
App Data (Hive + Files)
        ↓
CloudBackupService
        ↓
    ┌───┴───┐
    ↓       ↓
Firebase  Google Drive
Storage   (future)
    ↓       ↓
    └───┬───┘
        ↓
   User Cloud Account
```

## Usage

### 1. Initialize Service

In `main.dart`:

```dart
import 'data/services/cloud_backup_service.dart';

Future<void> main() async {
  // ... existing initialization
  
  // Initialize cloud backup
  await CloudBackupService.instance.initialize();
  debugPrint('✅ Cloud Backup Service initialized');
  
  runApp(MyApp());
}
```

### 2. Manual Backup

```dart
// Full backup
final result = await CloudBackupService.instance.backupAll();

if (result.success) {
  print('Backup completed!');
  print('Duration: ${result.duration?.inSeconds}s');
  print('Total size: ${result.totalSize} bytes');
  print('Notes: ${result.itemsCounts?['notes']} items');
  print('Images: ${result.itemsCounts?['images']} files');
} else {
  print('Backup failed: ${result.error}');
}
```

### 3. Restore from Backup

```dart
final result = await CloudBackupService.instance.restoreAll();

if (result.success) {
  print('Restore completed in ${result.duration?.inSeconds}s');
} else {
  print('Restore failed: ${result.error}');
}
```

### 4. Backup Single File

Quando salvi un'immagine o audio:

```dart
// After saving image
await CloudBackupService.instance.backupFile(
  localPath: imagePath,
  type: BackupFileType.images,
);

// After recording audio
await CloudBackupService.instance.backupFile(
  localPath: audioPath,
  type: BackupFileType.audio,
);
```

### 5. Get Backup Info

```dart
final info = await CloudBackupService.instance.getBackupInfo();

print('Backup exists: ${info.exists}');
print('Last backup: ${info.lastBackup}');
print('Total size: ${info.formattedSize}');
print('Total items: ${info.totalItems}');
print('Notes: ${info.itemCounts['notes']}');
print('Images: ${info.itemCounts['images']}');
```

### 6. Delete Backup

```dart
await CloudBackupService.instance.deleteBackup();
```

## Integration Examples

### Auto-Backup After Note Save

```dart
// In note_repository.dart
Future<void> saveNote(NoteModel note) async {
  // Save to Hive
  final box = Hive.box<NoteModel>('notes');
  await box.put(note.id, note);
  
  // Auto-backup if enabled
  await CloudBackupService.instance.backupAll();
}
```

### Auto-Backup After Image Capture

```dart
// In camera_service.dart
Future<void> saveImage(File imageFile) async {
  // Save locally
  final appDir = await getApplicationDocumentsDirectory();
  final imagesDir = Directory('${appDir.path}/images');
  await imagesDir.create(recursive: true);
  
  final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
  final savedPath = '${imagesDir.path}/$fileName';
  await imageFile.copy(savedPath);
  
  // Backup to cloud
  await CloudBackupService.instance.backupFile(
    localPath: savedPath,
    type: BackupFileType.images,
  );
}
```

### Settings UI Integration

```dart
// In settings_screen.dart
class BackupSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text('Backup Now'),
          subtitle: Text('Backup all data to cloud'),
          leading: Icon(Icons.cloud_upload),
          onTap: () async {
            final result = await CloudBackupService.instance.backupAll();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.success 
                  ? 'Backup completed!' 
                  : 'Backup failed: ${result.error}'),
              ),
            );
          },
        ),
        ListTile(
          title: Text('Restore from Backup'),
          subtitle: Text('Restore all data from cloud'),
          leading: Icon(Icons.cloud_download),
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Restore from Backup'),
                content: Text('This will replace all local data. Continue?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text('Restore'),
                  ),
                ],
              ),
            );
            
            if (confirm == true) {
              final result = await CloudBackupService.instance.restoreAll();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result.success 
                    ? 'Restore completed!' 
                    : 'Restore failed: ${result.error}'),
                ),
              );
            }
          },
        ),
        FutureBuilder<BackupInfo>(
          future: CloudBackupService.instance.getBackupInfo(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return ListTile(
                title: Text('Backup Info'),
                subtitle: Text('Loading...'),
                leading: Icon(Icons.info),
              );
            }
            
            final info = snapshot.data!;
            return ListTile(
              title: Text('Backup Info'),
              subtitle: Text(info.exists
                ? 'Last: ${info.lastBackup}, Size: ${info.formattedSize}'
                : 'No backup found'),
              leading: Icon(Icons.info),
            );
          },
        ),
      ],
    );
  }
}
```

## Scheduled Auto-Backup

Per backup automatico periodico:

```dart
// In background_service.dart
import 'package:workmanager/workmanager.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'cloudBackup') {
      await CloudBackupService.instance.initialize();
      final result = await CloudBackupService.instance.backupAll();
      debugPrint('Scheduled backup: ${result.success}');
    }
    return Future.value(true);
  });
}

Future<void> scheduleAutoBackup() async {
  await Workmanager().initialize(callbackDispatcher);
  
  // Schedule daily backup at 2 AM
  await Workmanager().registerPeriodicTask(
    'cloudBackup',
    'cloudBackup',
    frequency: Duration(hours: 24),
    initialDelay: Duration(hours: 2),
  );
}
```

## Firebase Storage Setup

### 1. Add Firebase Storage to `pubspec.yaml`

```yaml
dependencies:
  firebase_storage: ^11.0.0  # Already added
```

### 2. Firebase Console Rules

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{userId}/{allPaths=**} {
      // Users can read/write their own files
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 3. Enable Firebase Storage in Console

1. Go to Firebase Console
2. Select your project
3. Navigate to Storage
4. Click "Get Started"
5. Choose production mode
6. Select location (preferably same as Firestore)

## Cost Estimation

### Firebase Storage Pricing (as of 2024)

- **Storage**: $0.026/GB/month
- **Download**: $0.12/GB
- **Upload**: Free

### Example Usage

**Average user**:
- Notes: 1000 notes × 10KB = 10 MB
- Images: 50 images × 2MB = 100 MB
- Audio: 20 recordings × 5MB = 100 MB
- **Total**: ~210 MB = 0.21 GB

**Monthly cost**: 0.21 GB × $0.026 = **$0.0055/month** (~$0.066/year)

**Free tier**: 5GB storage, 1GB download/day → **sufficient for most users**

## Optimization Tips

### 1. Image Compression

Before backup:

```dart
import 'package:image/image.dart' as img;

Future<File> compressImage(File imageFile) async {
  final bytes = await imageFile.readAsBytes();
  final image = img.decodeImage(bytes);
  
  if (image != null) {
    // Resize to max 1920x1080
    final resized = img.copyResize(image, width: 1920);
    
    // Compress to 80% quality
    final compressed = img.encodeJpg(resized, quality: 80);
    
    await imageFile.writeAsBytes(compressed);
  }
  
  return imageFile;
}
```

### 2. Incremental Backup

Only backup changed files:

```dart
// Track last backup timestamps
final _lastBackupTimes = <String, DateTime>{};

Future<void> backupIfModified(String filePath) async {
  final file = File(filePath);
  final modified = await file.lastModified();
  
  final lastBackup = _lastBackupTimes[filePath];
  if (lastBackup == null || modified.isAfter(lastBackup)) {
    await CloudBackupService.instance.backupFile(
      localPath: filePath,
      type: BackupFileType.images,
    );
    _lastBackupTimes[filePath] = DateTime.now();
  }
}
```

### 3. WiFi-Only Backup

```dart
import 'package:connectivity_plus/connectivity_plus.dart';

Future<bool> shouldBackup() async {
  final connectivity = await Connectivity().checkConnectivity();
  return connectivity == ConnectivityResult.wifi;
}

// Use in backup flow
if (await shouldBackup()) {
  await CloudBackupService.instance.backupAll();
}
```

## Troubleshooting

### Backup Fails

**Symptoms**: `BackupResult.success = false`

**Solutions**:
- Check user is logged in (`FirebaseAuth.instance.currentUser != null`)
- Verify Firebase Storage enabled in console
- Check internet connection
- Review Firebase Storage rules
- Check console for quota limits

### Restore Incomplete

**Symptoms**: Some files not restored

**Solutions**:
- Check backup exists (`BackupInfo.exists == true`)
- Verify file permissions on device
- Ensure sufficient storage space
- Check logs for specific errors

### Slow Backup

**Symptoms**: Backup takes too long

**Solutions**:
- Compress images before backup
- Use WiFi instead of cellular
- Backup incrementally (only changes)
- Consider reducing image/audio quality
- Schedule backups during off-peak hours

## Future Enhancements

### Phase 1 (Current)
- ✅ Firebase Storage integration
- ✅ Complete backup/restore
- ✅ Per-file backup API
- ✅ Backup info retrieval

### Phase 2 (Next)
- ⏳ Incremental backup (only changes)
- ⏳ Compression before upload
- ⏳ WiFi-only option
- ⏳ Scheduled auto-backup
- ⏳ Progress indicators

### Phase 3 (Future)
- 📋 Google Drive integration
- 📋 Dropbox integration
- 📋 Selective restore (choose items)
- 📋 Backup history (multiple versions)
- 📋 Encryption at rest
- 📋 Backup sharing/export

## Security Considerations

### Data Privacy

- ✅ User-scoped folders (`userId/` prefix)
- ✅ Firebase Authentication required
- ✅ HTTPS transmission
- ⏳ Optional encryption at rest (future)

### Access Control

Firebase Storage rules ensure:
- Users can only access their own data
- Must be authenticated
- No public access

### Best Practices

1. **Never store sensitive data unencrypted**
2. **Use strong authentication** (not anonymous)
3. **Regular security audits** of Firebase rules
4. **Monitor usage** for suspicious activity
5. **Implement rate limiting** to prevent abuse

## API Reference

### CloudBackupService

```dart
// Singleton instance
static CloudBackupService get instance

// Initialize service
Future<void> initialize()

// Configuration
void setAutoBackup(bool enabled)
void setProvider(BackupProvider provider)

// Backup operations
Future<BackupResult> backupAll()
Future<void> backupFile({
  required String localPath,
  required BackupFileType type,
})

// Restore operations
Future<RestoreResult> restoreAll()

// Info & management
Future<BackupInfo> getBackupInfo()
Future<void> deleteBackup()
```

### BackupResult

```dart
class BackupResult {
  final bool success;
  final DateTime? timestamp;
  final Duration? duration;
  final int? totalSize;
  final Map<String, int>? itemsCounts;
  final String? error;
}
```

### BackupInfo

```dart
class BackupInfo {
  final bool exists;
  final DateTime? lastBackup;
  final int totalSize;
  final Map<String, int> itemCounts;
  
  String get formattedSize;
  int get totalItems;
}
```

## License

Part of RocketNotes AI. Uses Firebase Storage under Firebase terms.

---

**Ready to never lose your data again! 🚀☁️**
