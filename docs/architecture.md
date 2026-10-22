# Архітектура AI-агента

## 1. Які проблеми вирішує агент

AI-агент `build-engineer` автоматизує підготовку мінімального
кросплатформного Rust/Cargo-проєкту Hello World. Він вирішує такі проблеми:

- створення однакової структури Rust-проєкту без ручного дублювання файлів;
- налаштування бібліотеки, виконуваного файла та базового unit-тесту;
- генерація release-збірки й копії виконуваного файла в `dist/`;
- підготовка однакових CI-скриптів для Linux, macOS і Windows;
- створення GitHub Actions workflow з matrix для трьох операційних систем;
- ідемпотентне повторне виконання без дублювання секцій і кроків;
- перевірка структури, збірки, тестів, артефактів і Git-ігнорування;
- прозоре повідомлення про помилки із зупинкою невдалого процесу.

## 2. Skills і їхня відповідальність

Агент використовує три skills:

| Skill | Відповідальність |
|---|---|
| `project-scaffold` | Створює початкову структуру Rust-проєкту: `src/lib.rs`, `src/main.rs`, `tests/`, `docs/` і `README.md`, якщо його немає. |
| `build-and-test` | Налаштовує `Cargo.toml`, unit-тест, генерує `Cargo.lock`, створює `ci.sh` і `ci.bat`, а також перевіряє збірку й тести. |
| `github-actions` | Створює або перевіряє `.github/workflows/ci.yml` для Linux, Windows і macOS та завантаження `dist/` як артефакту. |

## 3. Commands, доступні користувачу

| Command | Призначення |
|---|---|
| `/git-init` | Перевіряє Git-репозиторій і створює або доповнює `.gitignore` без дублів. |
| `/create-project` | Виконує `project-scaffold` для `language=Rust`, `project_name=hello`. |
| `/create-build` | Виконує `build-and-test`, створює Cargo-конфігурацію, тест і CI-скрипти. |
| `/create-actions` | Виконує `github-actions` і створює кросплатформний workflow. |
| `/check` | Виконує read-only перевірку файлів, збірки, тестів, workflow та Git-ігнорування. |
| `/init` | Послідовно запускає всі перелічені етапи та завершує їх командою `/check`. |

## 4. Передавання даних між етапами

Процес проходить через послідовний ланцюжок:

```text
project_name
    -> src/
    -> Cargo.toml
    -> ci.sh / ci.bat
    -> ci.yml
```

1. `project_name=hello` визначає назву проєкту та очікуваний binary `hello`.
2. `project-scaffold` створює `src/`: бібліотеку `src/lib.rs` з функцією
   `add` і `src/main.rs`, який використовує `hello_lib::add`.
3. `build-and-test` описує ці вихідні файли в `Cargo.toml`, додає
   `tests/test_basic.rs`, а через `cargo build` генерує `Cargo.lock`.
4. `ci.sh` і `ci.bat` використовують Cargo-проєкт для release-збірки,
   release-тестів і копіювання `hello` або `hello.exe` у `dist/`.
5. `github-actions` створює `ci.yml`, який не дублює команди Rust, а лише
   запускає відповідний CI-скрипт на кожній операційній системі й завантажує
   `dist/`.

На кожному етапі передаються лише потрібні шляхи, параметри та результати
попередньої перевірки. Секрети, токени й конфіденційні дані не передаються.

## 5. Обробка помилок оркестратором `init`

Оркестратор `/init` виконує етапи строго в такому порядку:

1. `/git-init`;
2. `/create-project`;
3. `/create-build`;
4. `/create-actions`;
5. `/check`.

Після кожного етапу `init` перевіряє код завершення, очікувані файли та
результат відповідного prompt. Якщо етап завершується помилкою, оркестратор:

- негайно зупиняє виконання;
- не запускає наступні етапи;
- вказує номер і назву невдалого кроку;
- показує точну причину та пояснює, що потрібно виправити;
- не оголошує роботу успішною.

Фінальний успіх можливий лише тоді, коли всі попередні етапи завершилися
успішно, а read-only перевірка `/check` повернула `Статус: PASSED`. Будь-який
`FAIL` у таблиці `/check` означає загальний статус `FAILED`.

## 6. Відповідність файлів ролям

| Роль | Каталог | Файли |
|---|---|---|
| Agent | `.github/agents/` | [`build-engineer.agent.md`](../.github/agents/build-engineer.agent.md) — роль, доступні інструменти, skills, commands і правила роботи. |
| Skills | `.github/skills/` | [`project-scaffold/SKILL.md`](../.github/skills/project-scaffold/SKILL.md), [`build-and-test/SKILL.md`](../.github/skills/build-and-test/SKILL.md), [`github-actions/SKILL.md`](../.github/skills/github-actions/SKILL.md). |
| Commands | `.github/prompts/` | [`git-init.prompt.md`](../.github/prompts/git-init.prompt.md), [`create-project.prompt.md`](../.github/prompts/create-project.prompt.md), [`create-build.prompt.md`](../.github/prompts/create-build.prompt.md), [`create-actions.prompt.md`](../.github/prompts/create-actions.prompt.md), [`check.prompt.md`](../.github/prompts/check.prompt.md), [`init.prompt.md`](../.github/prompts/init.prompt.md). |

## 7. Формат VS Code Copilot

Проєкт використовує формат кастомізації **VS Code Copilot**:

- **custom agents** — файли `.agent.md` у `.github/agents/`;
- **prompt files** — файли `.prompt.md` у `.github/prompts/`, доступні як
  slash-команди;
- **agent skills** — файли `SKILL.md` у `.github/skills/<name>/`, які
  описують спеціалізовані багатоетапні робочі процеси.

Таким чином, агент, skills і commands розділені за відповідальністю та можуть
використовуватися повторно без змішування інструкцій із вихідним кодом
Rust-проєкту.
