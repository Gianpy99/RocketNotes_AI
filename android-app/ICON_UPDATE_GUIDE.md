# Script per aggiornare l'icona dell'app RocketNotes AI
# Questo script ti guiderà nel processo di sostituzione dell'icona

## Passaggi per aggiornare l'icona dell'app:

### 1. Preparazione delle immagini
Dovrai creare le seguenti versioni dell'immagine del calderone:

- **ic_launcher.png** per mipmap-mdpi: 48x48 px
- **ic_launcher.png** per mipmap-hdpi: 72x72 px  
- **ic_launcher.png** per mipmap-xhdpi: 96x96 px
- **ic_launcher.png** per mipmap-xxhdpi: 144x144 px
- **ic_launcher.png** per mipmap-xxxhdpi: 192x192 px

### 2. Strumenti consigliati:
- **Android Studio**: Ha un generatore di icone integrato
- **Online**: https://romannurik.github.io/AndroidAssetStudio/icons-launcher.html
- **GIMP/Photoshop**: Per ridimensionamento manuale

### 3. Posizioni dei file:
```
android/app/src/main/res/
├── mipmap-mdpi/ic_launcher.png     (48x48)
├── mipmap-hdpi/ic_launcher.png     (72x72)
├── mipmap-xhdpi/ic_launcher.png    (96x96)
├── mipmap-xxhdpi/ic_launcher.png   (144x144)
└── mipmap-xxxhdpi/ic_launcher.png  (192x192)
```

### 4. Comandi per il backup delle icone attuali:
```bash
cd android/app/src/main/res
mkdir backup_icons
cp mipmap-*/ic_launcher.png backup_icons/
```

### 5. Dopo aver sostituito le icone:
```bash
flutter clean
flutter build apk
```

## Note importanti:
- L'immagine del calderone dorato è perfetta per l'app RocketNotes AI
- Assicurati che l'immagine sia ben visibile anche a 48x48 px
- Considera di aggiungere un background solido se necessario
- Testa l'icona su diversi launcher Android
