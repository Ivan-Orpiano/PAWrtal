#!/bin/bash
# Exit if any command fails
set -e

# Install Flutter
git clone https://github.com/flutter/flutter.git --depth 1
export PATH="$PATH:`pwd`/flutter/bin"

# Enable web
flutter config --enable-web

# Get dependencies
flutter pub get

# Build web (release mode)
flutter build web --release
