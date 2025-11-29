#!/bin/bash

# Development script with API keys
# Copy this file to run_dev_local.sh and add your actual API keys

# Set your API keys here
GEMINI_API_KEY="your_gemini_api_key_here"
NANO_BANANA_API_KEY="your_nano_banana_api_key_here"

# Run the app with API keys
flutter run \
  --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY" \
  --dart-define=NANO_BANANA_API_KEY="$NANO_BANANA_API_KEY"