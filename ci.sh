#!/usr/bin/env bash
set -euo pipefail

cargo build --release
cargo test --release
mkdir -p dist
cp target/release/hello dist/hello
