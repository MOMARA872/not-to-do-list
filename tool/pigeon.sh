#!/usr/bin/env bash
set -euo pipefail
for f in pigeons/*.dart; do
  echo "Generating $f..."
  dart run pigeon --input "$f"
done
echo "Done. Run 'dart format lib/platform/' to format generated Dart."
