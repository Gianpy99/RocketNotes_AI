# RocketNotes AI - API Reference 📚

## Overview

This document provides comprehensive API references for all external services and integrations used in RocketNotes AI.

## 🔥 Firebase Integration

### Authentication
```dart
// Firebase Auth Service
class FirebaseAuthService {
  // Sign in with email and password
  Future<UserCredential> signInWithEmail(String email, String password);

  // Sign in with Google
  Future<UserCredential> signInWithGoogle();

  // Sign out
  Future<void> signOut();

  // Get current user
  User? getCurrentUser();

  // Password reset
  Future<void> resetPassword(String email);
}
```

### Firestore Database
```dart
// Firestore Service
class FirestoreService {
  // User operations
  Future<void> createUserProfile(UserProfile profile);
  Future<UserProfile?> getUserProfile(String userId);
  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates);

  // Note operations
  Future<String> createNote(Note note);
  Future<Note?> getNote(String noteId);
  Future<List<Note>> getUserNotes(String userId);
  Future<void> updateNote(String noteId, Map<String, dynamic> updates);
  Future<void> deleteNote(String noteId);

  // Category operations
  Future<String> createCategory(Category category);
  Future<List<Category>> getUserCategories(String userId);
  Future<void> updateCategory(String categoryId, Map<String, dynamic> updates);
}
```

### Firebase Storage
```dart
// Storage Service
class FirebaseStorageService {
  // Upload file
  Future<String> uploadFile(String path, File file);

  // Download file
  Future<String> getDownloadUrl(String path);

  // Delete file
  Future<void> deleteFile(String path);

  // List user files
  Future<List<String>> listUserFiles(String userId);
}
```

## 📷 Google ML Kit

### Text Recognition (OCR)
```dart
// OCR Service
class OCRService {
  // Process image for text
  Future<String> extractTextFromImage(File imageFile);

  // Process image with blocks
  Future<List<TextBlock>> extractTextBlocks(File imageFile);

  // Get confidence score
  double getConfidenceScore();
}
```

### Image Processing
```dart
// Image Processing Service
class ImageProcessingService {
  // Resize image
  Future<File> resizeImage(File image, int maxWidth, int maxHeight);

  // Compress image
  Future<File> compressImage(File image, int quality);

  // Enhance image
  Future<File> enhanceImage(File image);

  // Convert to grayscale
  Future<File> convertToGrayscale(File image);
}
```

## 🏷️ NFC Integration

### NFC Service
```dart
// NFC Service
class NFCService {
  // Check NFC availability
  Future<bool> isNFCAvailable();

  // Start NFC scanning
  Future<void> startScanning();

  // Stop NFC scanning
  Future<void> stopScanning();

  // Write to NFC tag
  Future<bool> writeToTag(String data);

  // Read from NFC tag
  Future<String?> readFromTag();

  // Get tag information
  Future<NfcTagInfo> getTagInfo();
}
```

### NFC Data Structures
```dart
class NfcTagInfo {
  final String id;
  final String technology;
  final int maxSize;
  final bool isWritable;
  final String? currentData;
}

class NfcScanResult {
  final bool success;
  final String? data;
  final String? error;
  final NfcTagInfo? tagInfo;
}
```

## 📱 Device Services

### Camera Service
```dart
// Camera Service
class CameraService {
  // Initialize camera
  Future<void> initializeCamera(CameraDescription camera);

  // Take photo
  Future<File> takePhoto();

  // Start video recording
  Future<void> startVideoRecording();

  // Stop video recording
  Future<File> stopVideoRecording();

  // Get available cameras
  Future<List<CameraDescription>> getAvailableCameras();

  // Set flash mode
  Future<void> setFlashMode(FlashMode mode);
}
```

### Local Storage (Hive)
```dart
// Local Storage Service
class LocalStorageService {
  // Initialize storage
  Future<void> initialize();

  // Note operations
  Future<void> saveNote(Note note);
  Future<Note?> getNote(String id);
  Future<List<Note>> getAllNotes();
  Future<void> deleteNote(String id);

  // Category operations
  Future<void> saveCategory(Category category);
  Future<List<Category>> getAllCategories();

  // User preferences
  Future<void> saveUserPreferences(UserPreferences prefs);
  Future<UserPreferences?> getUserPreferences();

  // Clear all data
  Future<void> clearAllData();
}
```

## 🔐 Security Services

### Encryption Service
```dart
// Encryption Service
class EncryptionService {
  // Encrypt data
  Future<String> encryptData(String data, String key);

  // Decrypt data
  Future<String> decryptData(String encryptedData, String key);

  // Generate key
  Future<String> generateEncryptionKey();

  // Hash password
  Future<String> hashPassword(String password);

  // Verify password
  Future<bool> verifyPassword(String password, String hash);
}
```

### Biometric Service
```dart
// Biometric Service
class BiometricService {
  // Check biometric availability
  Future<bool> isBiometricAvailable();

  // Get available biometrics
  Future<List<BiometricType>> getAvailableBiometrics();

  // Authenticate with biometrics
  Future<bool> authenticateWithBiometrics(String reason);

  // Enable biometric authentication
  Future<void> enableBiometricAuth();

  // Disable biometric authentication
  Future<void> disableBiometricAuth();
}
```

## 🌐 Network Services

### HTTP Client (Dio)
```dart
// API Service
class ApiService {
  // GET request
  Future<T> get<T>(String endpoint, {Map<String, dynamic>? queryParams});

  // POST request
  Future<T> post<T>(String endpoint, {dynamic data});

  // PUT request
  Future<T> put<T>(String endpoint, {dynamic data});

  // DELETE request
  Future<T> delete<T>(String endpoint);

  // Upload file
  Future<String> uploadFile(String endpoint, File file);

  // Download file
  Future<File> downloadFile(String url, String savePath);

  // Set authentication token
  void setAuthToken(String token);

  // Clear authentication
  void clearAuth();
}
```

### Connectivity Service
```dart
// Connectivity Service
class ConnectivityService {
  // Check internet connection
  Future<bool> isConnected();

  // Get connection type
  Future<ConnectivityResult> getConnectionType();

  // Listen to connectivity changes
  Stream<ConnectivityResult> get onConnectivityChanged;

  // Check if on mobile data
  Future<bool> isOnMobileData();

  // Check if on WiFi
  Future<bool> isOnWifi();
}
```

## 📊 Analytics & Monitoring

### Analytics Service
```dart
// Analytics Service
class AnalyticsService {
  // Track event
  Future<void> trackEvent(String eventName, Map<String, dynamic> parameters);

  // Track screen view
  Future<void> trackScreenView(String screenName);

  // Track user property
  Future<void> setUserProperty(String property, dynamic value);

  // Track purchase
  Future<void> trackPurchase(String productId, double price, String currency);

  // Track error
  Future<void> trackError(String error, StackTrace stackTrace);
}
```

### Performance Monitoring
```dart
// Performance Service
class PerformanceService {
  // Start trace
  Future<void> startTrace(String traceName);

  // Stop trace
  Future<void> stopTrace(String traceName);

  // Record metric
  Future<void> recordMetric(String metricName, num value);

  // Monitor network requests
  Future<void> monitorNetworkRequest(String url, int responseTime);

  // Monitor app startup time
  Future<void> recordAppStartTime(Duration startTime);
}
```

## 🔧 Utility Services

### File System Service
```dart
// File Service
class FileService {
  // Get app directory
  Future<Directory> getAppDirectory();

  // Get temporary directory
  Future<Directory> getTempDirectory();

  // Create file
  Future<File> createFile(String path);

  // Read file
  Future<String> readFile(String path);

  // Write file
  Future<void> writeFile(String path, String content);

  // Delete file
  Future<void> deleteFile(String path);

  // Check if file exists
  Future<bool> fileExists(String path);

  // Get file size
  Future<int> getFileSize(String path);
}
```

### Permission Service
```dart
// Permission Service
class PermissionService {
  // Request camera permission
  Future<bool> requestCameraPermission();

  // Request storage permission
  Future<bool> requestStoragePermission();

  // Request microphone permission
  Future<bool> requestMicrophonePermission();

  // Request location permission
  Future<bool> requestLocationPermission();

  // Check permission status
  Future<PermissionStatus> checkPermission(Permission permission);

  // Open app settings
  Future<bool> openAppSettings();
}
```

## 📱 Notification Services

### Local Notification Service
```dart
// Notification Service
class NotificationService {
  // Initialize notifications
  Future<void> initialize();

  // Show notification
  Future<void> showNotification(String title, String body, {String? payload});

  // Schedule notification
  Future<void> scheduleNotification(DateTime dateTime, String title, String body);

  // Cancel notification
  Future<void> cancelNotification(int id);

  // Cancel all notifications
  Future<void> cancelAllNotifications();

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications();
}
```

## 🔗 Deep Linking Service

### Deep Link Service
```dart
// Deep Link Service
class DeepLinkService {
  // Initialize deep linking
  Future<void> initialize();

  // Handle incoming link
  Future<void> handleIncomingLink(Uri link);

  // Create note link
  Future<String> createNoteLink(String noteId);

  // Create category link
  Future<String> createCategoryLink(String categoryId);

  // Parse link data
  Future<LinkData> parseLink(Uri link);
}
```

## 📋 Data Models

### Core Data Models
```dart
class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  final String categoryId;
  final List<String> tags;
  final List<Attachment> attachments;
  final bool isEncrypted;
}

class Category {
  final String id;
  final String name;
  final String color;
  final String icon;
  final String userId;
  final DateTime createdAt;
}

class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final Map<String, dynamic> preferences;
}

class Attachment {
  final String id;
  final String fileName;
  final String fileType;
  final String url;
  final int size;
  final DateTime uploadedAt;
}
```

## ⚡ Error Handling

### Custom Exceptions
```dart
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? details;

  ApiException(this.message, {this.statusCode, this.details});
}

class AuthException implements Exception {
  final String message;
  final AuthErrorCode code;

  AuthException(this.message, this.code);
}

class StorageException implements Exception {
  final String message;
  final String? filePath;

  StorageException(this.message, {this.filePath});
}
```

---

*API Reference v1.0*
*Last Updated: September 2025*</content>
<parameter name="filePath">c:\Development\RocketNotes_AI\docs\api-references\complete-api-reference.md
