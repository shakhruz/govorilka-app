---
description: Аудит безопасности приложения Govorilka — API ключи, сетевая безопасность, хранение данных
---

# Команда: Security Audit

Выполни аудит безопасности macOS-приложения Govorilka.

## Шаги аудита

### 1. Хранение секретов

Найди где хранится API ключ Deepgram:
- Поиск по `apiKey`, `APIKey`, `deepgramApiKey`
- Проверь `StorageService.swift`
- Проверь `@AppStorage` и `UserDefaults`

**CRITICAL если**: ключ в UserDefaults (читается любым процессом)
**OK если**: ключ в Keychain

### 2. Сетевая безопасность

Проверь `DeepgramService.swift`:
- WebSocket URL должен быть `wss://` (не `ws://`)
- Как обрабатываются SSL ошибки?
- Есть ли certificate pinning?

### 3. Данные пользователя

- Как хранится история транскрипций?
- Есть ли скриншоты (Pro режим)? Шифруются ли?
- Удаляются ли временные файлы?

### 4. Permissions

Проверь `Info.plist`:
- `NSMicrophoneUsageDescription` — должно быть
- `NSScreenCaptureUsageDescription` — если есть скриншоты

Проверь `Govorilka.entitlements`:
- Какие права запрошены?
- Sandboxing включён?

## Формат отчёта

```markdown
## Security Audit Report

### CRITICAL
- [Описание проблемы] → [Рекомендация]

### HIGH
- ...

### MEDIUM
- ...

### LOW
- ...

### Recommendations
1. [ ] Действие 1
2. [ ] Действие 2
```

## Известные проблемы

1. **API ключ в UserDefaults** — миграция в Keychain
2. **Отсутствие certificate pinning** — добавить URLSession delegate
3. **Скриншоты без шифрования** — AES-256 или удаление после использования
