# ASO (App Store Optimization) — Говорилка

Документация по оптимизации листингов для App Store.

## Структура файлов

```
govorilka/
├── fastlane/                    # macOS приложение
│   ├── Appfile
│   ├── Fastfile
│   ├── Deliverfile
│   ├── metadata/
│   │   ├── copyright.txt
│   │   ├── primary_category.txt
│   │   ├── secondary_category.txt
│   │   ├── ru/
│   │   │   ├── name.txt
│   │   │   ├── subtitle.txt
│   │   │   ├── keywords.txt
│   │   │   ├── description.txt
│   │   │   ├── promotional_text.txt
│   │   │   ├── privacy_url.txt
│   │   │   ├── support_url.txt
│   │   │   └── marketing_url.txt
│   │   └── en-US/
│   │       └── ... (аналогично)
│   └── screenshots/
│       ├── SCREENSHOTS_GUIDE.md
│       ├── ru/
│       └── en-US/
│
└── govorilka-mobile/
    ├── fastlane/                # iOS приложение
    │   ├── Appfile
    │   ├── Fastfile
    │   ├── Deliverfile
    │   └── metadata/
    │       └── ... (аналогично)
    └── store.config.json        # EAS Submit конфигурация
```

## Использование

### Предварительные требования

```bash
# Установка fastlane
brew install fastlane

# Переменные окружения
export APPLE_ID="your@email.com"
export TEAM_ID="XXXXXXXXXX"
export ITC_TEAM_ID="XXXXXXXXXX"  # если отличается
```

### Загрузка метаданных

**iOS приложение:**
```bash
cd govorilka-mobile
fastlane metadata
```

**macOS приложение:**
```bash
cd govorilka
fastlane mac metadata
```

### Загрузка скриншотов

```bash
# Сначала добавьте скриншоты в соответствующие папки
# Затем:
fastlane screenshots
```

### Полная загрузка

```bash
fastlane upload  # Метаданные + скриншоты
```

## ASO Стратегия

### Лимиты полей

| Поле | Лимит | Индексируется |
|------|-------|---------------|
| Name | 30 символов | ✅ |
| Subtitle | 30 символов | ✅ |
| Keywords | 100 символов | ✅ |
| Description | 4000 символов | ❌ |
| Promotional Text | 170 символов | ❌ |

### Правила оптимизации

1. **Не дублировать слова** между Name, Subtitle и Keywords
2. **Keywords без пробелов** после запятых
3. **Избегать стоп-слов**: "app", "the", "и", "для"
4. **Long-tail запросы** работают лучше

### Текущие keywords

**iOS (ru):**
```
диктовка,распознавание,запись,аудио,заметки,голосовой,ввод,расшифровка,стенография,конспект,лекции
```

**macOS (ru):**
```
диктовка,распознавание,аудио,заметки,горячие,клавиши,стенография,расшифровка,запись,голосовой,ввод
```

### Покрытие поисковых запросов

Комбинации, которые покрываются:
- "голосовой ввод"
- "запись голоса"
- "расшифровка аудио"
- "диктовка текста"
- "стенография лекций"
- "голосовые заметки"
- "транскрипция речи" (в Name/Subtitle)

## Скриншоты

### Требования iOS

| Устройство | Разрешение | Обязательно |
|------------|-----------|-------------|
| 6.7" (iPhone 15 Pro Max) | 1290 x 2796 | ✅ |
| 6.5" (iPhone 11 Pro Max) | 1284 x 2778 | ✅ |
| 5.5" (iPhone 8 Plus) | 1242 x 2208 | Опционально |

### Требования macOS

| Дисплей | Разрешение | Обязательно |
|---------|-----------|-------------|
| Mac | 2880 x 1800 | ✅ |

### Подробные гайды

- iOS: `govorilka-mobile/fastlane/screenshots/SCREENSHOTS_GUIDE.md`
- macOS: `fastlane/screenshots/SCREENSHOTS_GUIDE.md`

## Чеклист перед публикацией

### App Store Connect

- [ ] Создать приложение в App Store Connect
- [ ] Заполнить App Information
- [ ] Добавить App Privacy (Data Collection)
- [ ] Загрузить иконку 1024x1024

### Метаданные

- [ ] Проверить длину всех текстов
- [ ] Загрузить через fastlane
- [ ] Проверить в App Store Connect

### Скриншоты

- [ ] Создать скриншоты всех экранов
- [ ] Добавить текстовые оверлеи
- [ ] Проверить разрешения
- [ ] Загрузить через fastlane

### Билд

- [ ] Загрузить билд (EAS для iOS, Xcode для macOS)
- [ ] Выбрать билд в App Store Connect
- [ ] Заполнить What's New

### Review

- [ ] Добавить Review Information
- [ ] Указать демо-данные (если нужно)
- [ ] Отправить на Review

## Локализация

### Приоритетные языки

1. **ru** — основной рынок
2. **en-US** — международный охват

### Добавление нового языка

1. Создать папку `metadata/{locale}/`
2. Скопировать файлы из `ru/`
3. Перевести все тексты
4. Создать локализованные скриншоты

## Ссылки

- [Fastlane Deliver](https://docs.fastlane.tools/actions/deliver/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Apple Screenshot Specs](https://help.apple.com/app-store-connect/#/devd274dd925)
