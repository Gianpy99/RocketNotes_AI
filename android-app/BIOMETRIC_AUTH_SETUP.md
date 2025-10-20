# 🔐 Biometric Authentication Setup Guide

## ✅ Stato Attuale

Il tuo progetto ha già:
- ✅ Pacchetto `local_auth: ^3.0.0` installato
- ✅ `BiometricAuthService` implementato
- ✅ Provider Riverpod configurati
- ✅ UI nelle impostazioni con switch "Biometric Lock"
- ✅ Permessi Android aggiunti all'AndroidManifest.xml

## 🔧 Configurazione

### 1. Permessi Android (✅ FATTO)
I seguenti permessi sono stati aggiunti in `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
<uses-permission android:name="android.permission.USE_FINGERPRINT" />
<uses-feature android:name="android.hardware.fingerprint" android:required="false" />
```

### 2. Kotlin Version (Verifica)
Assicurati che `android/build.gradle` abbia almeno Kotlin 1.7.0:
```gradle
buildscript {
    ext.kotlin_version = '1.7.20'
    ...
}
```

### 3. Configurazione MainActivity (Opzionale per Android 10+)
Se necessario, aggiungi in `android/app/src/main/kotlin/.../MainActivity.kt`:
```kotlin
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity() {
    // Necessario per local_auth su alcuni dispositivi
}
```

## 📱 Come Usare il Servizio

### Esempio Base: Autenticazione Biometrica
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pensieve/features/family/services/biometric_auth_service.dart';

class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biometricService = ref.watch(biometricAuthServiceProvider);
    
    return ElevatedButton(
      onPressed: () async {
        // Verifica se disponibile
        final isAvailable = await biometricService.isBiometricAvailable();
        
        if (!isAvailable) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Autenticazione biometrica non disponibile')),
          );
          return;
        }
        
        // Autentica
        final authenticated = await biometricService.authenticate(
          reason: 'Conferma la tua identità per accedere',
        );
        
        if (authenticated) {
          // Successo!
          print('Autenticazione riuscita');
        } else {
          print('Autenticazione fallita');
        }
      },
      child: Text('Usa Biometria'),
    );
  }
}
```

### Esempio Avanzato: Dialog Biometrico
```dart
import 'package:pensieve/features/family/services/biometric_auth_service.dart';

// Mostra dialog con autenticazione biometrica
final result = await showDialog<bool>(
  context: context,
  builder: (context) => BiometricAuthDialog(
    title: 'Autenticazione Richiesta',
    subtitle: 'Verifica la tua identità',
    reason: 'Accesso a dati sensibili',
    onAuthenticated: () {
      print('Autenticato con successo!');
    },
    onCancelled: () {
      print('Autenticazione cancellata');
    },
  ),
);

if (result == true) {
  // Procedi con l'operazione
}
```

### Esempio: Verifica Tipi Biometrici Disponibili
```dart
final biometricService = ref.watch(biometricAuthServiceProvider);
final availableTypes = await biometricService.getAvailableBiometrics();

for (var type in availableTypes) {
  if (type == BiometricType.fingerprint) {
    print('Impronta digitale disponibile');
  } else if (type == BiometricType.face) {
    print('Riconoscimento facciale disponibile');
  } else if (type == BiometricType.iris) {
    print('Riconoscimento iride disponibile');
  }
}
```

## 🎯 Integrazione con le Impostazioni

Il servizio è già integrato con `AppSettingsModel`:
```dart
// In AppSettingsModel
@HiveField(9)
bool enableBiometric;
```

Per abilitare/disabilitare dalle impostazioni:
```dart
// Nell'UI settings
SettingsSwitchTile(
  title: 'Biometric Lock',
  subtitle: 'Require biometric authentication to open app',
  leading: const Icon(Icons.fingerprint_rounded),
  value: settingsData?.biometricLock ?? false,
  onChanged: (value) => _updateSetting('biometricLock', value),
),
```

## 🔒 Casi d'Uso Consigliati

### 1. Blocco App all'Avvio
```dart
// In main.dart o splash screen
class AppLockScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    
    if (settings.value?.enableBiometric == true) {
      return BiometricAuthDialog(
        title: 'Sblocca Pensieve',
        subtitle: 'Usa la biometria per accedere',
        reason: 'Autenticazione richiesta per accedere all\'app',
        onAuthenticated: () {
          // Naviga alla home
          context.go('/home');
        },
        onCancelled: () {
          // Esci dall'app o mostra messaggio
          SystemNavigator.pop();
        },
      );
    }
    
    return HomePage(); // Se biometria disabilitata
  }
}
```

### 2. Protezione Note Sensibili
```dart
// Prima di aprire una nota con tag "private"
if (note.tags.contains('private')) {
  final authenticated = await biometricService.authenticate(
    reason: 'Conferma per aprire questa nota privata',
  );
  
  if (!authenticated) {
    return; // Non aprire la nota
  }
}
```

### 3. Conferma Eliminazione
```dart
// Prima di eliminare dati importanti
final confirmed = await showDialog<bool>(
  context: context,
  builder: (context) => BiometricAuthDialog(
    title: 'Conferma Eliminazione',
    subtitle: 'Verifica la tua identità',
    reason: 'Conferma per eliminare tutti i dati',
    onAuthenticated: () {},
  ),
);

if (confirmed == true) {
  // Procedi con l'eliminazione
}
```

### 4. Accesso Famiglia/Condivisione
```dart
// Prima di condividere note in famiglia
final canShare = await biometricService.authenticate(
  reason: 'Conferma per condividere con la famiglia',
);

if (canShare) {
  // Condividi la nota
}
```

## ❓ NON Serve Google Sign-In

**IMPORTANTE**: L'autenticazione biometrica (impronta digitale, Face ID) **NON** richiede Google Sign-In.

- **Biometric Auth** = Autenticazione locale sul dispositivo (impronta, volto)
- **Google Sign-In** = Autenticazione cloud con account Google

Sono due cose separate:
- 🔐 **Biometric**: Usa il sensore hardware del telefono
- 🌐 **Google**: Usa le credenziali Google online

Puoi usare la biometria **SENZA** Google Sign-In!

## 🧪 Come Testare

### Su Emulatore Android
1. Apri Settings > Security > Fingerprint
2. Aggiungi un'impronta fittizia
3. Nell'emulatore, usa il pulsante "Fingerprint" per simulare il tocco

### Su Dispositivo Reale
1. Configura l'impronta/Face ID nelle impostazioni del telefono
2. Esegui l'app: `flutter run -d 36021JEHN10640`
3. Attiva "Biometric Lock" nelle impostazioni dell'app
4. Testa l'autenticazione

### Test Completo
```dart
// Crea un test widget
void main() {
  testWidgets('Biometric auth test', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: BiometricTestScreen(),
        ),
      ),
    );
    
    // Verifica disponibilità
    final service = BiometricAuthService();
    final available = await service.isBiometricAvailable();
    expect(available, isTrue);
  });
}
```

## 🐛 Troubleshooting

### Errore: "Biometrics not available"
- Verifica che il dispositivo abbia un sensore biometrico
- Assicurati di aver configurato almeno un'impronta/face nelle impostazioni
- Controlla i permessi in AndroidManifest.xml

### Errore: "PlatformException"
- Verifica la versione di Kotlin (≥ 1.7.0)
- Controlla che MainActivity estenda FlutterFragmentActivity (opzionale)
- Riavvia l'app dopo aver cambiato i permessi

### Errore: "Authentication failed"
- L'utente potrebbe aver annullato
- Potrebbero esserci troppi tentativi falliti
- Il sensore potrebbe essere sporco o malfunzionante

## 📚 Risorse Utili

- [local_auth package](https://pub.dev/packages/local_auth)
- [Android BiometricPrompt API](https://developer.android.com/training/sign-in/biometric-auth)
- [Flutter Platform Security](https://docs.flutter.dev/development/platform-integration/platform-channels)

## ✅ Checklist Implementazione

- [x] Pacchetto `local_auth` installato
- [x] Permessi Android configurati
- [x] BiometricAuthService creato
- [x] Provider Riverpod setup
- [x] UI nelle impostazioni
- [ ] Integrazione all'avvio app (opzionale)
- [ ] Protezione note sensibili (opzionale)
- [ ] Test su dispositivo reale

## 🎯 Prossimi Passi

1. **Testa sul tuo telefono** (36021JEHN10640)
2. **Attiva nelle impostazioni** il "Biometric Lock"
3. **Integra dove necessario** (es. splash screen, note private)
4. **Aggiungi feedback UI** (animazioni, messaggi)

Buon lavoro! 🚀
