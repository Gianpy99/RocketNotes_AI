# 🔐 Configurazione API Keys - RocketNotes AI

## 🚨 SICUREZZA IMPORTANTE

Il file `api_config.dart` è ora **ignorato da Git** per evitare di committare accidentalmente le chiavi API. 

## 📋 Setup Iniziale

### 1. Copia il Template
```bash
cd android-app/lib/core/config/
cp api_config.dart.template api_config.dart
```

### 2. Configura le Tue Chiavi

Apri `api_config.dart` e sostituisci:

```dart
static const Map<String, String> developmentKeys = {
  'openai': 'LA_TUA_VERA_CHIAVE_OPENAI_QUI',  // sk-proj-...
  'gemini': 'LA_TUA_VERA_CHIAVE_GEMINI_QUI',  // Se la hai
};
```

### 3. Ottieni le Chiavi API

#### OpenAI (Raccomandato)
1. Vai su: https://platform.openai.com/api-keys
2. Crea una nuova chiave API
3. Copia la chiave (inizia con `sk-proj-` o `sk-`)
4. Incollala al posto di `LA_TUA_VERA_CHIAVE_OPENAI_QUI`

#### Google Gemini (Opzionale)
1. Vai su: https://ai.google.dev/
2. Ottieni una API key
3. Incollala al posto di `LA_TUA_VERA_CHIAVE_GEMINI_QUI`

## ✅ Verifica Configurazione

Una volta inserite le chiavi, l'app:
- ✅ Userà le API reali invece delle simulazioni
- ✅ Mostrerà log come: `🔑 OPENAI DEBUG: API Key configurata: sk-proj-...`
- ✅ Le chiamate appariranno nel dashboard OpenAI

## 🛡️ Sicurezza

- ✅ `api_config.dart` è in `.gitignore`
- ✅ Le chiavi non vengono mai committate
- ✅ Solo il template viene versionato
- ⚠️ **MAI** condividere le chiavi API!

## 🔄 Ripristino Template

Se hai problemi, ripristina dal template:
```bash
cp api_config.dart.template api_config.dart
```

Poi riconfigura le tue chiavi.
