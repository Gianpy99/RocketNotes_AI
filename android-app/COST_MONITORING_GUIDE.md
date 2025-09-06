# 🚀 RocketNotes AI - Sistema di Monitoraggio Costi

## 📋 Panoramica

Il sistema di monitoraggio dei costi è stato completamente implementato per garantire un controllo intelligente delle spese API e l'ottimizzazione automatica dell'utilizzo dei modelli AI.

## ⚡ Funzionalità Principali

### 🎯 Monitoraggio in Tempo Reale
- **Tracciamento automatico** di tutte le chiamate API (Gemini, OpenAI)
- **Calcolo dei costi** basato sui prezzi ufficiali aggiornati
- **Limiti personalizzabili** giornalieri e mensili
- **Persistenza locale** con Hive per performance ottimali

### 🧠 Selezione Intelligente dei Modelli
- **Switch automatico** verso modelli gratuiti quando si avvicinano i limiti
- **Ottimizzazione Gemini 2.5 Flash** per restare nel free tier (25 richieste/giorno, 1500 grounding/giorno)
- **Gestione tier OpenAI** con preferenza per Flex quando possibile
- **Algoritmi predittivi** per evitare sorprese nei costi

### 📊 Dashboard Completa
- **Overview costi** giornalieri e mensili
- **Breakdown per provider** (Gemini vs OpenAI)
- **Statistiche di utilizzo** dettagliate
- **Consigli di ottimizzazione** automatici
- **Gestione budget** con alert proattivi

## 💰 Struttura Prezzi Implementata

### Gemini 2.5 Flash
- **Free Tier**: 25 richieste/giorno, 1500 grounding/giorno
- **Paid**: $0.075/1M input tokens, $0.30/1M output tokens
- **Context Caching**: $0.01875/1M cached tokens/hour

### OpenAI Models
- **Flex Tier**: Prezzi variabili con sconto del 50% su cached input
- **Standard Tier**: Prezzi fissi standard
- **Priority Tier**: Accesso prioritario con premium pricing

## 🚀 Come Accedere

1. Apri l'app RocketNotes AI
2. Vai in **Impostazioni** ⚙️
3. Sezione **AI Configuration**
4. Tocca **Cost Monitoring** 📊
5. Esplora dashboard e configura i tuoi limiti

## ⚙️ Configurazione Consigliata

### Per Utilizzo Leggero
- **Limite giornaliero**: $1.00
- **Limite mensile**: $20.00
- **Auto-switch**: Abilitato per Gemini free tier

### Per Utilizzo Intensivo
- **Limite giornaliero**: $5.00
- **Limite mensile**: $100.00
- **Monitoring**: Alert al 80% del budget

## 🛡️ Sicurezza e Privacy

- **Dati locali**: Tutti i dati di monitoraggio restano sul dispositivo
- **Nessun tracking**: Non vengono inviati dati di utilizzo a terzi
- **Crittografia**: Storage Hive con sicurezza nativa

## 🔧 File di Implementazione

### Modelli di Dati
- `lib/data/models/usage_monitoring_model.dart` - Modello Hive per tracciamento
- `lib/data/models/usage_monitoring_model.g.dart` - Codice generato

### Servizi
- `lib/data/services/cost_monitoring_service.dart` - Logica core di monitoraggio
- `lib/features/rocketbook/ai_analysis/ai_service.dart` - Configurazione modelli e prezzi

### UI
- `lib/presentation/screens/cost_monitoring_screen.dart` - Dashboard completa
- `lib/presentation/screens/settings_screen.dart` - Integrazione nelle impostazioni

## ✅ Status di Implementazione

- ✅ **Gemini 2.5 Flash** configurato con prezzi ufficiali
- ✅ **OpenAI Flex/Standard/Priority** tiers implementati
- ✅ **Sistema di tracking** completamente funzionale
- ✅ **UI dashboard** con tutte le funzionalità
- ✅ **Switch intelligente** per free tier
- ✅ **Persistenza Hive** ottimizzata
- ✅ **Integrazione settings** completata

## 🚀 Prossimi Step

Il sistema è **completamente pronto** per l'utilizzo in produzione. Tutti i rate e pricing sono allineati con i dati ufficiali forniti e il sistema di ottimizzazione intelligente garantisce un controllo totale sui costi.

---

*Implementato con ❤️ per RocketNotes AI - Smart Cost Management*
