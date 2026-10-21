1. <current_datetime>2026-10-22T01:07:12.132+03:00</current_datetime>

Я роблю лабораторну роботу: AI-агент для VS Code Copilot, який у репозиторії
генерує кросплатформний Rust проєкт Hello World (Cargo + cargo test) і CI
на GitHub Actions (Windows, Linux, macOS).
Зараз я в гілці develop і створюю ТІЛЬКИ інструкції агента (manifest, skills,
prompts-команди, документацію). Не створюй src/, tests/, Cargo.toml, ci.yml, ci.sh, ci.bat:
їх згенерує агент пізніше в гілці feature.
Файли створюй по одному, коли я попрошу. Мова інструкцій: українська,
імена файлів і команд: англійською.

2. <current_datetime>2026-10-22T01:07:55.898+03:00</current_datetime>

Створи файл .github/agents/build-engineer.agent.md з YAML frontmatter
(description, tools) і розділами:
1. Роль: build engineer для Rust/Cargo проєктів.
2. Область відповідальності: scaffold, збірка, юніт-тести, CI.
3. Доступні skills: project-scaffold, build-and-test, github-actions (з шляхами).
4. Доступні commands: git-init, create-project, create-build, create-actions,
   check, init (з коротким описом).
5. Правила роботи з файлами: ніколи не перезаписувати наявні файли без
   перевірки; ідемпотентність (повторний запуск не дублює вміст); показувати
   diff/список змін перед завершенням.
6. Заборонені дії: видалення файлів, git push --force, переписування історії,
   зміна захисту гілок, робота з секретами/токенами, публікація даних.
7. Порядок роботи.
8. Критерії успішного завершення: існує виконуваний файл hello (target/release/hello, копія в dist/); тест basic_addition проходить (cargo test); ci.yml містить ubuntu/windows/macos і лише викликає ci.sh/ci.bat; target/ і dist/ не під Git; check завершується без помилок.
9. Поведінка при помилці: зупинитись, показати причину, не вважати роботу успішною.

3. <current_datetime>2026-10-22T01:10:50.087+03:00</current_datetime>

Створи .github/skills/project-scaffold/SKILL.md.
Frontmatter: name: project-scaffold, description (коли застосовувати).
Вхід: language=Rust, project_name=hello.
Вихід: src/lib.rs (pub fn add(a: i32, b: i32) -> i32), src/main.rs (друкує
"Hello, World!" і використовує hello_lib::add), порожні каталоги tests/ та docs/,
README (якщо немає).
Правила: не перезаписувати наявні файли; якщо файл існує і відрізняється, повідомити.
Перевірки: src/main.rs існує; вказана команда запуску (cargo run --release або
./target/release/hello, на Windows target\release\hello.exe). Типова помилка:
файл вже існує з іншим вмістом.
Додай приклад входу та очікуваного результату.

4. <current_datetime>2026-10-22T01:11:49.706+03:00</current_datetime>

Створи .github/skills/build-and-test/SKILL.md.
Frontmatter: name: build-and-test, description (коли застосовувати).
Вхід: наявні src/lib.rs, src/main.rs.
Вихід: Cargo.toml ([package] name = "hello", version = "0.1.0", edition = "2021";
[lib] name = "hello_lib", path = "src/lib.rs"; [[bin]] name = "hello", path = "src/main.rs"),
tests/test_basic.rs з тестом #[test] fn basic_addition() (assert_eq!(hello_lib::add(2, 3), 5)),
Cargo.lock (згенерувати командою cargo build), скрипти ci.sh (bash, set -euo pipefail)
і ci.bat: cargo build --release, cargo test --release і копіювання виконуваного hello
(target/release/hello, на Windows target\release\hello.exe) у dist/. ci.sh має бути
виконуваним (git update-index --chmod=+x). ci.bat після кожної команди перевіряє
%errorlevel% і завершується з ненульовим кодом при помилці.
Перевірки: cargo test показує "test basic_addition ... ok"; існує виконуваний hello.
Типові помилки: cargo не знайдено (потрібен rustup); на Windows файл має розширення .exe;
каталог dist/ не створено перед копіюванням. Ідемпотентність: не дублювати секції
в Cargo.toml.
Додай приклад входу та очікуваного результату.

5. <current_datetime>2026-10-22T01:14:12.889+03:00</current_datetime>

Створи .github/skills/github-actions/SKILL.md.
Frontmatter: name: github-actions, description (коли застосовувати).
Вихід: .github/workflows/ci.yml: тригери push і pull_request на develop та master;
одна job з matrix os: [ubuntu-latest, windows-latest, macos-latest], fail-fast: false;
кроки: checkout, запуск ./ci.sh (не Windows, shell: bash) або ci.bat (Windows, shell: cmd),
upload-artifact з dist/ (actions/upload-artifact@v4, унікальне ім'я hello-${{ matrix.os }},
if-no-files-found: error). ВАЖЛИВО: у кроках run файлу ci.yml НЕ має бути команд cargo/rustc напряму,
лише запуск ci.sh/ci.bat. Без секретів.
Перевірки: YAML валідний (python -c "import yaml..." або actionlint, якщо є);
у файлі є три ОС; немає слів token/password/secret.
Типова помилка: ci.sh без прав на виконання.
Додай приклад входу та очікуваного результату.

6. <current_datetime>2026-10-22T01:15:05.910+03:00</current_datetime>

Створи .github/prompts/git-init.prompt.md.
Frontmatter: description, agent: build-engineer.
Розділи: Передумови, Дії, Очікувані файли, Команди перевірки, Повідомлення про помилку, Ідемпотентність.
Дії: перевірити, що поточний каталог є git-репозиторієм (git rev-parse); створити .gitignore або ДОПОВНИТИ його без дублів рядками target/, build/, dist/, out/, .vs/, .env, *.pem, *.key; показати git status.
Нічого не видаляти.

7. <current_datetime>2026-10-22T01:15:41.965+03:00</current_datetime>

Створи .github/prompts/create-project.prompt.md.
Frontmatter: description, agent: build-engineer.
Розділи: Передумови (git-репозиторій), Дії (виконати інструкції зі skill .github/skills/project-scaffold/SKILL.md з language=Rust, project_name=hello), Очікувані файли (src/lib.rs, src/main.rs), Команди перевірки (src/main.rs існує), Повідомлення про помилку, Ідемпотентність.

8. <current_datetime>2026-10-22T01:16:09.782+03:00</current_datetime>

Створи .github/prompts/create-build.prompt.md.
Frontmatter: description, agent: build-engineer.
Розділи: Передумови (є src/lib.rs, src/main.rs), Дії (виконати skill .github/skills/build-and-test/SKILL.md), Очікувані файли (Cargo.toml, Cargo.lock, tests/test_basic.rs, ci.sh, ci.bat), Команди перевірки, Повідомлення про помилку, Ідемпотентність.

9. <current_datetime>2026-10-22T01:16:41.787+03:00</current_datetime>

Створи .github/prompts/create-actions.prompt.md.
Frontmatter: description, agent: build-engineer.
Розділи: Передумови (є ci.sh і ci.bat), Дії (виконати skill .github/skills/github-actions/SKILL.md), Очікувані файли (.github/workflows/ci.yml), Команди перевірки (валідність YAML, три ОС, виклик лише ci.sh/ci.bat), Повідомлення про помилку, Ідемпотентність.

10. <current_datetime>2026-10-22T01:17:20.338+03:00</current_datetime>

Створи .github/prompts/check.prompt.md.
Frontmatter: description, agent: build-engineer.
Режим: ТІЛЬКИ ЧИТАННЯ. Не створювати і не змінювати файли проєкту (тимчасові каталоги target/ дозволені, вони в .gitignore).
Виконати перевірки і вивести таблицю PASS/FAIL:
1. Існують .github/agents/build-engineer.agent.md і три SKILL.md.
2. Кожен skill має розділи Вхід, Вихід, Перевірки.
3. Існують src/lib.rs, src/main.rs, tests/test_basic.rs, Cargo.toml, Cargo.lock, ci.sh, ci.bat.
4. cargo build --release проходить.
5. cargo test --release: basic_addition ... ok.
6. Існує виконуваний файл hello (target/release/hello або target\release\hello.exe).
7. ci.yml: валідний YAML, містить ubuntu-latest, windows-latest, macos-latest, у кроках run викликає лише ci.sh/ci.bat (без прямих команд cargo/rustc).
8. git ls-files не містить target/, build/, dist/, .env, *.key, *.pem.
9. .gitignore містить target/, build/ і dist/.
Якщо є хоча б один FAIL: вказати який саме і завершити зі статусом FAILED. Якщо все PASS: статус PASSED.
Додай розділи: Передумови, Повідомлення про помилку.

11. <current_datetime>2026-10-22T01:18:15.073+03:00</current_datetime>

Створи .github/prompts/init.prompt.md.
Frontmatter: description, agent: build-engineer.
Ти оркестратор. Виконуй кроки СТРОГО по порядку, читаючи і виконуючи інструкції з файлів:
1. .github/prompts/git-init.prompt.md
2. .github/prompts/create-project.prompt.md
3. .github/prompts/create-build.prompt.md
4. .github/prompts/create-actions.prompt.md
5. .github/prompts/check.prompt.md
Після кожного кроку перевіряй результат. Якщо крок завершився помилкою: ЗУПИНИСЬ, не виконуй наступні, виведи звіт (який крок, причина, що виправити). Не оголошуй успіх без PASSED від check.
Повторний запуск не повинен руйнувати чи дублювати наявні файли.
У кінці виведи таблицю: крок, статус, створені/змінені файли.
Додай розділи: Передумови, Очікувані файли, Повідомлення про помилку.

12. <current_datetime>2026-10-22T01:18:52.119+03:00</current_datetime>

Онови README.md (зараз там лише назва репозиторія, збережи її): ПІП [ПІП], група [група], варіант 10 (Rust, Cargo, cargo test), короткий опис проєкту, розділ "Запуск агента": відкрити папку у VS Code, відкрити Copilot Chat, вибрати агента build-engineer, виконати /init. Додай список commands. Залиш плейсхолдери для ПІП і групи.

13. <current_datetime>2026-10-22T01:19:17.824+03:00</current_datetime>

Створи docs/architecture.md з розділами:
1. Які проблеми вирішує агент.
2. Які skills використовує і за що вони відповідають.
3. Які commands доступні користувачу.
4. Які дані передаються між етапами (project_name -> src/ -> Cargo.toml -> ci.sh/ci.bat -> ci.yml).
5. Як оркестратор init обробляє помилки.
6. Таблиця відповідності файлів ролям: agent -> .github/agents/, skills -> .github/skills/, commands -> .github/prompts/.
7. Примітка, що використано формат VS Code Copilot (custom agents, prompt files, agent skills).
