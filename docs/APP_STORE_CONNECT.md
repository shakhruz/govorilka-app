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
   - **Name**: `Govorilka — Voice to Text`
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: `com.govorilka.mobile`
   - **SKU**: `govorilka-mobile-001`
   - **User Access**: Full Access

3. Нажать **Create**

> ⚠️ **Важно**: Primary Language = English для глобального охвата. Русская локализация добавляется отдельно.

### 1.3 Создать macOS приложение

1. **Apps** → **+** → **New App**
2. Заполнить:
   - **Platforms**: macOS
   - **Name**: `Govorilka for Mac`
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: `com.govorilka.app`
   - **SKU**: `govorilka-macos-001`
   - **User Access**: Full Access

3. Нажать **Create**

---

## Часть 2: Настройка iOS приложения

### 2.1 App Information

1. Перейти в **App Information**
2. Заполнить:
   - **Subtitle (EN)**: `Speech to Text with Deepgram AI`
   - **Category**: Productivity
   - **Secondary Category**: Utilities
   - **Content Rights**: Does not contain third-party content
   - **Age Rating**: 4+

### 2.2 Pricing and Availability

1. **Price**: Free
2. **Availability**: All territories (или выбрать конкретные)

### 2.3 App Privacy

1. Перейти в **App Privacy**
2. **Privacy Policy URL**: `https://govorilka.milagpt.com/privacy`
3. **Data Collection**:

   | Data Type | Collected | Linked to User | Tracking |
   |-----------|-----------|----------------|----------|
   | Audio Data | Yes | No | No |

   **Описание**: Audio is streamed to Deepgram for transcription and not stored.

### 2.4 Версия приложения

1. Перейти в **iOS App** → **1.0 Prepare for Submission**
2. Добавить локализации: **English (U.S.)** и **Russian**
3. Заполнить локализации:

#### English (U.S.) — PRIMARY

| Поле | Значение |
|------|----------|
| **Name** | `Govorilka — Voice to Text` |
| **Subtitle** | `Speech Transcription AI` |
| **Promotional Text** | Turn speech into text instantly! Powered by Deepgram AI with $200 free credits. Open-source & privacy-first. |
| **Keywords** | dictation,transcription,speech,recording,notes,voice,typing,memo,audio,whisper,siri |
| **Description** | см. ниже |
| **Support URL** | https://github.com/skylineyoga/govorilka/issues |
| **Marketing URL** | https://govorilka.milagpt.com |

**Description (EN):**
```
Govorilka transforms your voice into text with stunning accuracy using Deepgram's Nova-2 AI.

KEY FEATURES:
• Real-time transcription — see words appear as you speak
• Auto-paste — text goes directly where your cursor is
• Privacy-first — audio is never stored, only streamed
• Smart cleanup — removes filler words automatically
• Pro mode — add screenshots to voice feedback

HOW IT WORKS:
1. Get a free Deepgram API key ($200 credits included)
2. Press the hotkey to start recording
3. Speak naturally — text appears in real-time
4. Release to auto-paste into any app

PERFECT FOR:
• Quick notes and memos
• Drafting emails and messages
• Transcribing meetings and lectures
• Developers giving feedback to AI assistants

OPEN SOURCE:
Govorilka is free and open-source. Build it yourself or support development with a small donation.

github.com/skylineyoga/govorilka
```

---

#### Russian (Русский)

| Поле | Значение |
|------|----------|
| **Name** | `Говорилка — голос в текст` |
| **Subtitle** | `Транскрипция речи ИИ` |
| **Promotional Text** | Превращайте речь в текст мгновенно! Deepgram AI с $200 бесплатных кредитов. Open-source и приватность. |
| **Keywords** | диктовка,распознавание,запись,аудио,заметки,голосовой,ввод,расшифровка,стенография,конспект,лекции |
| **Description** | см. ниже |
| **Support URL** | https://github.com/skylineyoga/govorilka/issues |
| **Marketing URL** | https://govorilka.milagpt.com |

**Description (RU):**
```
Говорилка превращает голос в текст с потрясающей точностью благодаря ИИ Deepgram Nova-2.

ВОЗМОЖНОСТИ:
• Транскрипция в реальном времени — слова появляются пока вы говорите
• Автовставка — текст сразу появляется там, где курсор
• Приватность — аудио не сохраняется, только стримится
• Умная очистка — автоматически убирает слова-паразиты
• Pro режим — добавляйте скриншоты к голосовому фидбэку

КАК РАБОТАЕТ:
1. Получите бесплатный API ключ Deepgram ($200 кредитов)
2. Нажмите горячую клавишу для записи
3. Говорите естественно — текст появляется в реальном времени
4. Отпустите — текст автоматически вставится

ИДЕАЛЬНО ДЛЯ:
• Быстрых заметок
• Написания писем и сообщений
• Расшифровки встреч и лекций
• Разработчиков, дающих фидбэк ИИ-ассистентам

OPEN SOURCE:
Говорилка бесплатна и с открытым исходным кодом. Соберите сами или поддержите разработку небольшим донатом.

github.com/skylineyoga/govorilka
```

### 2.5 Screenshots

📖 **Полный гайд по скриншотам**: [SCREENSHOTS.md](./SCREENSHOTS.md)

**Требуемые размеры iOS:**
- iPhone 6.7" (15 Pro Max): 1290 × 2796 — **обязательно**
- iPhone 6.5" (11 Pro Max): 1284 × 2778 — **обязательно**

**Файлы:**
```
fastlane/screenshots/ru/
  01_recording.png, 02_transcribing.png, 03_result.png,
  04_history.png, 05_pro_mode.png, 06_settings.png

fastlane/screenshots/en-US/
  (аналогично)
```

**Загрузка:**
```bash
cd govorilka-mobile
./fastlane/screenshots/create_screenshots.sh  # Проверить статус
fastlane screenshots                          # Загрузить
```

### 2.6 Build

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

### 2.7 App Review Information

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

1. **Subtitle (EN)**: `Voice to Text from Menu Bar`
2. **Category**: Productivity
3. **Secondary Category**: Utilities

### 3.2 App Privacy

Аналогично iOS:
- **Privacy Policy URL**: `https://govorilka.milagpt.com/privacy`
- Audio Data collected but not linked to user

### 3.3 Версия приложения

#### English (U.S.) — PRIMARY

| Поле | Значение |
|------|----------|
| **Name** | `Govorilka for Mac` |
| **Subtitle** | `Voice to Text Menu Bar App` |
| **Promotional Text** | Lightning-fast voice transcription from your menu bar. Powered by Deepgram AI. Open-source! |
| **Keywords** | dictation,transcription,speech,menubar,hotkey,voice,typing,stenography,recording,whisper |

**Description (EN):**
```
Govorilka is a minimalist menu bar utility that transforms your voice into text using Deepgram's Nova-2 AI.

KEY FEATURES:
• Menu bar app — always one hotkey away
• Global hotkey — Right Cmd or Option+Space
• Real-time transcription — see words as you speak
• Auto-paste — text appears where your cursor is
• Smart cleanup — removes "um", "uh", filler words
• Pro mode — screenshot + voice feedback for AI agents

HOW TO USE:
1. Get free Deepgram API key (deepgram.com — $200 credits)
2. Add key in Settings
3. Press hotkey → speak → release
4. Text auto-pastes into active app

PERMISSIONS:
• Microphone — for audio capture
• Accessibility — for auto-paste (simulates Cmd+V)
• Screen Recording — only for Pro mode screenshots

OPEN SOURCE:
Free forever. Build from source or support with $4.99.
github.com/skylineyoga/govorilka
```

---

#### Russian (Русский)

| Поле | Значение |
|------|----------|
| **Name** | `Говорилка для Mac` |
| **Subtitle** | `Голос в текст из меню-бара` |
| **Promotional Text** | Молниеносная транскрипция голоса из меню-бара. Deepgram AI. Open-source! |
| **Keywords** | диктовка,распознавание,аудио,заметки,горячие,клавиши,стенография,расшифровка,запись,голосовой |

**Description (RU):**
```
Говорилка — минималистичная утилита в меню-баре для превращения голоса в текст с помощью ИИ Deepgram Nova-2.

ВОЗМОЖНОСТИ:
• Приложение в меню-баре — всегда под рукой
• Глобальная горячая клавиша — Right Cmd или Option+Space
• Транскрипция в реальном времени
• Автовставка — текст появляется где курсор
• Умная очистка — убирает «ну», «как бы», «типа»
• Pro режим — скриншот + голосовой фидбэк для ИИ-агентов

КАК ИСПОЛЬЗОВАТЬ:
1. Получите бесплатный ключ Deepgram ($200 кредитов)
2. Добавьте ключ в Настройки
3. Нажмите горячую клавишу → говорите → отпустите
4. Текст автоматически вставится в активное приложение

РАЗРЕШЕНИЯ:
• Микрофон — для записи аудио
• Универсальный доступ — для автовставки (⌘V)
• Запись экрана — только для Pro режима

OPEN SOURCE:
Бесплатно навсегда. Соберите из исходников или поддержите за $4.99.
github.com/skylineyoga/govorilka
```

### 3.4 Screenshots

📖 **Полный гайд по скриншотам**: [SCREENSHOTS.md](./SCREENSHOTS.md)

**Требуемые размеры macOS:**
- Mac: 2880 × 1800 — **обязательно**

**Файлы:**
```
fastlane/screenshots/ru/
  01_menubar.png, 02_dictation.png, 03_hotkeys.png,
  04_history.png, 05_privacy.png

fastlane/screenshots/en-US/
  (аналогично)
```

**Загрузка:**
```bash
cd govorilka
./fastlane/screenshots/create_screenshots.sh  # Проверить статус
fastlane mac screenshots                      # Загрузить
```

### 3.5 Build

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

### 3.6 App Review Information

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
