
# RocketNotes AI — Recap Progetto e PRD

---

## 1. Recap Progetto

### Hardware e strumenti
- Rocketbook Fusion Plus Executive size (notebook riutilizzabile)
- NFC Tags NTAG213 (144 byte), programmati con app NFC Tools
- Smartphone target: Google Pixel 7a (NFC read/write)
  
### Funzionalità chiave
- Lettura NFC per riconoscere tag personalizzati (work/personal)
- Deep linking con schema URI `rocketnotes://work` e `rocketnotes://personal`
- Avvio automatico app in modalità corrispondente al tag NFC
- Integrazione futura con AI per suggerimenti appunti

### Flusso utente
- Due tag NFC programmati con URI differenti posizionati su Rocketbook Capsule 2 folio cover
- Utente avvicina telefono al tag per aprire l’app con modalità specifica

---

## 2. Product Requirements Document (PRD)

### Obiettivi
- Fornire un’app per gestione appunti su Rocketbook con workflow personalizzato
- Semplificare apertura app tramite NFC con distinzione lavoro/personale
- Supportare AI per estrazione idee e suggerimenti dagli appunti

### Funzionalità principali
- Lettura NFC e parsing record URI o testo
- Deep linking con schema URI personalizzato
- UI semplice con due modalità: Work e Personal
- Salvataggio appunti e taggatura automatica in base modalità NFC
- Integrazione API AI per analisi testo e suggerimenti

### UX/UI
- Schermata home che mostra modalità attiva
- Possibilità di switch manuale modalità
- Notifiche o suggerimenti AI in overlay o sezione dedicata

### Requisiti tecnici
- Flutter come framework multipiattaforma
- Uso pacchetti `flutter_nfc_kit` e `uni_links`
- AndroidManifest.xml configurato per intent-filter URI scheme
- Supporto NFC standard NTAG213
- Persistenza dati locale (SQLite o altro)

---

## 3. Prompt di esempio per Copilot Pro / GPT-5 / Claude4

```
You are an expert Flutter developer.  
You have to implement a cross-platform app named "RocketNotes AI" to manage notes from Rocketbook.  
The app must support NFC reading of custom URI tags with scheme "rocketnotes://", to switch between "work" and "personal" modes automatically.  
It should handle deep linking on Android with intent filters, and parse the URI to update the UI accordingly.  
Implement NFC reading using flutter_nfc_kit and URI listening with uni_links.  
The app UI has a simple home screen showing the current mode.  
Add hooks for future AI integration for suggestions based on user notes.  
Write clean, maintainable, and well-commented code.

Start by setting up AndroidManifest.xml and main.dart with URI scheme handling and NFC reading.  
```
