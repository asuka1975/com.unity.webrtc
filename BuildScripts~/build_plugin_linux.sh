#!/bin/bash -eu

export LIBWEBRTC_DOWNLOAD_URL=https://github.com/Unity-Technologies/com.unity.webrtc/releases/download/M89/webrtc-linux.zip
export SOLUTION_DIR=$(pwd)/Plugin~

# Download LibWebRTC 
if [ ! -f webrtc-linux.zip ]; then
    curl -L $LIBWEBRTC_DOWNLOAD_URL > webrtc-linux.zip
fi

if [ -d $SOLUTION_DIR/webrtc ]; then
    rm -rf $SOLUTION_DIR/webrtc
fi
unzip -d $SOLUTION_DIR/webrtc webrtc-linux.zip 

# TODO:: Remove this install process from here and recreate an image to build the plugin.
#sudo apt install -y clang-10 libc++-10-dev libc++abi-10-dev freeglut3-dev
#sudo apt install -y nvidia-cuda-dev libvulkan-dev

# Build UnityRenderStreaming Plugin 
cd "$SOLUTION_DIR"
if [ -d build ]; then
    rm -rf build
fi
cmake . \
  -D CMAKE_C_COMPILER="clang-10" \
  -D CMAKE_CXX_COMPILER="clang++-10" \
  -D CMAKE_CXX_FLAGS="-stdlib=libc++" \
  -D CMAKE_BUILD_TYPE="Release" \
  -B build

cmake \
  --build build \
  --config Release \
  --target WebRTCPlugin
