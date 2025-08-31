# 🔧 Android Studio Debug Setup

## 1. Apri Android Studio
- **File** → **Open** 
- Naviga a: `C:\Development\RocketNotes_AI\android-app\android`
- Clicca **OK**

## 2. Verifica connessione dispositivo
- **View** → **Tool Windows** → **Logcat**
- In alto dovrebbe apparire il tuo dispositivo
- Se non appare, controlla che Debug USB sia abilitato

## 3. Installa app in modalità debug
Due opzioni:

### Opzione A: Da Flutter (Raccomandato)
```bash
cd C:\Development\RocketNotes_AI\android-app
flutter run --debug
```

### Opzione B: Da Android Studio
- **Run** → **Run 'app'** (freccia verde)
- Seleziona il tuo dispositivo
- L'app si installerà automaticamente

## 4. Visualizza Log in tempo reale

### In Android Studio:
- **View** → **Tool Windows** → **Logcat**
- Filtra per "flutter" o "RocketNotes"
- Vedrai tutti i debugPrint() dell'app

### Nel terminale:
```bash
adb logcat | findstr "flutter"
```

## 5. Log specifici da cercare

Quando usi l'app, cerca questi tag:
- `🔧 CAMERA_DEBUG`: Info debug camera
- `🔍 OCR_WIDGET`: Debug OCR
- `🖼️ IMAGE_MANAGER`: Gestione immagini
- `❌`: Errori generali
- `✅`: Successi

## 6. Debugging in tempo reale

1. **Apri l'app** sul telefono
2. **Vai al debug screen** (icona bug 🐛)
3. **Premi i pulsanti** di test
4. **Guarda i log** in Android Studio Logcat

## 7. Se non vedi il dispositivo

Verifica in PowerShell:
```bash
adb devices
```

Dovresti vedere il tuo telefono listato.
Se non compare:
- Controlla cavo USB
- Riavvia adb: `adb kill-server` poi `adb start-server`
- Verifica driver del telefono su Windows

## 8. Test specifici da fare

1. **Test permessi:**
   - Premi "Controlla Permessi"
   - Guarda output nel Logcat

2. **Test camera:**
   - Premi "Test Camera"
   - Vedi se si apre la camera
   - Controlla errori nel log

3. **Test OCR:**
   - Usa camera normale
   - Vai al QuickCapture
   - Scatta foto
   - Guarda log OCR

## 9. Come leggere i log

Esempio log normale:
```
🔧 CAMERA_DEBUG: Screen inizializzato
🔧 CAMERA_DEBUG: Controllo permessi...
🔧 CAMERA_DEBUG: Stato camera: granted
✅ Permesso camera concesso
```

Esempio log errore:
```
❌ IMAGE_MANAGER: Errore durante scatto: Camera not available
❌ OCR_WIDGET: Eccezione durante OCR: File not found
```

## 10. Feedback utile da darmi

Dopo aver fatto i test, dimmi:
- ✅ / ❌ Dispositivo riconosciuto in Android Studio
- ✅ / ❌ App si installa e avvia
- ✅ / ❌ Debug screen visibile (icona bug)
- ✅ / ❌ Camera si apre nei test
- ✅ / ❌ OCR funziona
- 📝 **Copia-incolla i log di errore dal Logcat**

Questo mi permetterà di capire esattamente dove è il problema!
