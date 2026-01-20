<p align="center">
  <img src="docs/icon.png" alt="Говорилка" width="128" height="128">
</p>

<h1 align="center">Говорилка</h1>

<p align="center">
  <strong>Голосовой ввод для macOS</strong><br>
  Минималистичное приложение для транскрибации речи в текст
</p>

<p align="center">
  <a href="https://github.com/shakhruz/govorilka-app/releases/latest">
    <img src="https://img.shields.io/github/v/release/shakhruz/govorilka-app?style=flat-square&label=Версия" alt="Version">
  </a>
  <a href="https://github.com/shakhruz/govorilka-app/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/shakhruz/govorilka-app?style=flat-square&label=Лицензия" alt="License">
  </a>
  <img src="https://img.shields.io/badge/macOS-13.0+-blue?style=flat-square" alt="macOS">
  <img src="https://img.shields.io/badge/Swift-5.9-orange?style=flat-square" alt="Swift">
</p>

<p align="center">
  <a href="#установка">Установка</a> •
  <a href="#использование">Использование</a> •
  <a href="#горячие-клавиши">Горячие клавиши</a> •
  <a href="#настройка">Настройка</a>
</p>

---

## Что это?

**Говорилка** — бесплатное open-source приложение для macOS, которое превращает вашу речь в текст. Живёт в menu bar, не мешает работе, вставляет текст туда, где стоит курсор.

### Для кого?

- Для тех, кто много пишет и хочет диктовать
- Для параноиков, которые не доверяют закрытым решениям
- Для минималистов, которым не нужны 100 функций
- Для разработчиков, работающих с AI-ассистентами

### Почему Говорилка?

| | Говорилка | Платные аналоги |
|---|---|---|
| **Цена** | Бесплатно | $30-50 |
| **Исходный код** | Открыт | Закрыт |
| **Качество распознавания** | Deepgram Nova-2 | Разное |
| **Русский язык** | Отлично | Часто плохо |
| **Сложность** | Минимальная | Перегружены |

---

## Установка

### Скачать готовое приложение

1. Перейдите в [Releases](https://github.com/shakhruz/govorilka-app/releases/latest)
2. Скачайте `Govorilka-v1.0.0.zip`
3. Распакуйте и перетащите в `/Applications`
4. При первом запуске: правый клик → Открыть

### Собрать из исходников

```bash
# Клонировать репозиторий
git clone https://github.com/shakhruz/govorilka-app.git
cd govorilka-app

# Установить xcodegen (если нет)
brew install xcodegen

# Сгенерировать проект и открыть
xcodegen generate
open Govorilka.xcodeproj

# Собрать: ⌘R в Xcode
```

---

## Использование

<p align="center">
  <img src="docs/demo.gif" alt="Демо" width="400">
</p>

1. **Нажмите горячую клавишу** — появится индикатор записи
2. **Говорите** — текст появляется в реальном времени
3. **Нажмите ещё раз** — текст вставится в активное окно
4. **ESC** — отменить запись без сохранения

---

## Горячие клавиши

В настройках можно выбрать один из режимов:

| Режим | Клавиша | Описание |
|-------|---------|----------|
| **⌥ Space** | Option + Пробел | Классическая комбинация |
| **Right ⌘** | Правый Command | Рекомендуется — одно нажатие |
| **2× Right ⌥** | Правый Option×2 | Двойное нажатие |

**Дополнительно:**
- **ESC** — отменить запись

---

## Настройка

### 1. API ключ Deepgram

Говорилка использует [Deepgram](https://deepgram.com) для распознавания речи.

1. Зарегистрируйтесь на [console.deepgram.com](https://console.deepgram.com/signup)
2. Получите **$200 бесплатных кредитов** (без карты!)
3. Создайте API ключ: Settings → API Keys
4. Вставьте ключ в настройках Говорилки

> **$200 хватит на ~775 часов** диктовки. Это много.

### 2. Разрешения macOS

| Разрешение | Зачем | Как включить |
|------------|-------|--------------|
| **Микрофон** | Запись голоса | Автоматический запрос |
| **Accessibility** | Автовставка текста | System Settings → Privacy → Accessibility |

---

## Стоимость

**Говорилка бесплатна.** Вы платите только за API Deepgram:

- **$200 бесплатно** при регистрации
- **$0.0043/минута** после исчерпания (≈26 копеек)
- Никаких подписок, платите только за использование

---

## Архитектура

```
Govorilka/
├── GovorilkaApp.swift           # Точка входа + MenuBarExtra
├── Views/                       # SwiftUI интерфейс
│   ├── MenuBarView.swift        # Главное меню
│   ├── RecordingView.swift      # Индикатор записи
│   ├── SettingsView.swift       # Настройки
│   └── FloatingRecorderWindow.swift  # Плавающее окно
├── ViewModels/
│   └── AppState.swift           # Состояние приложения
├── Services/
│   ├── AudioService.swift       # Захват звука (AVAudioEngine)
│   ├── DeepgramService.swift    # WebSocket к Deepgram
│   ├── HotkeyService.swift      # Горячие клавиши
│   └── PasteService.swift       # Вставка текста
└── Models/
    └── TranscriptEntry.swift    # Запись в истории
```

---

## Приватность

- **Аудио** отправляется напрямую в Deepgram, нигде не сохраняется
- **История** хранится только локально на вашем Mac
- **API ключ** хранится в UserDefaults, не передаётся третьим лицам
- **Исходный код** открыт — можете проверить сами

---

## Разработка

### Требования

- macOS 13.0+
- Xcode 15.0+
- Swift 5.9

### Зависимости

- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) — глобальные хоткеи

### Сборка

```bash
xcodegen generate
xcodebuild -scheme Govorilka -configuration Release build
```

---

## Roadmap

- [ ] Выбор языка распознавания
- [ ] Кастомные промпты для постобработки
- [ ] Интеграция с локальными LLM
- [ ] Экспорт истории

---

## Поддержка

- [Issues](https://github.com/shakhruz/govorilka-app/issues) — баги и предложения
- [Discussions](https://github.com/shakhruz/govorilka-app/discussions) — вопросы

---

## Лицензия

MIT License — делайте что хотите, только не удаляйте копирайт.

---

<p align="center">
  Сделано с ❤️ для русскоязычного сообщества
</p>
