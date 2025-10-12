# Audio Transcription & Translation System

## Overview
Implementazione completa di registrazione audio, trascrizione AI e traduzione intelligente con ottimizzazione dei costi.

## Features

### 1. **Registrazione Audio**
- Registrazione tramite package `record` (AAC/M4A, 128kbps)
- Controlli: Start, Pause, Resume, Stop, Cancel
- Timer in tempo reale
- Indicatore visivo livello audio
- Gestione permessi microfono

### 2. **Trascrizione AI Multi-Provider**

#### OpenAI Whisper
- Modello: `whisper-1`
- Accuratezza: ~95%
- Supporto multilingua (99+ lingue)
- Rilevamento automatico lingua
- Pricing: $0.006/minuto audio
- Response format: `verbose_json` (include metadata)

#### Google Gemini Native Audio
- Modello: `gemini-2.5-flash` o `gemini-2.5-flash-native-audio`
- Supporto audio nativo (no conversion)
- Rilevamento lingua integrato
- Pricing: $3.00 per 1M audio tokens (~$0.003-0.006/minuto)
- Response format: JSON strutturato

#### Fallback Locale
- Usa `speech_to_text` package
- Nessun costo API
- Accuratezza ridotta (~60-70%)
- Richiede configurazione provider AI

### 3. **Smart Translation**

#### Logica Intelligente
```dart
// Traduce SOLO se necessario
detectedLanguage != targetLanguage
```

**Esempio:**
- Audio in inglese → utente italiano → **traduzione automatica**
- Audio in italiano → utente italiano → **nessuna traduzione** (risparmio costi)

#### Provider Translation
- **OpenAI**: `gpt-5-mini` (veloce e economico)
- **Gemini**: `gemini-2.5-flash` (gratuito fino a limiti)
- Temperatura bassa (0.3) per consistenza
- Max tokens: 1000 (sufficiente per la maggior parte dei casi)

### 4. **Cost Tracking & Optimization**

#### Metriche Salvate
- Costo per richiesta ($USD)
- Provider e modello utilizzato
- Durata processing (ms)
- Token stimati
- Confidence score

#### Ottimizzazioni
1. **Whisper vs Gemini**: Scegli in base al caso d'uso
   - Whisper: audio lungo, qualità massima
   - Gemini: audio breve, free tier disponibile

2. **Translation On-Demand**: Solo se lingua diversa

3. **Compression**: Audio AAC 128kbps (bilanciamento qualità/dimensione)

4. **Batch Processing**: Possibilità di elaborare più file in coda

## Usage

### In una schermata:
```dart
import 'package:pensieve/presentation/widgets/audio_note_recorder.dart';

AudioNoteRecorder(
  targetLanguage: 'it', // Lingua preferita utente
  onTranscriptionComplete: (transcription, translation) {
    // Usa il testo trascritto
    print('Original: $transcription');
    if (translation != null) {
      print('Translated: $translation');
    }
  },
)
```

### Schermata dedicata:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => AudioNoteScreen(),
  ),
);
```

### Servizio standalone:
```dart
final result = await AudioTranscriptionService.instance.transcribeAudio(
  audioFilePath: '/path/to/audio.m4a',
  targetLanguage: 'it',
  autoTranslate: true,
);

print('Transcription: ${result.transcription}');
print('Language: ${result.detectedLanguage}');
print('Cost: \$${result.estimatedCost}');
if (result.translation != null) {
  print('Translation: ${result.translation}');
}
```

## Configuration

### Settings (AppSettingsModel)
```dart
aiProvider: 'openai' | 'gemini'
audioTranscriptionModel: 'whisper-1' | 'gemini-2.5-flash-native-audio'
```

### API Keys (api_config.dart)
```dart
static const String actualOpenAIKey = 'sk-...';
static const String actualGeminiKey = 'AIza...';
```

## Cost Estimates

### Scenario: Meeting di 30 minuti

#### OpenAI Whisper
- Durata: 30 min
- Costo trascrizione: 30 × $0.006 = **$0.18**
- Traduzione (se necessaria): ~500 token input + 500 output
  - gpt-5-mini: (0.5M/1000K) × $0.125 + (0.5M/1000K) × $1.00 = **$0.0006**
- **Totale: ~$0.18-0.19**

#### Gemini Flash
- Durata: 30 min (~1.8 MB audio)
- Stima token: ~180K audio tokens
- Costo trascrizione: (180K/1M) × $3.00 = **$0.54**
- Traduzione (free tier Gemini): **$0.00**
- **Totale: ~$0.54**

**Raccomandazione**: OpenAI Whisper per trascrizioni lunghe, Gemini per brevi sessioni (< 5 min) sfruttando free tier.

## Analytics Integration

I dati vengono salvati in `UsageMonitoringModel`:
- `dailyUsage`: conteggio richieste e costi per giorno
- `monthlySpending`: totale mensile per provider
- Visualizzabili in Cost Monitoring screen

## Future Enhancements

1. **Batch Processing**: elabora più file offline
2. **Speaker Diarization**: identifica chi parla (Whisper API supporta)
3. **Real-time Streaming**: trascrizione live (Gemini 2.0 Live API)
4. **Custom Vocabulary**: terminologia specifica per dominio
5. **Summary Generation**: riassunto automatico post-trascrizione
6. **Action Items Extraction**: estrai TODO dal contenuto

## Testing

Per testare:
1. Configura API keys in `api_config.dart`
2. Lancia l'app su device con microfono
3. Naviga a Audio Note screen
4. Registra audio (almeno 5 secondi)
5. Verifica trascrizione e traduzione (se lingue diverse)
6. Controlla costo in Cost Monitoring

## Troubleshooting

### "Microphone permission denied"
- Android: aggiungi `<uses-permission android:name="android.permission.RECORD_AUDIO"/>` in `AndroidManifest.xml`
- iOS: aggiungi `NSMicrophoneUsageDescription` in `Info.plist`

### "OpenAI/Gemini API key not configured"
- Verifica che `ApiConfig.actualOpenAIKey` o `actualGeminiKey` siano impostati
- Controlla che le chiavi siano valide e con credito disponibile

### "Transcription failed"
- Verifica connessione internet
- Controlla lunghezza audio (max ~25MB per Whisper)
- Prova con un audio più breve per test

### Costi elevati
- Abilita `enableCostOptimization` in UsageMonitoringModel
- Imposta `dailySpendingLimit` appropriato
- Considera Gemini free tier per brevi sessioni
- Disabilita auto-traduzione se non necessaria

---

**Autore**: Implementazione completa audio AI  
**Data**: Ottobre 2025  
**Licenza**: Privato - RocketNotes AI
