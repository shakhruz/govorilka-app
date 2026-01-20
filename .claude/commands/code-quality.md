---
description: Анализ качества кода Govorilka — стиль, дублирование, сложность, потенциальные баги
---

# Команда: Code Quality

Проанализируй качество кода macOS-приложения Govorilka.

## Области анализа

### 1. Стиль и консистентность

**Проверь**:
- Единый стиль именования (camelCase для переменных, PascalCase для типов)
- Организация кода (MARK: comments, extensions)
- SwiftLint конфигурация (`.swiftlint.yml`)

**Поиск**:
```bash
# Найти все MARK комментарии
grep -r "// MARK:" --include="*.swift"

# Проверить наличие SwiftLint
ls .swiftlint.yml
```

### 2. Дублирование кода

**Типичные проблемы**:
- Цвета темы дублируются в разных view
- Magic numbers вместо констант
- Одинаковая логика в разных местах

**Рекомендация**:
```swift
// Создать Theme.swift
enum Theme {
    static let primaryColor = Color.blue
    static let backgroundColor = Color(.windowBackgroundColor)
    static let cornerRadius: CGFloat = 8
}
```

### 3. Сложность кода

**Метрики**:
- Длинные методы (>50 строк) — разбить
- Длинные файлы (>300 строк) — декомпозиция
- Глубокая вложенность (>3 уровня) — early return

**Поиск длинных файлов**:
```bash
wc -l Govorilka/**/*.swift | sort -rn | head -10
```

**Известно**: AppState.swift — 594 строки (God Object)

### 4. Потенциальные баги

**Поиск**:
```bash
# Force unwrap
grep -r "!" --include="*.swift" | grep -v "!="

# TODO/FIXME
grep -rE "TODO|FIXME|HACK|XXX" --include="*.swift"

# Неиспользуемые переменные (компилятор покажет warning)
```

**Проверь**:
- Force unwrap (`!`) без guard/if let
- Retain cycles в closures (нет `[weak self]`)
- Неявные optional (`implicitly unwrapped`)

### 5. SwiftUI Best Practices

**Проверь**:
- Используется `@StateObject` для owner, `@ObservedObject` для inject
- View body не слишком большой
- Extracted subviews для сложных layouts

## Формат отчёта

```markdown
## Code Quality Report

### Metrics
| Metric | Value | Status |
|--------|-------|--------|
| Total files | X | - |
| Total lines | Y | - |
| Longest file | AppState.swift (594) | ⚠️ |
| Force unwraps | Z | - |

### Issues

#### Style
- [ ] Нет SwiftLint конфигурации
- [ ] Inconsistent naming в X

#### Duplication
- [ ] Цвета темы дублируются
- [ ] Magic numbers в views

#### Complexity
- [ ] AppState.swift слишком большой
- [ ] Method X в файле Y > 50 строк

#### Potential Bugs
- [ ] Force unwrap в строке X файла Y
- [ ] Missing [weak self] в Z

### Recommendations
1. [ ] Добавить SwiftLint
2. [ ] Создать Theme.swift для цветов
3. [ ] Вынести константы
4. [ ] Разбить AppState
```

## SwiftLint Configuration

Создай `.swiftlint.yml`:

```yaml
disabled_rules:
  - trailing_whitespace

opt_in_rules:
  - empty_count
  - force_unwrapping
  - implicitly_unwrapped_optional

excluded:
  - Pods
  - .build

line_length:
  warning: 120
  error: 150

file_length:
  warning: 400
  error: 600

function_body_length:
  warning: 40
  error: 60

type_body_length:
  warning: 300
  error: 500
```

## Чеклист качества

- [ ] Нет force unwrap без обоснования
- [ ] Нет magic numbers
- [ ] Нет дублирования кода
- [ ] Файлы < 400 строк
- [ ] Методы < 50 строк
- [ ] [weak self] в closures
- [ ] SwiftLint настроен
