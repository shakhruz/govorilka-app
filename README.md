# Говорилка

Бесплатная минималистичная утилита для macOS, позволяющая наговаривать тексты голосом и получать транскрипцию через Deepgram API.

## Возможности

- **Глобальный хоткей** (⌥+Space по умолчанию) — старт/стоп записи из любого приложения
- **Real-time транскрибация** через Deepgram Nova-2
- **Автокопирование** в буфер обмена
- **Автовставка** в активное окно (опционально)
- **История записей** (последние 50)
- **Поддержка русского и английского** языков (автоопределение)

## Системные требования

- macOS 13.0 (Ventura) или новее
- Интернет-соединение
- Аккаунт Deepgram (бесплатная регистрация)

## Установка

### Через Xcode

1. Клонируйте репозиторий:
```bash
git clone https://github.com/skylineyoga/govorilka.git
cd govorilka
```

2. Установите xcodegen (если не установлен):
```bash
brew install xcodegen
```

3. Сгенерируйте Xcode проект:
```bash
xcodegen generate
```

4. Откройте проект:
```bash
open Govorilka.xcodeproj
```

5. Соберите и запустите (⌘R)

### Ручная настройка (без xcodegen)

1. Создайте новый macOS App проект в Xcode
2. Выберите SwiftUI и macOS 13.0+
3. Скопируйте содержимое папки `Govorilka/` в проект
4. Добавьте Swift Package: `https://github.com/sindresorhus/KeyboardShortcuts`
5. Настройте Info.plist и Entitlements согласно файлам в репозитории

## Настройка

### 1. Получите API ключ Deepgram

1. Зарегистрируйтесь на [console.deepgram.com](https://console.deepgram.com/signup)
2. Получите **$200 бесплатных кредитов** (без привязки карты)
3. Создайте API ключ в разделе Settings → API Keys

### 2. Введите ключ в приложении

1. Запустите Говорилку
2. Кликните на иконку микрофона в menu bar
3. Перейдите на вкладку "Настройки"
4. Введите API ключ и нажмите "Сохранить"

### 3. Настройте автовставку (опционально)

Для автоматической вставки текста нужен доступ Accessibility:

1. Включите "Автоматически вставлять текст" в настройках
2. Нажмите "Настроить"
3. В System Settings → Privacy & Security → Accessibility добавьте Говорилку

## Использование

1. **Нажмите хоткей** (⌥+Space) или кнопку в menu bar
2. **Говорите** — текст появляется в реальном времени
3. **Нажмите хоткей снова** для остановки
4. **Текст автоматически** скопирован в буфер (и вставлен, если включено)

## Стоимость

Говорилка бесплатна. Вы платите только за использование Deepgram API:

| Тариф | Стоимость | Примечание |
|-------|-----------|------------|
| Бесплатно | $200 кредитов | При регистрации |
| Nova-2 | $0.0043/минута | ~775 часов на $200 |
| Pay-as-you-go | От $0.0043/мин | После исчерпания кредитов |

## Архитектура

```
Govorilka/
├── GovorilkaApp.swift          # Entry point + MenuBarExtra
├── Info.plist                   # Permissions
├── Govorilka.entitlements       # Sandbox config
│
├── Views/
│   ├── MenuBarView.swift        # Main popover
│   ├── RecordingView.swift      # Recording indicator
│   ├── HistoryView.swift        # History list
│   └── SettingsView.swift       # Settings
│
├── ViewModels/
│   └── AppState.swift           # State management
│
├── Services/
│   ├── AudioService.swift       # AVAudioEngine
│   ├── DeepgramService.swift    # WebSocket API
│   ├── PasteService.swift       # Clipboard + ⌘V
│   └── StorageService.swift     # UserDefaults
│
├── Models/
│   └── TranscriptEntry.swift    # History entry
│
└── Resources/
    └── Assets.xcassets          # Icons
```

## Зависимости

- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) — глобальные хоткеи

## Privacy

- **Микрофон**: Аудио отправляется напрямую в Deepgram API
- **Данные**: История хранится локально в UserDefaults
- **API ключ**: Хранится локально, не передаётся третьим лицам

## Troubleshooting

### "Доступ к микрофону запрещён"

System Settings → Privacy & Security → Microphone → Включите Говорилку

### "API ключ Deepgram не настроен"

Добавьте ключ в Настройках приложения

### Автовставка не работает

1. Убедитесь что функция включена в настройках
2. Добавьте Говорилку в System Settings → Privacy & Security → Accessibility

### WebSocket ошибка

- Проверьте интернет-соединение
- Проверьте правильность API ключа
- Проверьте баланс на console.deepgram.com

## Сравнение с VoiceInk

| Аспект | VoiceInk | Говорилка |
|--------|----------|-----------|
| Цена | $39.99 | Бесплатно |
| Транскрипция | Локальная | Cloud (Deepgram) |
| Offline | Да | Нет |
| Языки | 100+ | Русский + English |
| Функционал | Расширенный | Минимальный |

## License

MIT License

## Credits

- [Deepgram](https://deepgram.com) — Speech-to-Text API
- [Sindre Sorhus](https://github.com/sindresorhus) — KeyboardShortcuts

---

Made with ❤️ by [Skyline Yoga](https://skylineyoga.online)
