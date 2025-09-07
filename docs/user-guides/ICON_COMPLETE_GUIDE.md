# 🎨 Guida per Aggiornare l'Icona dell'App RocketNotes AI

## 📖 Panoramica
Questa guida ti aiuterà a sostituire l'icona attuale dell'app con la bellissima immagine del calderone dorato che hai fornito.

## ✅ Backup Completato
Le icone attuali sono state salvate in: `backup_icons_manual/`

## 🔧 Metodi per Generare le Icone

### Metodo 1: Android Studio (Consigliato)
1. Apri Android Studio
2. Vai su **File → New → Image Asset**
3. Seleziona **Launcher Icons (Legacy)**
4. Carica l'immagine del calderone
5. Configura padding e forma
6. Genera automaticamente tutte le dimensioni

### Metodo 2: Online Tool (Veloce)
1. Visita: https://romannurik.github.io/AndroidAssetStudio/icons-launcher.html
2. Carica l'immagine del calderone
3. Configura le impostazioni:
   - **Name**: ic_launcher
   - **Shape**: Circle o Square (a tua scelta)
   - **Theme**: None
4. Scarica il ZIP generato
5. Estrai e copia i file nelle cartelle appropriate

### Metodo 3: Manuale con GIMP/Photoshop
Crea le seguenti dimensioni manualmente:

## 📏 Dimensioni Richieste

| Densità | Dimensione | Cartella |
|---------|------------|----------|
| mdpi    | 48x48 px   | mipmap-mdpi    |
| hdpi    | 72x72 px   | mipmap-hdpi    |
| xhdpi   | 96x96 px   | mipmap-xhdpi   |
| xxhdpi  | 144x144 px | mipmap-xxhdpi  |
| xxxhdpi | 192x192 px | mipmap-xxxhdpi |

## 📂 Posizioni dei File
Sostituisci i file in queste cartelle:
```
android/app/src/main/res/
├── mipmap-mdpi/ic_launcher.png     (48x48)
├── mipmap-hdpi/ic_launcher.png     (72x72)
├── mipmap-xhdpi/ic_launcher.png    (96x96)
├── mipmap-xxhdpi/ic_launcher.png   (144x144)
└── mipmap-xxxhdpi/ic_launcher.png  (192x192)
```

## 🎯 Suggerimenti per l'Immagine del Calderone

### Ottimizzazioni:
- **Contrasto**: Assicurati che il calderone sia ben visibile su sfondi scuri e chiari
- **Dettagli**: I dettagli devono essere visibili anche a 48x48 px
- **Padding**: Lascia un po' di spazio attorno al calderone
- **Background**: Considera un background solido dorato/arancione

### Varianti suggerite:
1. **Versione Semplice**: Solo il calderone su sfondo trasparente
2. **Versione con Background**: Calderone su sfondo dorato gradient
3. **Versione Circolare**: Calderone in un cerchio dorato

## 🚀 Dopo la Sostituzione

### Test dell'Icona:
```bash
# Pulisci e ricompila
flutter clean
flutter pub get

# Build per test
flutter build apk --debug

# Installa e testa su dispositivo
flutter install
```

### Verifica:
1. Controlla l'icona nel launcher
2. Verifica su diversi launcher Android
3. Testa su dispositivi con densità diverse
4. Controlla in modalità dark/light

## 🎨 Personalizzazioni Aggiuntive

### Se vuoi aggiungere elementi RocketNotes:
- Piccola icona "note" o "rocket" nell'angolo
- Effetto glow dorato
- Nome app sotto l'icona (configurable in AndroidManifest.xml)

### Colori del tema da considerare:
- **Oro/Arancione**: #FF8C00, #FFA500, #FFD700
- **Bronzo**: #CD7F32
- **Gradient**: Arancione scuro → Oro chiaro

## 📱 Test su Diversi Launchers
- Stock Android Launcher
- Nova Launcher
- Microsoft Launcher
- Samsung One UI

## 🔄 Come Ripristinare l'Icona Originale
Se necessario, copia i file da `backup_icons_manual/` nelle cartelle originali:
```bash
copy backup_icons_manual\ic_launcher_mdpi.png android\app\src\main\res\mipmap-mdpi\ic_launcher.png
copy backup_icons_manual\ic_launcher_hdpi.png android\app\src\main\res\mipmap-hdpi\ic_launcher.png
# ... e così via per tutte le densità
```

## 💡 Note Finali
- L'immagine del calderone è perfetta per RocketNotes AI
- Rappresenta creatività, trasformazione e "brewing ideas"
- I colori dorati si abbinano bene al tema premium dell'app

Buona fortuna con la tua nuova icona! 🎨✨
