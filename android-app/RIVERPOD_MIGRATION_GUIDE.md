# 🚀 Guida alla Migrazione Riverpod 2.x → 3.x

## 📋 Sommario delle Modifiche

### ❌ Rimosso
- `StateNotifierProvider` → Sostituito con `NotifierProvider`
- `StateNotifier` → Sostituito con `Notifier` / `AsyncNotifier`
- `StateProvider` → Sostituito con `NotifierProvider`
- `FutureProviderFamily` → Sostituito con `.family` modifier
- Accesso a `state` nelle classi → Usa `ref` al suo posto

### ✅ Nuovo Pattern

## 🔄 Pattern di Migrazione

### 1. StateNotifierProvider → NotifierProvider

#### ❌ Prima (Riverpod 2.x)
```dart
final counterProvider = StateNotifierProvider<CounterNotifier, int>((ref) {
  return CounterNotifier();
});

class CounterNotifier extends StateNotifier<int> {
  CounterNotifier() : super(0);

  void increment() {
    state = state + 1;
  }
}
```

#### ✅ Dopo (Riverpod 3.x)
```dart
@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;

  void increment() {
    state = state + 1;
  }
}
```

### 2. StateProvider → NotifierProvider

#### ❌ Prima
```dart
final nameProvider = StateProvider<String>((ref) => '');
```

#### ✅ Dopo
```dart
@riverpod
class Name extends _$Name {
  @override
  String build() => '';
  
  void update(String newName) => state = newName;
}
```

### 3. FutureProviderFamily → Family Modifier

#### ❌ Prima
```dart
final userProvider = FutureProviderFamily<User, String>((ref, userId) async {
  return fetchUser(userId);
});
```

#### ✅ Dopo
```dart
@riverpod
Future<User> user(UserRef ref, String userId) async {
  return fetchUser(userId);
}
```

### 4. AsyncNotifier per Operazioni Asincrone

#### ✅ Nuovo Pattern
```dart
@riverpod
class UserData extends _$UserData {
  @override
  Future<User> build(String userId) async {
    return fetchUser(userId);
  }

  Future<void> updateUser(User user) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => updateUserApi(user));
  }
}
```

## 📦 Setup Richiesto

### 1. Aggiorna pubspec.yaml
```yaml
dependencies:
  flutter_riverpod: ^3.0.3
  riverpod_annotation: ^3.0.0

dev_dependencies:
  riverpod_generator: ^3.0.0
  build_runner: ^2.4.13
```

### 2. Genera il codice
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 🔧 Modifiche Necessarie per RocketNotes

### File da Aggiornare (in ordine di priorità):

1. **Provider Core**:
   - `lib/presentation/providers/app_providers.dart`
   - `lib/presentation/providers/app_providers_simple.dart`

2. **Feature Providers**:
   - `lib/features/family/providers/auth_providers.dart`
   - `lib/features/family/providers/family_providers.dart`
   - `lib/features/shared_notes/providers/shared_notes_providers.dart`

3. **Service Providers**:
   - `lib/providers/notification_providers.dart`
   - `lib/providers/shopping_providers.dart`
   - `lib/providers/user_profile_provider.dart`

4. **Widget Providers**:
   - `lib/presentation/widgets/audio_note_recorder.dart`
   - `lib/features/rocketbook/camera/camera_screen.dart`

## 🎯 Strategia di Migrazione

### Fase 1: Setup
- ✅ Aggiungere dipendenze riverpod_annotation/generator
- ✅ Configurare build_runner

### Fase 2: Migrazione Graduale
1. Migrare un provider alla volta
2. Generare il codice con build_runner
3. Aggiornare i consumer del provider
4. Testare

### Fase 3: Pulizia
- Rimuovere vecchi import non necessari
- Rigenerare tutto il codice
- Test completi

## ⚠️ Note Importanti

1. **Code Generation Obbligatorio**: Riverpod 3.x usa code generation con `riverpod_generator`
2. **Import Changes**: Usa `import 'package:riverpod_annotation/riverpod_annotation.dart';`
3. **Part Files**: Ogni provider file necessita di `part 'filename.g.dart';`

## 🔍 Riferimenti

- [Riverpod 3.0 Migration Guide](https://riverpod.dev/docs/migration/from_state_notifier)
- [Code Generation](https://riverpod.dev/docs/concepts/about_code_generation)
