#!/bin/bash -eu

export LIBWEBRTC_DOWNLOAD_URL=https://github.com/Unity-Technologies/com.unity.webrtc/releases/download/M89/webrtc-mac.zip
export SOLUTION_DIR=$(pwd)/Plugin~
export BUNDLE_FILE=$(pwd)/Runtime/Plugins/x86_64/webrtc.bundle

# Install cmake
#export HOMEBREW_NO_AUTO_UPDATE=1
#brew install cmake

# Clear build directory if it exists
if [ -d Plugin~/build ]; then
    rm -rf Plugin~/build
fi

# Download webrtc 
if [ ! -f webrtc-mac.zip ]; then
    curl -L $LIBWEBRTC_DOWNLOAD_URL > webrtc-mac.zip
fi

# Unfurl webrtc
if [ -d $SOLUTION_DIR/webrtc ]; then
    rm -rf $SOLUTION_DIR/webrtc
fi
unzip -d $SOLUTION_DIR/webrtc webrtc-mac.zip 

# Remove old bundle file
if [ -f "$BUNDLE_FILE" ]; then
    rm -r "$BUNDLE_FILE"
fi

# Build UnityRenderStreaming Plugin
cd "$SOLUTION_DIR"
cmake . \
  -G Xcode \
  -B build

cmake \
  --build build \
  --config Release \
  --target WebRTCPlugin
