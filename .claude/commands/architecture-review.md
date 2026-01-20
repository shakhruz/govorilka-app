---
description: Обзор архитектуры приложения Govorilka — MVVM, сервисы, управление состоянием
---

# Команда: Architecture Review

Проанализируй архитектуру Swift/SwiftUI приложения Govorilka.

## Области анализа

### 1. MVVM Pattern

Проверь структуру:
```
ViewModels/
├── AppState.swift      # Центральный state (594 строки — слишком много!)

Views/
├── MenuBarView.swift
├── RecordingView.swift
├── HistoryView.swift
└── SettingsView.swift
```

**Вопросы**:
- Чёткое разделение View/ViewModel/Model?
- AppState — God Object?
- Бизнес-логика только в ViewModel?

### 2. Сервисы

Проверь `Services/`:
- Есть ли протоколы для абстракции?
- Dependency injection или singleton?
- Можно ли тестировать изолированно?

**Ожидаемые сервисы**:
- AudioService — захват аудио
- DeepgramService — WebSocket API
- PasteService — clipboard
- StorageService — persistence
- TextCleanerService — обработка текста

### 3. Delegate Pattern

Проверь реализацию:
- `AudioServiceDelegate` — аудио чанки
- `DeepgramServiceDelegate` — транскрипции

**Вопросы**:
- Weak references?
- Main thread dispatch?

### 4. State Management

- Как управляется состояние записи?
- Есть ли state machine enum?
- Race conditions при async?

## Формат отчёта

```markdown
## Architecture Review

### Strengths
- ...

### Issues

#### HIGH: God Object
- **File**: AppState.swift (594 lines)
- **Problem**: ...
- **Solution**: ...

### Dependency Graph
```
AppState
├── AudioService
├── DeepgramService
└── ...
```

### Recommendations
1. [ ] Разделить AppState на координаторы
2. [ ] Добавить протоколы для сервисов
3. [ ] State machine для записи
```

## Рекомендации по рефакторингу

### Разделение AppState

```swift
// Вместо одного огромного AppState:
class RecordingCoordinator: ObservableObject { }
class HistoryCoordinator: ObservableObject { }
class SettingsCoordinator: ObservableObject { }

class AppCoordinator: ObservableObject {
    @Published var recording: RecordingCoordinator
    @Published var history: HistoryCoordinator
    @Published var settings: SettingsCoordinator
}
```

### Протоколы для сервисов

```swift
protocol AudioServiceProtocol {
    var delegate: AudioServiceDelegate? { get set }
    func startCapture() throws
    func stopCapture()
}
```
