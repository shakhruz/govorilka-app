---
description: Настройка тестирования для Govorilka — XCTest target, unit тесты, mock объекты
---

# Команда: Setup Tests

Настрой тестирование для macOS-приложения Govorilka.

## Текущее состояние

- **Тесты**: 0
- **Покрытие**: 0%
- **CI/CD**: не настроен

## Задача 1: Создать Test Target

### Добавь в project.yml

```yaml
targets:
  GovorilkaTests:
    type: bundle.unit-test
    platform: macOS
    deploymentTarget: "13.0"
    sources:
      - GovorilkaTests
    dependencies:
      - target: Govorilka
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: com.govorilka.tests
      TEST_HOST: "$(BUILT_PRODUCTS_DIR)/Govorilka.app/Contents/MacOS/Govorilka"
      BUNDLE_LOADER: "$(TEST_HOST)"
```

### Создай структуру

```bash
mkdir -p GovorilkaTests
```

## Задача 2: Написать первые тесты

### Приоритет тестирования

| Компонент | Сложность | Приоритет |
|-----------|-----------|-----------|
| TextCleanerService | Easy | HIGH — чистые функции |
| TranscriptEntry | Easy | HIGH — модель |
| StorageService | Medium | MEDIUM — нужен mock |
| AppState | Hard | LOW — много зависимостей |

### TextCleanerServiceTests.swift

Создай файл `GovorilkaTests/TextCleanerServiceTests.swift`:

```swift
import XCTest
@testable import Govorilka

final class TextCleanerServiceTests: XCTestCase {
    var sut: TextCleanerService!

    override func setUp() {
        super.setUp()
        sut = TextCleanerService()
    }

    func test_clean_trimsWhitespace() {
        XCTAssertEqual(sut.clean("  Hello  "), "Hello")
    }

    func test_clean_emptyString() {
        XCTAssertEqual(sut.clean(""), "")
    }
}
```

### TranscriptEntryTests.swift

```swift
import XCTest
@testable import Govorilka

final class TranscriptEntryTests: XCTestCase {
    func test_init_setsProperties() {
        let entry = TranscriptEntry(text: "Test", date: Date())
        XCTAssertEqual(entry.text, "Test")
    }

    func test_codable() throws {
        let entry = TranscriptEntry(text: "Test", date: Date())
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(TranscriptEntry.self, from: data)
        XCTAssertEqual(entry.id, decoded.id)
    }
}
```

## Задача 3: Mock объекты

### Создай протоколы

Добавь протоколы в сервисы для возможности мокирования:

```swift
protocol AudioServiceProtocol {
    var delegate: AudioServiceDelegate? { get set }
    func startCapture() throws
    func stopCapture()
}

protocol DeepgramServiceProtocol {
    var delegate: DeepgramServiceDelegate? { get set }
    func connect(apiKey: String)
    func disconnect()
    func sendAudio(_ data: Data)
}
```

### MockAudioService.swift

```swift
@testable import Govorilka

class MockAudioService: AudioServiceProtocol {
    weak var delegate: AudioServiceDelegate?
    var startCaptureCalled = false
    var stopCaptureCalled = false

    func startCapture() throws {
        startCaptureCalled = true
    }

    func stopCapture() {
        stopCaptureCalled = true
    }
}
```

## Задача 4: CI/CD

### GitHub Actions

Создай `.github/workflows/test.yml`:

```yaml
name: Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: macos-14
    steps:
    - uses: actions/checkout@v4
    - name: Install xcodegen
      run: brew install xcodegen
    - name: Generate project
      run: xcodegen generate
    - name: Run tests
      run: xcodebuild test -project Govorilka.xcodeproj -scheme Govorilka -destination 'platform=macOS'
```

## Чеклист

После выполнения проверь:

- [ ] Test target добавлен в project.yml
- [ ] GovorilkaTests директория создана
- [ ] Минимум 2 теста работают
- [ ] `xcodegen generate` успешен
- [ ] `xcodebuild test` проходит
