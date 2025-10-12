# 🎯 Widget Android - Guida Visiva Rapida

## Come Aggiungere i Widget alla Home

### Passo 1: Accedi ai Widget
```
┌─────────────────────┐
│                     │
│   Premi e tieni     │  👆 Premi a lungo su uno spazio
│   premuto qui       │     vuoto della home screen
│                     │
└─────────────────────┘
```

### Passo 2: Seleziona Widget
```
┌─────────────────────┐
│  📱 Widgets         │
│  🏠 Wallpapers      │  👆 Tocca "Widget"
│  ⚙️  Settings       │
│  ℹ️  Home settings  │
└─────────────────────┘
```

### Passo 3: Trova Pensieve
```
Scorri fino a:

┌─────────────────────┐
│  📝 Notes           │
│  📊 OneNote         │
│  🧠 Pensieve   ◄── Qui!
│  📸 Photos          │
└─────────────────────┘
```

### Passo 4: Scegli il Widget
```
┌─────────────────────┐
│  Pensieve           │
│                     │
│  ┌────┐  ┌────┐   │
│  │ 📷 │  │ 🎤 │   │  ◄── Trascina quello
│  │Cam │  │Aud │   │      che preferisci!
│  └────┘  └────┘   │
│                     │
│  Quick Camera       │
│  Quick Audio        │
└─────────────────────┘
```

### Passo 5: Posiziona sulla Home
```
        ┌─────┐
        │  🎤 │  ◄── Trascina e rilascia
        └─────┘      dove vuoi!
             ↓
┌─────────────────────┐
│ 📱 +39 123...       │
│                     │
│ ┌────┐ ┌────┐     │
│ │ 📧 │ │ 🌐 │     │
│ └────┘ └────┘     │
│                     │
│ ┌────┐ ┌────┐ 📷  │ ◄── Widget aggiunto!
│ │ 📁 │ │ 📝 │     │
│ └────┘ └────┘     │
│                     │
└─────────────────────┘
```

## Utilizzo dei Widget

### Widget Camera 📷
```
Tap sul widget → Apre camera → Scatta foto
                      ↓
              ┌───────────────┐
              │               │
              │    CAMERA     │
              │     ATTIVA    │
              │               │
              │  ┏━━━━━━━┓   │
              │  ┃       ┃   │
              │  ┃  📸   ┃   │
              │  ┃       ┃   │
              │  ┗━━━━━━━┛   │
              │               │
              │   [Capture]   │
              └───────────────┘
```

### Widget Audio 🎤
```
Tap sul widget → Apre registrazione → Registra nota
                      ↓
              ┌───────────────┐
              │               │
              │  AUDIO NOTE   │
              │               │
              │   🎤 🔴      │
              │               │
              │   00:00:00    │
              │               │
              │  [  STOP  ]   │
              │  [ PAUSE  ]   │
              └───────────────┘
```

## Aspetto dei Widget

### Design Finale
```
┌────────┐          ┌────────┐
│   📷   │          │   🎤   │
│        │          │        │
│ Camera │          │ Audio  │
└────────┘          └────────┘
  Purple              Purple
  1x1 cell            1x1 cell
```

### Colori
- **Background**: Purple (#673AB7) - colore tema dell'app
- **Icone**: Bianco (#FFFFFF)
- **Testo**: Bianco (#FFFFFF)
- **Forma**: Rounded corners (16dp)

## Test Rapido

### ✅ Checklist Funzionamento

Camera Widget:
- [ ] Widget visibile nella lista widget di Pensieve
- [ ] Widget si aggiunge alla home screen
- [ ] Tap sul widget apre l'app
- [ ] App mostra schermata camera
- [ ] Camera è pronta per scattare

Audio Widget:
- [ ] Widget visibile nella lista widget di Pensieve
- [ ] Widget si aggiunge alla home screen
- [ ] Tap sul widget apre l'app
- [ ] App mostra schermata registrazione
- [ ] UI registrazione è visibile

## Risoluzione Problemi Comuni

### ❌ Widget non appare nella lista
```
Soluzione:
1. Chiudi app completamente
2. Reinstalla: flutter clean && flutter build apk
3. Riprova ad aggiungere widget
```

### ❌ Widget aggiunto ma non fa nulla
```
Soluzione:
1. Rimuovi widget dalla home
2. Riavvia dispositivo
3. Aggiungi widget nuovamente
```

### ❌ App si apre ma sulla home
```
Soluzione:
1. Controlla versione Android (min. API 21)
2. Verifica permessi app nelle impostazioni
3. Prova deep link via ADB (vedi test-widgets.ps1)
```

## Screenshot Attesi

### Prima del Tap
```
Home Screen
┌─────────────────────┐
│                     │
│    ┌────┐          │
│    │ 📷 │ ◄── Widget camera
│    └────┘          │
│                     │
│    ┌────┐          │
│    │ 🎤 │ ◄── Widget audio
│    └────┘          │
│                     │
└─────────────────────┘
```

### Dopo il Tap
```
App aperta sulla schermata target

Camera Widget:
┌─────────────────────┐
│  ← Pensieve         │
│                     │
│  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │
│  ▓   Camera View  ▓ │
│  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │
│                     │
│     [Capture]       │
└─────────────────────┘

Audio Widget:
┌─────────────────────┐
│  ← Audio Note       │
│                     │
│      🎤 ●          │
│                     │
│    00:00:00         │
│                     │
│   [  STOP  ]        │
│   [ PAUSE  ]        │
└─────────────────────┘
```

## Statistiche di Utilizzo

Per vedere quante volte usi i widget, vai in:
**App → Impostazioni → Statistiche → Widget Usage**

```
┌─────────────────────────┐
│  Widget Usage           │
│                         │
│  📷 Camera: 45 volte   │
│  🎤 Audio:  23 volte   │
│                         │
│  Preferenza: Camera     │
└─────────────────────────┘
```

---

## 🎉 Fatto!

Ora hai accesso rapido alle funzionalità più usate direttamente dalla home screen!

**Tips:**
- Usa Camera widget per catture rapide di documenti
- Usa Audio widget per note vocali al volo
- Puoi aggiungere entrambi i widget
- Puoi aggiungere multipli dello stesso widget

**Troubleshooting dettagliato:**
📚 `docs/implementation/ANDROID_WIDGETS.md`

**Test automatici:**
⚙️ `android-app/test-widgets.ps1`
