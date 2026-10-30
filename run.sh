#!/usr/bin/env bash
# Builds (if needed) and runs the simulation
set -euo pipefail
cd "$(dirname "$0")"
if [ ! -d out ] || [ -n "$(find src -newer out -name '*.java' 2>/dev/null | head -1)" ]; then
  ./build.sh
fi
java -cp out com.fintech.ledger.FintechLedgerApp
