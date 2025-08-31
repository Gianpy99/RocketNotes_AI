# 🔑 Configurazione API OpenAI - AGGIORNATA

## ✅ Nuova Struttura Sicura

Ora le chiavi API sono gestite in un file separato per maggiore sicurezza!

### 📁 File da Configurare

**File**: `android-app/lib/core/services/openai_config.dart`

### 🔧 Come Configurare

1. **Apri il file** `openai_config.dart`
2. **Sostituisci** `your-openai-api-key-here` con la tua vera API key OpenAI
3. **Salva** il file

### 📋 Esempio di Configurazione

```dart
class OpenAIConfig {
  // 🔑 AGGIUNGI QUI LA TUA API KEY OPENAI
  static const String apiKey = 'sk-proj-ABCdef123456789...'; // LA TUA CHIAVE
  
  // 🔧 CONFIGURAZIONI (opzionali)
  static const String model = 'gpt-4o-mini';          // Modello AI
  static const int maxTokens = 1000;                  // Massimo token per risposta
  static const double temperature = 0.1;              // Precisione dell'analisi (0.0-1.0)
  
  // 📊 OTTIMIZZAZIONE COSTI
  static const bool enableCostOptimization = true;
  static const int maxImageSize = 1024;               // Pixel massimi per lato
  static const int compressionQuality = 85;           // Qualità compressione (0-100)
}
```

### 🔒 Sicurezza

- ✅ **File protetto**: `openai_config.dart` è nel `.gitignore`
- ✅ **Non versionato**: Le tue chiavi non vanno mai su GitHub
- ✅ **Configurazione centralizzata**: Tutti i parametri in un posto

### 🚀 Vantaggi

- **Sicurezza**: Chiavi API protette da git
- **Flessibilità**: Configura modello, token, qualità immagini
- **Ottimizzazione**: Controllo completo sui costi
- **Semplicità**: Un solo file da configurare

### 🔄 Migrazione

Se hai già configurato la chiave nel vecchio file:
1. **Copia** la tua API key dal vecchio `openai_service.dart`
2. **Incolla** nel nuovo `openai_config.dart`
3. **Testa** l'app per verificare funzionamento

---

**⚠️ IMPORTANTE**: Non condividere mai le tue API key OpenAI!  
**📁 File da configurare**: `android-app/lib/core/services/openai_config.dart`
