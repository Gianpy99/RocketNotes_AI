# 🐛 Issues da Risolvere - Riepilogo Completo

## Data: 20 Ottobre 2025

## ❌ PROBLEMA 1: Overflow in Note Editor (15 pixels)
**File**: `lib/presentation/screens/note_editor_screen.dart` linea 536
**Errore**: `A RenderFlex overflowed by 15 pixels on the bottom`

**Soluzione**: Avvolgere la Column in un `SingleChildScrollView` o ridurre padding/spacing

---

## ❌ PROBLEMA 2: Settings Crash (encryptNotes field rimosso)
**File**: `lib/ui/screens/settings/settings_screen.dart`
**Errore**: Il campo `encryptNotes` è stato rimosso dal model ma è ancora referenziato nella UI

**Status**: ✅ RISOLTO (rimosso il toggle dalla UI)

---

## ❌ PROBLEMA 3: Biometric Lock non visibile in Settings
**File**: `lib/ui/screens/settings/settings_screen.dart`
**Problema**: Il toggle "Biometric Lock" non appare nella sezione Privacy & Security

**Status**: ✅ IMPLEMENTATO ma `enableBiometric` è false di default
**Necessita**: Testare attivazione manuale nelle Settings

---

## ❌ PROBLEMA 4: Page Detection Threshold troppo alto
**File**: `lib/features/rocketbook/processing/page_detector.dart` linea 24
**Problema**: `confidence > 0.5` troppo restrittivo, non accetta pagine valide

**Soluzione**: ✅ IMPLEMENTATA - ridotto a `confidence > 0.35`
**Status**: Codice modificato, da testare con scansione reale

---

## 🧪 TEST DA FARE

### 1. Biometric Lock
- [ ] Vai in Settings → Privacy & Security
- [ ] Attiva "Biometric Lock"
- [ ] Metti app in background
- [ ] Riapri → dovrebbe chiedere fingerprint

### 2. Page Detection
- [ ] Apri fotocamera Rocketbook
- [ ] Scansiona una pagina
- [ ] Verifica che accetti pagine con confidence >= 35%

### 3. Overflow Fix
- [ ] Apri una nota esistente
- [ ] Verifica che non ci sia l'errore "overflowed by X pixels"

---

## 📝 MODIFICHE IMPLEMENTATE (ma non testate)

✅ **BiometricLockWrapper** aggiunto in `app_simple.dart`
✅ **Threshold page detection** ridotto a 0.35
✅ **encryptNotes** rimosso da settings_screen.dart
❌ **Overflow fix** NON ancora implementato

---

## 🚨 PROSSIMO STEP

1. **FIX OVERFLOW** in note_editor_screen.dart (PRIORITÀ ALTA)
2. **TEST BIOMETRIC** lock manualmente
3. **TEST PAGE DETECTION** con scansione reale
