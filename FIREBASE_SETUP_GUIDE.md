## 🔥 GUIDA SETUP FIREBASE COMPLETA

### 1. Firebase Console Setup
1. Vai su https://console.firebase.google.com
2. Accedi con il tuo account Google
3. Trova il progetto esistente "RocketNotes AI" o simile

### 2. Configurazione Android App ✅ GIÀ CONFIGURATA
**La tua app Firebase esistente:**
- **App ID:** `1:580705135159:android:9c6186f56e5e5f6cf8adb2`
- **App nickname:** `RocketNotes AI`
- **Package name:** `com.example.pensieve`

**Prossimi passi:**
1. Firebase Console → Il tuo progetto → Gear icon ⚙️ → Project Settings
2. Scroll down → "Your apps" section  
3. Click su "RocketNotes AI" (com.example.pensieve)
4. Download `google-services.json`
5. Copia il file in: `android-app/android/app/google-services.json`

### 3. Installa FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
```

### 4. Configura il progetto Flutter
**Con le tue informazioni specifiche:**
```bash
cd android-app
flutterfire configure --project=580705135159
```
Oppure usa il project ID (nome) se lo conosci:
```bash
flutterfire configure --project=your-project-name
```
Questo genererà automaticamente `lib/firebase_options.dart`

### 5. Verifica gradle files
Controlla che questi file contengano le configurazioni Firebase:

**android-app/android/build.gradle (project-level):**
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
}
```

**android-app/android/app/build.gradle:**
```gradle
apply plugin: 'com.google.gms.google-services'
```

### 6. Ricrea firebase_config.dart
Dopo aver generato firebase_options.dart, ricrea il file:
`android-app/lib/core/config/firebase_config.dart`

### 7. Test della configurazione
```bash
cd android-app
flutter clean
flutter pub get
flutter run
```

### 8. Verifica Firebase Services
- Authentication: verifica che gli utenti possano accedere
- Firestore: controlla che i dati famiglia si sincronizzino  
- Storage: verifica upload file
- Cloud Functions: testa notifiche push

### 9. Regole Firestore/Storage
Assicurati che le regole di sicurezza siano configurate per:
- Accesso famiglia condiviso
- Permessi utente appropriati
- Sicurezza dati sensibili

Una volta completato il setup, fammi sapere e rigenererò il file firebase_config.dart!