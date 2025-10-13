# Testing Guide - RocketNotes AI

## Panoramica

Questa guida spiega come eseguire, creare e manutenere i test per RocketNotes AI.

## Struttura Test

```
test/
├── mocks/
│   ├── mock_note_repository.dart       # Mock repository per le note
│   └── mock_settings_repository.dart    # Mock repository per le impostazioni
├── test_helpers/
│   ├── fakes_notifiers.dart            # Fake notifiers per stati specifici
│   └── test_settings_repository.dart    # Helper per mock settings
├── widget_tests/
│   ├── home_screen_test.dart           # Test per HomeScreen
│   ├── settings_screen_test.dart       # Test per SettingsScreen
│   ├── note_list_screen_test.dart      # Test per NoteListScreen
│   ├── search_screen_test.dart         # Test per SearchScreen
│   ├── quick_capture_test.dart         # Test per QuickCaptureScreen
│   ├── favorites_screen_test.dart      # Test per FavoritesScreen
│   └── archive_screen_test.dart        # Test per ArchiveScreen
└── integration_test/
    └── app_test.dart                    # Integration test completo
```

## Eseguire i Test

### Tutti i test
```powershell
flutter test
```

### Solo widget tests
```powershell
flutter test test/widget_tests/
```

### Test specifico
```powershell
flutter test test/widget_tests/home_screen_test.dart
```

### Con coverage
```powershell
flutter test --coverage
```

### Visualizzare coverage report
```powershell
# Genera lcov.info
flutter test --coverage

# Converti in HTML (richiede genhtml)
genhtml coverage/lcov.info -o coverage/html

# Apri nel browser
start coverage/html/index.html
```

## Pattern di Test

### 1. Setup Base per Widget Test

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:pensieve/ui/screens/mia_screen.dart';
import 'package:pensieve/presentation/providers/app_providers.dart' as providers;
import '../mocks/mock_note_repository.dart';

void main() {
  group('MiaScreen', () {
    testWidgets('descrizione test', (tester) async {
      final mockRepo = MockNoteRepository();
      
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (context, state) => const MiaScreen()),
      ]);

      await tester.pumpWidget(
        ProviderScope(overrides: [
          providers.noteRepositoryProvider.overrideWithValue(mockRepo),
        ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Test assertions...
      expect(find.text('Testo atteso'), findsOneWidget);
    });
  });
}
```

### 2. Override Multiple Providers

```dart
await tester.pumpWidget(
  ProviderScope(overrides: [
    providers.noteRepositoryProvider.overrideWithValue(mockRepo),
    providers.settingsRepositoryProvider.overrideWithValue(mockSettings),
  ],
    child: MaterialApp.router(routerConfig: router),
  ),
);
```

### 3. Test con Note Mock

```dart
final mockRepo = MockNoteRepository();
mockRepo.addNote(NoteModel(
  id: '1',
  title: 'Test Note',
  content: 'Content',
  mode: 'personal',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
));
```

### 4. Test Error State

```dart
import '../test_helpers/fakes_notifiers.dart';

// Usa TestErrorNotesNotifier per forzare stato di errore
await tester.pumpWidget(
  ProviderScope(overrides: [
    providers.notesProvider.overrideWith((ref) {
      return TestErrorNotesNotifier(providers.noteRepositoryProvider);
    }),
  ],
    child: MaterialApp.router(routerConfig: router),
  ),
);
```

### 5. Test Interazioni Utente

```dart
// Tap su un button
await tester.tap(find.byIcon(Icons.add));
await tester.pumpAndSettle();

// Inserire testo
await tester.enterText(find.byType(TextField), 'Testo di test');
await tester.pumpAndSettle();

// Scroll
await tester.drag(find.byType(ListView), const Offset(0, -300));
await tester.pumpAndSettle();

// Long press
await tester.longPress(find.text('Item'));
await tester.pumpAndSettle();
```

### 6. Disambiguare Widget Multipli

```dart
// Usa predicati per trovare widget specifici
final mainFab = find.byWidgetPredicate(
  (w) => w is FloatingActionButton && w.heroTag == 'main'
);

// Oppure usa .first / .last
final firstTextField = find.byType(TextField).first;
```

### 7. Screen Size Configuration

```dart
import 'dart:ui' as ui;

testWidgets('test con layout custom', (tester) async {
  // Configura dimensioni schermo per evitare overflow
  tester.binding.window.physicalSizeTestValue = const ui.Size(1080, 1920);
  tester.binding.window.devicePixelRatioTestValue = 1.0;
  
  // ... resto del test
  
  addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
});
```

## Creare Nuovi Test

### 1. Identificare la Schermata

Trova il file della schermata in:
- `lib/ui/screens/`
- `lib/presentation/screens/`
- `lib/screens/`

### 2. Analizzare Dipendenze

Verifica quali provider usa la schermata:
```dart
final notes = ref.watch(notesProvider);
final settings = ref.watch(appSettingsProvider);
```

### 3. Creare Mock se Necessario

Se la schermata usa un nuovo repository, crea un mock in `test/mocks/`:

```dart
class MockNuovoRepository extends NuovoRepository {
  // Implementa metodi necessari...
}
```

### 4. Scrivere Test

Crea file in `test/widget_tests/nome_screen_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
// ... altri import

void main() {
  group('NomeScreen', () {
    testWidgets('test base - screen si carica', (tester) async {
      // Setup
      // Pump widget
      // Assertions
    });
    
    testWidgets('test interazione - button funziona', (tester) async {
      // Test interazioni
    });
    
    testWidgets('test stato - mostra errore correttamente', (tester) async {
      // Test stati
    });
  });
}
```

### 5. Eseguire e Iterare

```powershell
flutter test test/widget_tests/nome_screen_test.dart
```

Correggi errori fino a che tutti i test passano.

## Debugging Test

### Test Fallisce: Widget non trovato

```dart
// Stampa albero widget per debug
debugDumpApp();

// Oppure cerca tutti i widget di un tipo
print(find.byType(Button).evaluate());

// Verifica cosa c'è realmente
expect(find.byType(Scaffold), findsWidgets);
```

### Test Fallisce: Timeout

```dart
// Aumenta timeout
await tester.pumpAndSettle(const Duration(seconds: 5));

// Oppure pump manualmente
for (int i = 0; i < 10; i++) {
  await tester.pump(const Duration(milliseconds: 100));
}
```

### Test Fallisce: Async issues

```dart
// Assicurati di usare await
final notes = await mockRepo.getAllNotes();

// Non dimenticare pumpAndSettle dopo interazioni
await tester.tap(find.text('Save'));
await tester.pumpAndSettle(); // Importante!
```

## Best Practices

### ✅ DO

- Testa comportamenti, non implementazioni
- Usa mock per isolare le dipendenze
- Scrivi test leggibili con nomi descrittivi
- Testa casi edge (empty, error, loading)
- Usa `pumpAndSettle()` dopo interazioni
- Pulisci stato tra test

### ❌ DON'T

- Non testare dettagli implementativi interni
- Non usare hardcoded delays (`await Future.delayed`)
- Non fare test troppo lunghi o complessi
- Non ignorare test falliti
- Non testare logica business nei widget test (usa unit test)

## Troubleshooting Comuni

### Provider non trovato
```dart
// Assicurati di wrappare con ProviderScope
ProviderScope(
  overrides: [...],
  child: MaterialApp(...),
)
```

### Router configuration error
```dart
// Usa GoRouter correttamente
final router = GoRouter(routes: [...]);
MaterialApp.router(routerConfig: router)
```

### Null check operator error
```dart
// Assicurati che tutti i provider siano mockati
// Verifica che AsyncValue sia inizializzato
state = AsyncValue.data(mockData);
```

## Coverage Goals

- **Target Globale**: 70%
- **Widget Tests**: Tutte le schermate principali
- **Unit Tests**: Logica business critica
- **Integration Tests**: Flussi utente principali

## Risorse

- [Flutter Testing Documentation](https://flutter.dev/docs/testing)
- [Riverpod Testing](https://riverpod.dev/docs/cookbooks/testing)
- [Widget Test Best Practices](https://flutter.dev/docs/cookbook/testing/widget)

---
*Guida creata per RocketNotes AI Development Team*
