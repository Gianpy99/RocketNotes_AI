# 📱 Piano di Test RocketNotes AI - Telefono Fisico
**Data**: 20 Ottobre 2025  
**Dispositivo**: Pixel 7a (Android 16 API 36)  
**Build**: Debug con aggiornamenti pacchetti v2.0

---

## 🎥 TEST CAMERA (PRIORITÀ MASSIMA)

### ✅ Funzionalità da Testare:

1. **Tap-to-Focus** 🎯
   - [ ] Tocca lo schermo → Visualizza indicatore circolare bianco
   - [ ] Immagine si focalizza sul punto toccato
   - [ ] Funziona in diverse condizioni di luce

2. **Qualità Immagine** 📸
   - [ ] Risoluzione: VeryHigh (verifica nelle impostazioni)
   - [ ] Nitidezza testo acquisito
   - [ ] Confronta con versione precedente

3. **Auto-Focus Continuo** 🔄
   - [ ] La camera mantiene il focus automaticamente
   - [ ] Nessun blur quando si muove il telefono

4. **Zoom** 🔍
   - [ ] Slider zoom funziona (se implementato)
   - [ ] Pinch-to-zoom (se disponibile)
   - [ ] Qualità mantiene

5. **Flash/Lighting** 💡
   - [ ] Flash auto funziona in stanza buia
   - [ ] Modalità ON/OFF/AUTO

6. **Performance** ⚡
   - [ ] Tempo avvio camera: ___ secondi
   - [ ] Lag durante preview: Sì/No
   - [ ] Crash o freeze: Sì/No

---

## 🎤 TEST AUDIO RECORDING

### ✅ Funzionalità da Testare:

1. **Qualità Audio** 🎙️
   - [ ] Chiarezza voce registrata
   - [ ] Riduzione rumore ambientale
   - [ ] Volume adeguato

2. **UI Controls** 🎛️
   - [ ] Pulsante record/stop funziona
   - [ ] Indicatore visivo durante recording
   - [ ] Timer visualizzato

3. **Salvataggio** 💾
   - [ ] Audio salvato correttamente
   - [ ] Playback funziona
   - [ ] Formato file: ___

---

## 🔧 TEST GENERALI

1. **Stabilità App**
   - [ ] Avvio senza errori
   - [ ] Nessun crash durante uso normale
   - [ ] Transizioni fluide tra schermate

2. **Firebase/Backend**
   - [ ] Login funziona
   - [ ] Sync note funziona
   - [ ] Notifiche arrivano

3. **Performance**
   - [ ] Velocità generale: Buona/Media/Scarsa
   - [ ] Consumo batteria: Normale/Alto
   - [ ] Memoria usata: ___

---

## 📝 NOTE E PROBLEMI TROVATI

### Camera:
```
[Scrivi qui eventuali problemi]
```

### Audio:
```
[Scrivi qui eventuali problemi]
```

### Altro:
```
[Scrivi qui altri problemi]
```

---

## 🎯 PRIORITÀ IMMEDIATE SE CI SONO PROBLEMI:

1. **Camera non focalizza bene**
   → Aumentare delay auto-focus
   → Provare FocusMode.locked dopo tap

2. **Qualità immagine bassa**
   → Verificare ResolutionPreset
   → Controllare compressione JPEG

3. **Audio con disturbi**
   → Cambiare encoder
   → Aumentare bitrate

4. **App lenta**
   → Ridurre preview fps
   → Ottimizzare UI rebuild

---

## ✅ CHECKLIST FINALE

- [ ] Camera acquisisce testo nitido
- [ ] Tap-to-focus funziona perfettamente
- [ ] Audio recording è chiaro
- [ ] Nessun crash in 10 minuti di uso
- [ ] Esperienza utente fluida

**Se tutti i check sono ✅ → DEPLOYMENT PRONTO! 🚀**
