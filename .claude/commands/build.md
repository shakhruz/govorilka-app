# /build - Сборка и запуск локального билда

Этот скилл собирает приложение, копирует в ~/Applications и запускает. Гарантирует, что запускается именно последний билд.

## Инструкции

### Шаг 1: Проверить текущую версию

```bash
# Версия в project.yml
echo "📋 Версия в project.yml:"
grep "MARKETING_VERSION:" project.yml | sed 's/.*"\(.*\)"/\1/'
grep "CURRENT_PROJECT_VERSION:" project.yml | sed 's/.*"\(.*\)"/\1/'
```

### Шаг 2: Закрыть запущенное приложение

```bash
# Завершить Govorilka если запущена
pkill -x Govorilka 2>/dev/null && echo "⏹️  Govorilka остановлена" || echo "ℹ️  Govorilka не была запущена"
sleep 0.5
```

### Шаг 3: Очистить старый билд (опционально)

Если версия не обновляется, нужно очистить DerivedData:

```bash
# Очистить только для Govorilka (быстрее чем полная очистка)
rm -rf ~/Library/Developer/Xcode/DerivedData/Govorilka-*
echo "🧹 DerivedData очищена"
```

### Шаг 4: Регенерировать Xcode проект

```bash
xcodegen generate
echo "⚙️  Xcode проект сгенерирован"
```

### Шаг 5: Собрать приложение

```bash
xcodebuild -project Govorilka.xcodeproj -scheme Govorilka -configuration Debug build 2>&1 | grep -E "(error:|BUILD)"
```

Если сборка успешна, продолжить. Если есть ошибки - показать их пользователю.

### Шаг 6: Скопировать в ~/Applications

**ВАЖНО**: Использовать флаги для полной перезаписи!

```bash
# Удалить старое приложение и скопировать новое
rm -rf ~/Applications/Govorilka.app
cp -R ~/Library/Developer/Xcode/DerivedData/Govorilka-*/Build/Products/Debug/Govorilka.app ~/Applications/
echo "📦 Приложение скопировано в ~/Applications"
```

### Шаг 7: Проверить версию установленного приложения

```bash
# Проверить что версия правильная
VERSION=$(defaults read ~/Applications/Govorilka.app/Contents/Info.plist CFBundleShortVersionString)
BUILD=$(defaults read ~/Applications/Govorilka.app/Contents/Info.plist CFBundleVersion)
echo "✅ Установлена версия: $VERSION ($BUILD)"
```

### Шаг 8: Запустить приложение

```bash
open ~/Applications/Govorilka.app
echo "🚀 Govorilka запущена"
```

### Шаг 9: Итоговый отчёт

Показать пользователю:

```
✅ Билд успешен!

📦 Версия: X.Y.Z (build N)
📍 Путь: ~/Applications/Govorilka.app
🚀 Приложение запущено

Проверь версию в приложении: внизу окна "Говорилка vX.Y.Z (N)"
```

---

## Быстрая команда (одной строкой)

Для быстрой пересборки без очистки:

```bash
pkill -x Govorilka; sleep 0.3 && xcodegen generate && xcodebuild -project Govorilka.xcodeproj -scheme Govorilka -configuration Debug build 2>&1 | grep -E "(error:|BUILD)" && rm -rf ~/Applications/Govorilka.app && cp -R ~/Library/Developer/Xcode/DerivedData/Govorilka-*/Build/Products/Debug/Govorilka.app ~/Applications/ && open ~/Applications/Govorilka.app
```

## С полной очисткой (если версия не обновляется)

```bash
pkill -x Govorilka; rm -rf ~/Library/Developer/Xcode/DerivedData/Govorilka-* && xcodegen generate && xcodebuild -project Govorilka.xcodeproj -scheme Govorilka -configuration Debug build 2>&1 | grep -E "(error:|BUILD)" && rm -rf ~/Applications/Govorilka.app && cp -R ~/Library/Developer/Xcode/DerivedData/Govorilka-*/Build/Products/Debug/Govorilka.app ~/Applications/ && open ~/Applications/Govorilka.app
```

---

## Troubleshooting

### Версия не обновляется
1. Проверь `Govorilka/Info.plist` - должны быть переменные `$(MARKETING_VERSION)` и `$(CURRENT_PROJECT_VERSION)`
2. Очисти DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData/Govorilka-*`
3. Пересобери с нуля

### Приложение не запускается
1. Проверь права: `codesign -vv ~/Applications/Govorilka.app`
2. Удали карантин: `xattr -cr ~/Applications/Govorilka.app`

### Тесты перед билдом
```bash
xcodebuild -project Govorilka.xcodeproj -scheme GovorilkaTests -destination 'platform=macOS' test 2>&1 | grep -E "(Executed|passed|failed)"
```
