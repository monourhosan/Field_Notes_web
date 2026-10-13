#!/usr/bin/env bash
set -e

echo "==> Preparing Flutter SDK for Vercel deployment..."

FLUTTER_DIR="$HOME/flutter"

if [ ! -d "$FLUTTER_DIR" ]; then
  echo "==> Cloning Flutter stable branch..."
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

git config --global --add safe.directory "$FLUTTER_DIR" 2>/dev/null || true
git config --global --add safe.directory "$PWD" 2>/dev/null || true

flutter --version

echo "==> Compiling Flutter Web Application..."
cd mobile
flutter pub get
if [ -n "$API_BASE_URL" ]; then
  echo "==> Building with custom API_BASE_URL: $API_BASE_URL"
  flutter build web --release --dart-define=API_BASE_URL="$API_BASE_URL"
else
  flutter build web --release
fi

cp web/vercel.json build/web/vercel.json 2>/dev/null || true

echo "==> Vercel build completed successfully."
