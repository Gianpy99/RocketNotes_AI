# 📱 Installazione APK su Cellulare

## 📦 File APK Generato

**Percorso**: `c:\Development\RocketNotes_AI\android-app\build\app\outputs\flutter-apk\app-debug.apk`

**Dimensione**: ~388 MB (407,353,994 bytes)  
**Data**: 12 Ottobre 2025, 13:59  
**Tipo**: Debug APK (con simboli debug)

---

## 🚀 Metodi di Installazione

### Metodo 1: USB (Più Veloce) ✅

1. **Collega il cellulare al PC** via USB
2. **Abilita USB Debugging** sul cellulare:
   - Vai in **Impostazioni → Info sul telefono**
   - Tocca **Numero build** 7 volte (attiva Modalità Sviluppatore)
   - Vai in **Impostazioni → Opzioni sviluppatore**
   - Attiva **Debug USB**
   - Autorizza il computer quando appare il popup

3. **Verifica connessione**:
   ```powershell
   adb devices
   ```
   Dovresti vedere il tuo device

4. **Installa APK**:
   ```powershell
   cd c:\Development\RocketNotes_AI\android-app
   adb install -r build\app\outputs\flutter-apk\app-debug.apk
   ```

5. **Fatto!** L'app si installa automaticamente

---

### Metodo 2: Trasferimento File (Senza Cavo) 📁

#### Opzione A: Email/Messaging
1. **Invia APK via email/WhatsApp/Telegram** a te stesso
2. **Scarica sul cellulare**
3. **Apri il file** scaricato
4. Se appare "Origine sconosciuta":
   - Vai in **Impostazioni → Sicurezza**
   - Attiva **Sorgenti sconosciute** o **Installa app sconosciute**
5. **Tocca "Installa"**

#### Opzione B: Google Drive/OneDrive
1. **Carica APK** su cloud storage
2. **Apri dal cellulare**
3. **Scarica e installa** (come sopra)

#### Opzione C: Cavo USB + File Explorer
1. **Collega cellulare** al PC via USB
2. **Seleziona "Trasferimento file"** sul cellulare
3. **Copia APK** in una cartella del telefono (es. Download)
4. **Sul cellulare**: Apri File Manager
5. **Trova APK** e tocca per installare

#### Opzione D: WiFi Direct / Nearby Share
1. **Attiva condivisione file** tramite WiFi Direct o Nearby Share
2. **Invia APK** dal PC al cellulare
3. **Installa** dal file ricevuto

---

## ⚙️ Prima Installazione - Permessi

Quando apri l'app per la prima volta, dovrai autorizzare:

✅ **Camera** - Per cattura immagini Rocketbook  
✅ **Microfono** - Per registrazione note audio  
✅ **Storage** - Per salvare foto e file  
✅ **Notifiche** (opzionale) - Per reminder

---

## 🎨 Aggiungere i Widget alla Home

Dopo l'installazione:

1. **Premi e tieni** su spazio vuoto della home screen
2. Tocca **"Widget"**
3. Scorri e trova **"Pensieve"**
4. Vedrai **2 widget**:
   - 📷 **Quick Camera Capture**
   - 🎤 **Quick Audio Note**
5. **Trascina** il widget desiderato sulla home
6. **Tap** sul widget per testarlo!

```
┌────────┐          ┌────────┐
│   📷   │          │   🎤   │
│        │          │        │
│ Camera │          │ Audio  │
└────────┘          └────────┘
```

---

## 🔧 Risoluzione Problemi

### ❌ "App non installata"
**Causa**: Versione precedente con firma diversa  
**Soluzione**: Disinstalla vecchia versione prima:
```bash
adb uninstall com.example.pensieve
# Poi reinstalla
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

### ❌ "Origine sconosciuta bloccata"
**Causa**: Android blocca app non da Play Store  
**Soluzione**: 
- Android 8+: Vai in **Impostazioni → App e notifiche → Accesso speciale alle app → Installa app sconosciute**
- Seleziona l'app che usi per installare (es. File Manager, Chrome)
- Attiva "Consenti da questa origine"

### ❌ "File danneggiato"
**Causa**: Download incompleto  
**Soluzione**: 
- Controlla dimensione file (~388 MB)
- Ri-scarica o ri-trasferisci
- Verifica che il trasferimento sia completo

### ❌ Widget non appare
**Causa**: App non completamente installata  
**Soluzione**:
- Riavvia il cellulare
- Disinstalla e reinstalla l'app
- Aspetta 30 secondi dopo l'installazione

---

## 📊 Informazioni APK

**Package Name**: `com.example.pensieve`  
**App Name**: Pensieve  
**Version**: Debug (development build)  
**Min Android**: 5.0 (API 21)  
**Target Android**: 14 (API 34)

**Features incluse**:
- ✅ Sistema trascrizione audio AI (OpenAI/Gemini)
- ✅ Camera Rocketbook con OCR
- ✅ Widget Android home screen
- ✅ Gestione note work/personal
- ✅ Sync Firebase
- ✅ NFC mode switching
- ✅ Family sharing
- ✅ Shopping list
- ✅ Statistics & monitoring

---

## 🔄 Aggiornamenti Futuri

Per installare versioni successive:

**Con ADB (automatico)**:
```powershell
adb install -r new-version.apk
```
Il flag `-r` reinstalla mantenendo i dati

**Manuale**:
- Non serve disinstallare
- Installa sopra la versione esistente
- I dati vengono preservati

---

## 💡 Tips

1. **Performance**: Questa è versione debug (~388MB). Per produzione, usa:
   ```powershell
   flutter build apk --release
   ```
   Dimensione ridotta a ~50MB

2. **Multiple devices**: Puoi installare su più dispositivi contemporaneamente:
   ```powershell
   adb devices  # Elenca devices
   adb -s DEVICE_ID install -r app-debug.apk
   ```

3. **Test Widget**: Dopo installazione, aggiungi i widget e testali subito!

4. **Backup**: Prima di aggiornare, esporta le note dalle impostazioni

---

## 📞 Contatti Sviluppatore

Per problemi o domande:
- **Repository**: RocketNotes_AI
- **Docs**: `docs/implementation/ANDROID_WIDGETS.md`
- **Widget Guide**: `docs/WIDGET_VISUAL_GUIDE.md`

---

**Enjoy! 🚀**

La tua app è pronta con i nuovi widget per accesso rapido!
