---
name: github-actions
description: "Застосовуй для створення або перевірки кросплатформного GitHub Actions workflow, який запускає ci.sh або ci.bat на Linux, Windows і macOS та завантажує dist/ як артефакт."
---

# GitHub Actions

## Призначення

Цей skill створює мінімальний кросплатформний workflow для Rust/Cargo
проєкту. GitHub Actions лише запускає підготовлений скрипт CI та завантажує
його результат; команди збірки й тестування не дублюються у workflow.

## Вхід

Перед початком перевір:

```text
ci.sh існує
ci.bat існує
```

Також перевір, що `ci.sh` має виконуваний біт. Якщо його немає, виправ це
через:

```text
git update-index --chmod=+x ci.sh
```

Не перезаписуй наявні файли без попередньої перевірки. Якщо скрипт відсутній
або не має потрібних прав, повідом проблему і не оголошуй workflow готовим.

## Вихід

Створи `.github/workflows/ci.yml` з такими вимогами:

```yaml
name: CI

on:
  push:
    branches: [develop, master]
  pull_request:
    branches: [develop, master]

jobs:
  build-and-test:
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Run CI script on Unix
        if: runner.os != 'Windows'
        run: ./ci.sh
        shell: bash

      - name: Run CI script on Windows
        if: runner.os == 'Windows'
        run: ci.bat
        shell: cmd

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: hello-${{ matrix.os }}
          path: dist/
          if-no-files-found: error
```

Workflow повинен мати:

- тригери `push` і `pull_request` лише для гілок `develop` та `master`;
- одну job із matrix `os: [ubuntu-latest, windows-latest, macos-latest]`;
- `fail-fast: false`;
- checkout через `actions/checkout@v4`;
- запуск `./ci.sh` на Linux/macOS із `shell: bash`;
- запуск `ci.bat` на Windows із `shell: cmd`;
- завантаження `dist/` через `actions/upload-artifact@v4`;
- унікальне ім'я артефакту `hello-${{ matrix.os }}`;
- `if-no-files-found: error`.

## Обмеження workflow

- У значеннях `run` файлу `ci.yml` дозволено лише запуск `./ci.sh` або
  `ci.bat` відповідно до операційної системи.
- Не додавай у `run` прямі команди `cargo`, `rustc` або інші команди збірки й
  тестування.
- Не додавай кроки, що дублюють логіку `ci.sh` або `ci.bat`.
- Не додавай секрети, токени, паролі чи інші конфіденційні значення.
- Не додавай зайві jobs або окремі workflow без вимоги користувача.

## Ідемпотентність і правила файлів

1. Перевір, чи існує `.github/workflows/ci.yml`, до початку редагування.
2. Якщо файл не існує, створи його з одним workflow і однією job.
3. Якщо файл існує, перевір його вміст і не дублюй тригери, jobs або кроки.
4. Якщо наявний файл має конфліктний вміст, покажи відмінності та зупинись;
   не перезаписуй його автоматично.
5. Повторний запуск не повинен додавати дублікати YAML-секцій або кроків.
6. Перед завершенням покажи diff і список змінених файлів.

## Перевірки

Перевір, що YAML синтаксично валідний. Якщо доступний Python із PyYAML,
використай:

```text
python -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))"
```

Якщо доступний `actionlint`, можеш додатково виконати:

```text
actionlint .github/workflows/ci.yml
```

Також перевір:

- у файлі присутні `ubuntu-latest`, `windows-latest` і `macos-latest`;
- присутні тригери `push` і `pull_request` для `develop` та `master`;
- `fail-fast` має значення `false`;
- використано `actions/checkout@v4`;
- використано `actions/upload-artifact@v4`;
- шлях артефакту дорівнює `dist/`;
- ім'я артефакту використовує `hello-${{ matrix.os }}`;
- `if-no-files-found` має значення `error`;
- у `run` немає прямих команд `cargo` або `rustc`;
- у файлі немає слів `token`, `password` або `secret`;
- `ci.sh` має виконуваний біт.

## Типова помилка

**`ci.sh` не має прав на виконання.**

Не замінюй запуск на іншу команду і не додавай обхідний виклик. Виправ
виконуваний біт командою:

```text
git update-index --chmod=+x ci.sh
```

Після цього повторно перевір workflow та його diff.

## Приклад

### Вхід

```text
ci.sh існує і має виконуваний біт
ci.bat існує
потрібен CI для develop та master
```

### Очікуваний результат

```text
Створено:
- .github/workflows/ci.yml

Workflow:
- запускається на push і pull_request для develop та master;
- має одну job із ubuntu-latest, windows-latest і macos-latest;
- запускає ci.sh або ci.bat;
- завантажує dist/ як артефакт hello-${{ matrix.os }};
- не містить прямих команд cargo або rustc.

Перевірки YAML і правил workflow завершилися без помилок.
```
