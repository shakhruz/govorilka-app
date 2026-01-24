# /deploy-site - Деплой сайта на Vercel

Деплоит сайт Говорилки (папка `docs/`) на Vercel production (govorilka.app).

Vercel-проект: `milagpt/govorilka`
Домен: `govorilka.app`
Исходники: `docs/` (статический HTML)

## Инструкции

### Шаг 1: Проверка состояния

Выполни параллельно:

```bash
# Незакоммиченные изменения в docs/
git status docs/

# Последний коммит в docs/
git log --oneline -1 -- docs/

# Vercel-линк на месте
cat docs/.vercel/project.json
```

### Шаг 2: Незакоммиченные изменения

Если есть незакоммиченные изменения в `docs/`:

1. Показать diff: `git diff docs/`
2. Спросить пользователя через AskUserQuestion:
   - "Закоммитить и задеплоить"
   - "Задеплоить без коммита"
   - "Отмена"

Если пользователь выбрал коммит:
```bash
git add docs/
git commit -m "feat(website): <краткое описание>"
git push
```

### Шаг 3: Деплой

Деплой из корня репозитория (docs/.vercel уже слинкован на проект govorilka):

```bash
cd /Users/farangissharapova/govorilka/docs && npx vercel deploy --prod
```

Ожидаемый вывод: `Aliased: https://govorilka.app`

### Шаг 4: Верификация

После деплоя проверь сайт:

```bash
curl -sI https://govorilka.app | head -5
```

Убедись что HTTP 200 и сайт доступен.

### Шаг 5: Итоговый отчёт

Покажи пользователю:
- Production URL: https://govorilka.app
- Deployment URL (уникальный для этого деплоя)
- Коммит, который задеплоен

---

## Откат

```bash
cd /Users/farangissharapova/govorilka/docs && npx vercel rollback
```
