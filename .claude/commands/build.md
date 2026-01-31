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

## Release билд с нотаризацией (для распространения)

### Шаг 1: Собрать Release без отладочных entitlements

```bash
xcodebuild -project Govorilka.xcodeproj -scheme Govorilka -configuration Release CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO clean build 2>&1 | grep -E "(error:|BUILD)"
```

### Шаг 2: Подписать с Developer ID и timestamp

```bash
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/Govorilka-*/Build/Products/Release -name "Govorilka.app" -type d | head -1)
codesign --force --options runtime --timestamp --sign "Developer ID Application: Shakhruz Ashirov (TZY7G965L4)" "$APP_PATH"
```

### Шаг 3: Создать и подписать DMG

```bash
VERSION=$(grep "MARKETING_VERSION:" project.yml | sed 's/.*"\(.*\)"/\1/')
DMG_PATH="Govorilka-${VERSION}.dmg"
rm -f "$DMG_PATH"
hdiutil create -volname "Govorilka" -srcfolder "$APP_PATH" -ov -format UDZO "$DMG_PATH"
codesign --force --timestamp --sign "Developer ID Application: Shakhruz Ashirov (TZY7G965L4)" "$DMG_PATH"
```

### Шаг 4: Нотаризовать

```bash
xcrun notarytool submit "$DMG_PATH" --keychain-profile "notarytool" --wait
```

### Шаг 5: Staple нотаризацию

```bash
xcrun stapler staple "$DMG_PATH"
```

### Шаг 6: Проверить

```bash
spctl -a -vvv -t install "$DMG_PATH"
# Должно показать: source=Notarized Developer ID
```

### Быстрая команда Release + Нотаризация

```bash
VERSION=$(grep "MARKETING_VERSION:" project.yml | sed 's/.*"\(.*\)"/\1/') && \
xcodebuild -project Govorilka.xcodeproj -scheme Govorilka -configuration Release CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO clean build 2>&1 | grep BUILD && \
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/Govorilka-*/Build/Products/Release -name "Govorilka.app" -type d | head -1) && \
codesign --force --options runtime --timestamp --sign "Developer ID Application: Shakhruz Ashirov (TZY7G965L4)" "$APP_PATH" && \
rm -f "Govorilka-${VERSION}.dmg" && \
hdiutil create -volname "Govorilka" -srcfolder "$APP_PATH" -ov -format UDZO "Govorilka-${VERSION}.dmg" && \
codesign --force --timestamp --sign "Developer ID Application: Shakhruz Ashirov (TZY7G965L4)" "Govorilka-${VERSION}.dmg" && \
xcrun notarytool submit "Govorilka-${VERSION}.dmg" --keychain-profile "notarytool" --wait && \
xcrun stapler staple "Govorilka-${VERSION}.dmg" && \
echo "✅ Govorilka-${VERSION}.dmg готов к распространению!"
```

---

## Настройка нотаризации (один раз)

Для сохранения credentials:

```bash
xcrun notarytool store-credentials "notarytool" \
  --apple-id "shakhruz.ashirov@ya.ru" \
  --team-id "TZY7G965L4" \
  --password "APP_SPECIFIC_PASSWORD"
```

App-specific password создаётся на [appleid.apple.com](https://appleid.apple.com/account/manage) → Sign-In and Security → App-Specific Passwords.

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

### Нотаризация не проходит

**"The signature does not include a secure timestamp"**
- Добавь `--timestamp` при подписи

**"The executable requests the com.apple.security.get-task-allow entitlement"**
- Собери с `CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO`

**"Invalid credentials" (401)**
- Проверь Apple ID и Team ID
- Создай новый app-specific password

**Проверить логи нотаризации:**
```bash
xcrun notarytool log SUBMISSION_ID --keychain-profile "notarytool"
```
