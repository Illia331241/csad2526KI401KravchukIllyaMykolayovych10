# Використання

## Запуск агента

1. Відкрийте папку репозиторію у **VS Code**.
2. Відкрийте **Copilot Chat**.
3. Виберіть агента `build-engineer`.
4. Виконайте:

   ```text
   /init
   ```

Команда `/init` послідовно підготує Git-репозиторій, структуру Rust-проєкту,
збірку, CI та фінальну перевірку.

Для окремої read-only перевірки виконайте:

```text
/check
```

Успішна перевірка завершується статусом `PASSED`.

## Локальна збірка і перевірка

### Linux/macOS

Запустіть CI-скрипт:

```bash
./ci.sh
```

Скрипт виконує release-збірку, release-тести, створює `dist/` і копіює
виконуваний файл `hello` у `dist/hello`.

### Windows

Запустіть batch-скрипт:

```bat
ci.bat
```

Скрипт виконує release-збірку, release-тести, створює `dist\` і копіює
`target\release\hello.exe` у `dist\hello.exe`.

## Запуск hello

### Linux/macOS

```bash
./dist/hello
```

### Windows

```bat
dist\hello.exe
```

## Запуск тестів

Для запуску release-тестів виконайте:

```text
cargo test --release
```

Очікуваний тест `basic_addition` має завершитися успішно.
