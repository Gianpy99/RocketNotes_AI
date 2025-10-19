# 📚 Topics Feature - Organizzazione Note per Gruppi

## Panoramica

La funzionalità **Topics** ti permette di organizzare le tue note in gruppi tematici (es. viaggi di lavoro, meeting, progetti) e generare **AI summaries** complete di tutto il contenuto.

## 🎯 Casi d'Uso

### 1. Viaggio di Lavoro
- Crea topic: **"Milano Work Trip - Gennaio 2025"**
- Aggiungi note durante il viaggio (meeting, spese, contatti)
- Genera AI summary al ritorno per avere un resoconto completo

### 2. Meeting Ricorrenti
- Topic: **"Q1 Marketing Meeting"**
- Note con decisioni, action items, idee
- AI summary per tracking progressi e azioni

### 3. Progetti
- Topic: **"Project Alpha - Development"**
- Tutte le note relative al progetto
- Summary AI per overview rapido stato progetto

## 🛠️ Come Funziona

### Modelli Creati

1. **`Topic` Model** (`lib/data/models/topic.dart`)
   - `id`: ID univoco
   - `name`: Nome del topic (es. "Milano Trip")
   - `description`: Descrizione opzionale
   - `colorValue`: Colore personalizzato
   - `iconCodePoint`: Icona personalizzata
   - `noteCount`: Numero di note nel topic
   - `isFavorite`: Flag per topic preferiti
   - `userId`: Supporto multi-utente

2. **`NoteModel` - Campo Aggiunto**
   - `topicId`: Riferimento al topic (opzionale)

### Repository

**`TopicRepository`** (`lib/data/repositories/topic_repository.dart`)
- Salvataggio/caricamento topic da Hive
- Filtro per utente corrente
- Ricerca topic
- Toggle favorite

### Servizio AI

**`TopicAIService`** (`lib/data/services/topic_ai_service.dart`)

Metodi principali:
- `generateTopicSummary()`: Summary completo con key points, action items, insights
- `generateTopicInsights()`: Analisi trends nel tempo
- `compareTopics()`: Confronto tra topic multipli

Output strutturato:
```dart
TopicSummary {
  summary: "Panoramica 2-3 frasi"
  keyPoints: ["punto 1", "punto 2", ...]
  actionItems: ["azione 1", "azione 2", ...]
  insights: "Pattern e osservazioni"
  noteCount: 15
}
```

## 📱 UI - Topics Screen

**`TopicsScreen`** (`lib/presentation/screens/topics_screen.dart`)

Features:
- ✅ Lista tutti i topic con colori personalizzati
- ✅ Creazione nuovo topic con dialog
- ✅ Generazione AI summary con loading indicator
- ✅ Menu contestuale: Summary, Favorite, Edit, Delete
- ✅ Contatore note per topic
- ✅ Empty state con istruzioni

## 🎨 Personalizzazione

### Colori Predefiniti
10 colori disponibili in `TopicColors.predefined`:
- Blue, Green, Amber, Pink, Purple, Orange, Cyan, Brown, Blue Grey, Indigo

### Colori Tematici
Map `TopicColors.themed` con colori suggeriti per tipo:
- work → Blue
- travel → Orange
- meeting → Purple
- learning → Cyan
- ecc.

## 🔄 Integrazione

### 1. Inizializzazione Hive
Aggiungi in `main.dart`:
```dart
// Registra adapter Topic
Hive.registerAdapter(TopicAdapter());
await Hive.openBox<Topic>('topics');
```

### 2. Genera Hive Adapter
Esegui build runner:
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

Questo genererà:
- `lib/data/models/topic.g.dart`
- Aggiornamento di `note_model.g.dart` con campo `topicId`

### 3. Aggiunta Route
In `lib/app/routes.dart`:
```dart
GoRoute(
  path: '/topics',
  name: 'topics',
  builder: (context, state) => const TopicsScreen(),
),
```

### 4. Link nel Menu
Aggiungi bottone/menu item per navigare a `/topics`

## 📸 Foto e Immagini

### Storage Foto AI Analysis

**Posizione attuale**: Le foto scattate con `ImagePicker` vengono salvate temporaneamente nella cache del dispositivo:
- Android: `/data/data/com.example.pensieve/cache/`
- Path ottenuto da `XFile.path` dopo scatto

**Allegati Note**:
Il campo `attachments` in `NoteModel` contiene i path delle foto/file allegati:
```dart
@HiveField(7)
List<String> attachments;
```

**Per storage permanente** potresti implementare:
1. Copia foto in `getApplicationDocumentsDirectory()`
2. Upload su Firebase Storage
3. Salva URL in `attachments[]`

## 🚀 Prossimi Passi

### Immediate
1. ✅ Run build_runner per generare adapters
2. ✅ Registra Topic adapter in main.dart
3. ✅ Aggiungi route in routes.dart
4. ✅ Testa creazione topic e AI summary

### Future Enhancements
- [ ] Filtro note per topic nella NotesListScreen
- [ ] Batch assign: seleziona multiple note → assegna topic
- [ ] Export topic summary in PDF/Markdown
- [ ] Grafici statistiche per topic (note nel tempo)
- [ ] Sync topic su Firestore (come NoteSyncService)
- [ ] Topic templates (Meeting, Travel, Project)
- [ ] Sub-topics (topic gerarchici)

## 📊 Esempio Workflow Completo

1. **Crea Topic**
   - Tap FAB "New Topic"
   - Nome: "Milano Business Trip"
   - Colore: Blue
   - Descrizione: "Meeting clienti e fiera settembre"

2. **Assegna Note**
   - Durante il viaggio, crea note
   - In editor nota, seleziona topic "Milano Business Trip"
   - Note salvate con `topicId` popolato

3. **Genera Summary**
   - Apri Topics screen
   - Tap menu (⋮) sul topic
   - Seleziona "AI Summary"
   - Attendi elaborazione
   - Visualizza: overview, key points, action items, insights

4. **Revisione**
   - Summary salvato per riferimento futuro
   - Export o condividi con team
   - Action items convertibili in task

## 🔧 Troubleshooting

### Build errors "topic.g.dart not found"
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Topic non mostrati
- Verifica `userId` matching in TopicRepository
- Check Hive box aperto correttamente

### AI Summary errore
- Verifica configurazione AI service
- Check API key provider AI
- Logs: `[TopicAI]` per debug

## 📝 Note Tecniche

- **Type ID Hive**: Topic usa `typeId: 5` (assicurati non in conflitto)
- **Field ID Note**: `topicId` usa `@HiveField(16)`
- **Sync Firestore**: Topic al momento solo local (Hive)
- **Performance**: AI summary può richiedere 5-10s per topic con 50+ note

---

**Creato**: 2025-10-19
**Versione**: 1.0.0
**Autore**: GitHub Copilot per RocketNotes AI / Pensieve
