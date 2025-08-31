# 🚀 RocketNotes AI - Configurazione OpenAI

## 🔧 Come configurare l'API Key OpenAI

### 1. Ottieni una API Key da OpenAI

1. Vai su [https://platform.openai.com/api-keys](https://platform.openai.com/api-keys)
2. Crea un account o effettua il login
3. Clicca su "Create new secret key"
4. Copia la chiave API (inizia con `sk-...`)

### 2. Aggiungi l'API Key all'app

1. Apri il file: `android-app/lib/core/services/openai_service.dart`
2. Trova la riga:
   ```dart
   static const String _apiKey = 'YOUR_OPENAI_API_KEY_HERE';
   ```
3. Sostituisci `'YOUR_OPENAI_API_KEY_HERE'` con la tua API key:
   ```dart
   static const String _apiKey = 'sk-proj-abc123...';
   ```

### 3. Ricompila l'app

```bash
cd android-app
flutter clean
flutter pub get
flutter build apk --debug -t lib/main_simple.dart
```

### 4. Installa l'APK aggiornato

Il nuovo APK sarà in: `android-app/build/app/outputs/flutter-apk/app-debug.apk`

## 💡 Funzionalità AI

### Analisi Rocketbook
- **Estrazione testo**: Riconosce scrittura manuale e testo stampato
- **Rilevamento simboli**: Identifica le destinazioni Rocketbook (email, cloud, ecc.)
- **Analisi strutturale**: Distingue titoli, liste, tabelle e diagrammi
- **Azioni automatiche**: Rileva task, promemoria e meeting
- **Metadata**: Valuta qualità dell'immagine e leggibilità

### Campi Rocketbook Standard
L'AI è addestrata per riconoscere questi elementi tipici dei notebook Rocketbook:

1. **Titolo** (in alto)
2. **Corpo principale** (area centrale di scrittura)
3. **Simboli destinazione** (in basso):
   - 📧 Email
   - 💾 Google Drive
   - 📦 Dropbox
   - 🐘 Evernote
   - 💬 Slack
   - ☁️ iCloud
   - 📁 OneDrive

### Tipi di contenuto rilevati:
- **Testo semplice**
- **Liste puntate/numerate**
- **Tabelle**
- **Diagrammi e schemi**
- **Task e promemoria**
- **Note per meeting**

## 🔒 Sicurezza

- L'API key è memorizzata localmente nell'app
- Le immagini vengono compresse prima dell'invio (max 1024px)
- Usa il modello `gpt-4o-mini` per costi ridotti
- Nessuna immagine viene salvata sui server OpenAI

## 💰 Costi Stimati

Con il modello **gpt-4o-mini**:
- Circa **$0.01-0.02** per analisi di immagine
- Compression automatica per ridurre i costi
- Prompt ottimizzato per risposte concise

## 🔧 Personalizzazione

Puoi modificare il comportamento dell'AI editando il metodo `_getRocketbookSystemPrompt()` nel file `openai_service.dart` per:
- Aggiungere rilevamento di elementi specifici
- Modificare il formato di output
- Migliorare l'accuratezza per i tuoi notebook

## 🆘 Troubleshooting

### L'analisi non funziona:
1. Verifica che l'API key sia corretta
2. Controlla la connessione internet
3. Assicurati di avere crediti OpenAI sufficienti

### Risultati non accurati:
1. Scatta foto con buona illuminazione
2. Mantieni il notebook dritto e in focus
3. Evita ombre sulla pagina
4. Usa una risoluzione adeguata (non troppo bassa)

### Errori di compilazione:
1. Esegui `flutter clean`
2. Riavvia VS Code
3. Verifica che tutte le dipendenze siano installate

## 📱 Come usare nell'app

1. Apri RocketNotes AI
2. Tocca il pulsante arancione con l'icona ✨ (AI)
3. Scegli "Scatta Foto" o "Galleria"
4. Attendi l'analisi (5-10 secondi)
5. Rivedi i risultati strutturati
6. Salva come nota (funzione in sviluppo)

---

**Sviluppato con ❤️ per ottimizzare il flusso di lavoro con Rocketbook**
