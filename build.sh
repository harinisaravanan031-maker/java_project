#!/usr/bin/env bash
# Compiles all sources into ./out
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p out
javac -Xlint:all -d out src/com/fintech/ledger/*.java
echo "Build successful: classes are in ./out"
