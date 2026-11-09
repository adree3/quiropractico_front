#!/bin/bash
set -e

# 1. Clonar Flutter SDK 3.29.3 si no existe en cache
if [ ! -d "flutter-sdk" ]; then
  echo "Clonando Flutter SDK 3.29.3..."
  git clone https://github.com/flutter/flutter.git -b 3.29.3 --depth 1 flutter-sdk
fi

# 2. Agregar Flutter al PATH
export PATH="$PATH:$(pwd)/flutter-sdk/bin"

# 3. Configuración y dependencias
flutter config --no-analytics
flutter pub get

# 4. Variables de compilación (Vercel CI / Git)
GIT_HASH=${VERCEL_GIT_COMMIT_SHA:-$(git rev-parse --short HEAD 2>/dev/null || echo "dev-local")}
BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "===> Iniciando compilación de Flutter Web"
echo "API_URL: $API_URL"
echo "GIT_HASH: $GIT_HASH"
echo "BUILD_TIME: $BUILD_TIME"

# 5. Compilar la aplicación web inyectando variables de entorno
flutter build web --release --base-href / \
  --dart-define=API_URL="$API_URL" \
  --dart-define=GIT_HASH="$GIT_HASH" \
  --dart-define=BUILD_TIME="$BUILD_TIME"
