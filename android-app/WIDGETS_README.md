# 📱 RocketNotes AI - Widget Android

## Quick Start

### Aggiungi i Widget

1. **Premi e tieni** su spazio vuoto della home screen
2. Tocca **"Widget"**
3. Trova **"Pensieve"**
4. Trascina i widget sulla home:
   - 📷 **Quick Camera Capture** - Cattura rapida immagini
   - 🎤 **Quick Audio Note** - Registrazione rapida audio

### Widget Disponibili

| Widget | Icona | Azione | Schermata |
|--------|-------|--------|-----------|
| Camera | 📷 | Cattura immagine | `RocketbookCameraScreen` |
| Audio | 🎤 | Registra audio | `AudioNoteScreen` |

## Build & Install

```powershell
# Da root del progetto
cd android-app
flutter clean
flutter pub get
flutter build apk --debug
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

## Test Widget

### Metodo 1: Manuale
1. Aggiungi widget alla home
2. Tap sul widget
3. Verifica che l'app si apra sulla schermata corretta

### Metodo 2: ADB (Automatico)
```powershell
# Usa lo script di test
.\test-widgets.ps1

# Oppure direttamente via ADB:
adb shell am start -W -a android.intent.action.VIEW -d "rocketnotes://camera" com.example.rocket_notes_ai
adb shell am start -W -a android.intent.action.VIEW -d "rocketnotes://audio" com.example.rocket_notes_ai
```

## Struttura

```
android/app/src/main/
├── kotlin/.../
│   ├── CameraWidgetProvider.kt     # Widget camera
│   └── AudioWidgetProvider.kt      # Widget audio
├── res/
│   ├── xml/                        # Widget metadata
│   ├── layout/                     # Widget UI
│   └── drawable/                   # Widget background
└── AndroidManifest.xml             # Widget registration

lib/
├── data/services/
│   └── widget_deep_link_service.dart  # Deep link handler
└── app/
    └── routes_simple.dart             # Routes /camera, /audio
```

## Deep Links

| URI | Route | Destinazione |
|-----|-------|--------------|
| `rocketnotes://camera` | `/camera` | `RocketbookCameraScreen` |
| `rocketnotes://audio` | `/audio` | `AudioNoteScreen` |

## Troubleshooting

### Widget non visibile
```bash
# Rebuild completo
flutter clean && flutter build apk
```

### Widget non risponde
1. Controlla logcat per errori:
   ```bash
   adb logcat | grep -i "widget\|deeplink\|rocketnotes"
   ```
2. Verifica che l'app sia installata correttamente
3. Prova a rimuovere e riaggiungere il widget

### App si apre ma sulla home
1. Verifica che le routes esistano in `routes_simple.dart`
2. Controlla che `WidgetDeepLinkService.initialize()` sia chiamato
3. Vedi log Flutter per errori di navigazione

## Documentazione Completa

📚 **Guida completa**: `docs/implementation/ANDROID_WIDGETS.md`

Include:
- Architettura dettagliata
- Personalizzazione widget
- Best practices sicurezza
- Future enhancements
- Debug avanzato

## Features

✅ Accesso istantaneo (1 tap)  
✅ Design minimalista 1x1  
✅ Tema app (purple)  
✅ Deep links sicuri  
✅ Android 12+ compatibile  
✅ Zero battery impact  

---

**Made with ❤️ for RocketNotes AI**
