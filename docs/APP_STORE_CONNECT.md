# App Store Connect — Руководство по публикации

Пошаговая инструкция для публикации Говорилки в App Store.

## Предварительные требования

- [ ] Apple Developer Account ($99/год)
- [ ] Xcode 15+ установлен
- [ ] fastlane установлен (`brew install fastlane`)

## Часть 1: Создание приложений

### 1.1 Войти в App Store Connect

1. Открыть [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Войти с Apple ID разработчика

### 1.2 Создать iOS приложение

1. **Apps** → **+** → **New App**
2. Заполнить:
   - **Platforms**: iOS
   - **Name**: `Говорилка — голос в текст`
   - **Primary Language**: Russian
   - **Bundle ID**: `com.govorilka.mobile`
   - **SKU**: `govorilka-mobile-001`
   - **User Access**: Full Access

3. Нажать **Create**

### 1.3 Создать macOS приложение

1. **Apps** → **+** → **New App**
2. Заполнить:
   - **Platforms**: macOS
   - **Name**: `Говорилка для Mac`
   - **Primary Language**: Russian
   - **Bundle ID**: `com.govorilka.app`
   - **SKU**: `govorilka-macos-001`
   - **User Access**: Full Access

3. Нажать **Create**

---

## Часть 2: Настройка iOS приложения

### 2.1 App Information

1. Перейти в **App Information**
2. Заполнить:
   - **Subtitle**: `Транскрипция речи Deepgram AI`
   - **Category**: Productivity
   - **Secondary Category**: Utilities
   - **Content Rights**: Does not contain third-party content
   - **Age Rating**: 4+

### 2.2 Pricing and Availability

1. **Price**: Free
2. **Availability**: All territories (или выбрать конкретные)

### 2.3 App Privacy

1. Перейти в **App Privacy**
2. **Privacy Policy URL**: `https://govorilka.app/privacy`
3. **Data Collection**:

   | Data Type | Collected | Linked to User | Tracking |
   |-----------|-----------|----------------|----------|
   | Audio Data | Yes | No | No |

   **Описание**: Audio is streamed to Deepgram for transcription and not stored.

### 2.4 Версия приложения

1. Перейти в **iOS App** → **1.0 Prepare for Submission**
2. Заполнить локализации:

#### Русский (ru)
```
Screenshots: [загрузить из fastlane/screenshots/ru/]
Promotional Text: Превращайте речь в текст мгновенно! $200 бесплатных кредитов при регистрации в Deepgram.
Description: [из fastlane/metadata/ru/description.txt]
Keywords: диктовка,распознавание,запись,аудио,заметки,голосовой,ввод,расшифровка,стенография,конспект,лекции
Support URL: https://github.com/shakhruz/govorilka-app/issues
Marketing URL: https://govorilka.app
```

#### English (en-US)
```
Screenshots: [загрузить из fastlane/screenshots/en-US/]
Promotional Text: Turn speech into text instantly! $200 free credits when you sign up for Deepgram.
Description: [из fastlane/metadata/en-US/description.txt]
Keywords: dictation,transcription,speech,recording,notes,voice,typing,stenography,lecture,memo,audio
Support URL: https://github.com/shakhruz/govorilka-app/issues
Marketing URL: https://govorilka.app
```

### 2.5 Build

1. Загрузить билд через EAS:
   ```bash
   cd govorilka-mobile
   eas build --platform ios --profile production
   eas submit --platform ios
   ```

2. Или через Xcode:
   - Product → Archive
   - Distribute App → App Store Connect

3. Выбрать билд в App Store Connect

### 2.6 App Review Information

```
First Name: [Ваше имя]
Last Name: [Ваша фамилия]
Phone: [Телефон]
Email: [Email]

Demo Account: Not required
Notes: This app requires a Deepgram API key for functionality.
       Users can get a free key at deepgram.com with $200 credits.
       The app works offline for settings, but requires internet for transcription.
```

---

## Часть 3: Настройка macOS приложения

### 3.1 App Information

1. **Subtitle**: `Голос в текст из меню-бара`
2. **Category**: Productivity
3. **Secondary Category**: Utilities

### 3.2 App Privacy

Аналогично iOS:
- **Privacy Policy URL**: `https://govorilka.app/privacy`
- Audio Data collected but not linked to user

### 3.3 Версия приложения

Заполнить локализации аналогично iOS, но с macOS текстами:
- `fastlane/metadata/ru/` и `fastlane/metadata/en-US/`

### 3.4 Build

```bash
cd /path/to/govorilka

# Archive
xcodebuild -project Govorilka.xcodeproj \
  -scheme Govorilka \
  -configuration Release \
  -archivePath build/Govorilka.xcarchive \
  archive

# Export for App Store
xcodebuild -exportArchive \
  -archivePath build/Govorilka.xcarchive \
  -exportPath build/AppStore \
  -exportOptionsPlist ExportOptions.plist
```

Или через Xcode:
1. Product → Archive
2. Distribute App → App Store Connect

### 3.5 App Review Information

```
Notes: This is a menu bar utility for voice-to-text transcription.
       Requires Deepgram API key (free at deepgram.com).

       Permissions required:
       - Microphone: for audio capture
       - Accessibility: for auto-paste feature (simulates Cmd+V)
       - Screen Recording: only for Pro mode screenshots (optional)

       To test:
       1. Launch app (appears in menu bar)
       2. Enter API key in Settings
       3. Press hotkey (Right Cmd or Option+Space) to record
       4. Speak and release to transcribe
```

---

## Часть 4: Загрузка метаданных через Fastlane

### 4.1 Настройка

```bash
# Установить переменные
export APPLE_ID="your@email.com"
export TEAM_ID="XXXXXXXXXX"
export ITC_TEAM_ID="XXXXXXXXXX"

# Или создать .env файл
echo "APPLE_ID=your@email.com" >> .env
echo "TEAM_ID=XXXXXXXXXX" >> .env
```

### 4.2 Загрузка iOS

```bash
cd govorilka-mobile
fastlane metadata    # Только метаданные
fastlane screenshots # Только скриншоты
fastlane upload      # Всё вместе
```

### 4.3 Загрузка macOS

```bash
cd govorilka
fastlane mac metadata
fastlane mac screenshots
fastlane mac upload
```

---

## Часть 5: Отправка на Review

### 5.1 Чеклист перед отправкой

- [ ] Все метаданные заполнены (ru + en-US)
- [ ] Скриншоты загружены (все размеры)
- [ ] Иконка 1024x1024 загружена
- [ ] Privacy Policy URL работает
- [ ] Build загружен и выбран
- [ ] App Review Information заполнена
- [ ] Age Rating настроен
- [ ] Pricing установлен (Free)

### 5.2 Отправка

1. Перейти в версию приложения
2. Проверить все секции (зелёные галочки)
3. Нажать **Add for Review**
4. Ответить на вопросы:
   - Export Compliance: No (если нет шифрования)
   - Content Rights: Yes (владеете контентом)
   - Advertising Identifier: No
5. Нажать **Submit to App Review**

### 5.3 После отправки

- Review занимает 24-48 часов (обычно)
- Статусы: Waiting for Review → In Review → Ready for Sale
- При отклонении — исправить и resubmit

---

## Полезные ссылки

- [App Store Connect](https://appstoreconnect.apple.com)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Fastlane Deliver](https://docs.fastlane.tools/actions/deliver/)
- [Screenshot Specifications](https://help.apple.com/app-store-connect/#/devd274dd925)

---

## Troubleshooting

### "Bundle ID already exists"
Bundle ID уже зарегистрирован. Используйте другой или удалите старый в Developer Portal.

### "Missing compliance"
Добавьте Export Compliance в Info.plist:
```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

### "Invalid binary"
Проверьте, что:
- Подпись правильная (Distribution certificate)
- Provisioning profile актуален
- Bundle ID совпадает

### "Metadata rejected"
Частые причины:
- Скриншоты не соответствуют функционалу
- Упоминание цен без "начиная от"
- Ссылки на другие платформы
