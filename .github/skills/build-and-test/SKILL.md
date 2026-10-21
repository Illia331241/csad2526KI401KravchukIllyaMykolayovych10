---
name: build-and-test
description: "Застосовуй, коли потрібно створити конфігурацію Cargo, базовий unit-тест, зібрати Rust-проєкт і перевірити його локально або через кросплатформні CI-скрипти."
---

# Build and Test

## Призначення

Цей skill налаштовує збірку і тестування наявного Rust-проєкту з
`src/lib.rs` та `src/main.rs`, а також готує скрипти для однакового запуску
перевірок на Linux, macOS і Windows.

## Вхід

Перед початком перевір:

```text
src/lib.rs існує
src/main.rs існує
```

Якщо будь-який із цих файлів відсутній, зупинись і повідом про відсутній
вхідний файл. Не створюй заміну автоматично.

## Вихід

Створи лише відсутні файли. Не перезаписуй наявні файли без окремого рішення.

### Cargo.toml

Створи `Cargo.toml` з такими секціями та значеннями:

```toml
[package]
name = "hello"
version = "0.1.0"
edition = "2021"

[lib]
name = "hello_lib"
path = "src/lib.rs"

[[bin]]
name = "hello"
path = "src/main.rs"
```

Не дублюй секції `[package]`, `[lib]` або `[[bin]]`. Якщо `Cargo.toml` уже
існує, спочатку перевір його вміст і повідом про відсутні або конфліктні
значення замість безумовного перезапису.

### tests/test_basic.rs

Створи `tests/test_basic.rs` з тестом:

```rust
#[test]
fn basic_addition() {
    assert_eq!(hello_lib::add(2, 3), 5);
}
```

### Cargo.lock

Згенеруй `Cargo.lock` командою:

```text
cargo build
```

Не редагуй `Cargo.lock` вручну, якщо його можна отримати успішною командою
Cargo.

### ci.sh

Створи `ci.sh` як Bash-скрипт із таким порядком дій:

1. shebang для Bash;
2. `set -euo pipefail`;
3. `cargo build --release`;
4. `cargo test --release`;
5. створення каталогу `dist/`;
6. копіювання `target/release/hello` у `dist/`.

Скрипт має бути еквівалентним такій логіці:

```bash
#!/usr/bin/env bash
set -euo pipefail

cargo build --release
cargo test --release
mkdir -p dist
cp target/release/hello dist/hello
```

Після створення познач `ci.sh` виконуваним:

```text
git update-index --chmod=+x ci.sh
```

### ci.bat

Створи `ci.bat`, який послідовно виконує:

1. `cargo build --release`;
2. `cargo test --release`;
3. створення `dist\`;
4. копіювання `target\release\hello.exe` у `dist\hello.exe`.

Після кожної команди перевіряй `%errorlevel%`. При ненульовому коді
завершуй скрипт із ненульовим кодом. Наприклад:

```bat
@echo off

cargo build --release
if %errorlevel% neq 0 exit /b %errorlevel%

cargo test --release
if %errorlevel% neq 0 exit /b %errorlevel%

if not exist dist mkdir dist
if %errorlevel% neq 0 exit /b %errorlevel%

copy /Y target\release\hello.exe dist\hello.exe
if %errorlevel% neq 0 exit /b %errorlevel%
```

На Windows очікуй виконуваний файл саме `target\release\hello.exe`, а не файл
без розширення.

## Ідемпотентність і правила файлів

- Перед створенням або зміною кожного файла перевір його існування.
- Не перезаписуй наявні файли автоматично.
- Повторний запуск не має дублювати секції в `Cargo.toml`, тестові функції або
  команди у скриптах.
- Якщо файл існує, але має інший вміст, покажи шлях і змістовну відмінність та
  зупинись щодо цього файла.
- Не створюй `dist/` до моменту, коли скрипт готується копіювати виконуваний
  файл; перед копіюванням каталог обов'язково має існувати.
- Не приховуй помилки Cargo, Bash або Windows batch.

## Перевірки

Після створення вихідних файлів виконай:

```text
cargo test
```

У результаті має бути рядок:

```text
test basic_addition ... ok
```

Також перевір:

- успішне виконання `cargo build --release`;
- існування виконуваного файла `target/release/hello` на Linux/macOS;
- існування виконуваного файла `target\release\hello.exe` на Windows;
- існування копії виконуваного файла у `dist/`;
- виконуваний біт `ci.sh` через `git update-index --chmod=+x`;
- відсутність дубльованих секцій у `Cargo.toml`.

## Типові помилки

- **`cargo` не знайдено.** Повідом, що потрібно встановити Rust через
  `rustup`, після чого повторити перевірки.
- **Windows-файл має неправильне розширення.** Використовуй
  `target\release\hello.exe` і копіюй його як `dist\hello.exe`.
- **Каталог `dist/` не створено перед копіюванням.** Спочатку створи `dist/`
  або `dist\`, потім виконуй копіювання.
- **Файл вже існує з іншим вмістом.** Не перезаписуй його; покажи відмінність
  і зупинись.

## Приклад

### Вхід

```text
src/lib.rs існує
src/main.rs існує
```

### Очікуваний результат

```text
Створено або перевірено:
- Cargo.toml
- tests/test_basic.rs
- Cargo.lock (через cargo build)
- ci.sh
- ci.bat

cargo test показує:
test basic_addition ... ok

Release-виконуваний файл:
- Linux/macOS: target/release/hello
- Windows: target\release\hello.exe

Копія:
- dist/hello
- або dist\hello.exe на Windows
```
