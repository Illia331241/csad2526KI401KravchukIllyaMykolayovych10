---
description: "Створити кросплатформний GitHub Actions workflow за правилами skill github-actions."
agent: build-engineer
---

# Create Actions

## Передумови

- `ci.sh` існує в корені проєкту.
- `ci.bat` існує в корені проєкту.
- Перед початком перевір існування та вміст обох скриптів.
- `ci.sh` має виконуваний біт, встановлений через
  `git update-index --chmod=+x ci.sh`.
- Skill має бути доступний за шляхом
  `.github/skills/github-actions/SKILL.md`.

Якщо будь-яка передумова не виконана, не створюй неповний workflow і перейди
до розділу «Повідомлення про помилку».

## Дії

1. Прочитай і виконай інструкції зі skill
   `.github/skills/github-actions/SKILL.md`.
2. Передай skill наявні скрипти:

   ```text
   ci.sh
   ci.bat
   ```

3. Створи або перевір `.github/workflows/ci.yml` відповідно до skill.
4. Переконайся, що workflow має тригери `push` і `pull_request` для
   `develop` та `master`.
5. Переконайся, що workflow використовує одну job із matrix для Ubuntu,
   Windows і macOS та `fail-fast: false`.
6. Переконайся, що Linux/macOS запускають лише `./ci.sh` через `bash`, а
   Windows запускає лише `ci.bat` через `cmd`.
7. Перед завершенням покажи diff і список змінених файлів.

## Очікувані файли

Після успішного виконання має існувати:

- `.github/workflows/ci.yml` з одним кросплатформним workflow;
- matrix з `ubuntu-latest`, `windows-latest` і `macos-latest`;
- кроком checkout;
- запуском `./ci.sh` на Linux/macOS;
- запуском `ci.bat` на Windows;
- завантаженням `dist/` через `actions/upload-artifact@v4` з унікальним
  іменем для кожної ОС.

Не створюй додаткові workflow, jobs або секрети.

## Команди перевірки

Перевір YAML одним із доступних способів:

```text
python -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))"
```

або:

```text
actionlint .github/workflows/ci.yml
```

Також перевір:

- у файлі є `ubuntu-latest`, `windows-latest` і `macos-latest`;
- є тригери `push` і `pull_request` для `develop` та `master`;
- є `fail-fast: false`;
- є `actions/checkout@v4` і `actions/upload-artifact@v4`;
- артефакт використовує `dist/`, унікальне ім'я
  `hello-${{ matrix.os }}` та `if-no-files-found: error`;
- значення `run` містять лише `./ci.sh` або `ci.bat`;
- у значеннях `run` немає команд `cargo` чи `rustc`;
- `ci.sh` і `ci.bat` справді існують, а `ci.sh` має виконуваний біт.

## Повідомлення про помилку

- Якщо `ci.sh` або `ci.bat` відсутній, покажи відсутній шлях і зупинись.
- Якщо `ci.sh` не має виконуваного біта, повідом про це та вкажи команду
  `git update-index --chmod=+x ci.sh`; не обходь проблему іншою командою.
- Якщо skill `.github/skills/github-actions/SKILL.md` недоступний, покажи
  шлях і точну причину, після чого зупинись.
- Якщо YAML невалідний або відсутня будь-яка ОС, покажи конкретну помилку і
  не вважай workflow готовим.
- Якщо наявний `ci.yml` має конфліктний вміст, не перезаписуй його
  автоматично; покажи відмінності та зупинись.
- Не приховуй помилки й не додавай обхідні кроки.

## Ідемпотентність

- Перед створенням або зміною `.github/workflows/ci.yml` перевір його
  існування та вміст.
- Не перезаписуй наявний workflow без окремого рішення.
- Повторний запуск не повинен дублювати triggers, jobs, matrix або steps.
- Якщо workflow уже відповідає вимогам skill, залиш його без змін.
- Не змінюй `ci.sh`, `ci.bat` або інші файли поза областю цього prompt.
- Не видаляй файли, кроки чи наявні правила конфігурації.
