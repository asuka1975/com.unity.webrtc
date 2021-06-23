#!/bin/bash -eu

CWD=$(pwd)
export LIBWEBRTC_DOWNLOAD_URL=https://github.com/Unity-Technologies/com.unity.webrtc/releases/download/M89/webrtc-ios.zip
export SOLUTION_DIR=$CWD/Plugin~
export WEBRTC_FRAMEWORK_DIR=$CWD/Runtime/Plugins/iOS
export WEBRTC_ARCHIVE_DIR=build/webrtc.xcarchive
export WEBRTC_SIM_ARCHIVE_DIR=build/webrtc-sim.xcarchive

# Install cmake
#export HOMEBREW_NO_AUTO_UPDATE=1
#brew install cmake

# Download webrtc 
if [ ! -f webrtc-ios.zip ]; then
    curl -L $LIBWEBRTC_DOWNLOAD_URL > webrtc-ios.zip
fi

# Unfurl webrtc
if [ -d $SOLUTION_DIR/webrtc ]; then
    rm -rf $SOLUTION_DIR/webrtc
fi
unzip -d $SOLUTION_DIR/webrtc webrtc-ios.zip 

# Clear build directory if it exists
if [ -d $SOLUTION_DIR/build ]; then
    rm -rf $SOLUTION_DIR/build
fi

# BUG: !@#$%^&*()ing xcodebuild is not obeying the --archivePath directive
# and instead writes into a temporary default location.  Worse, it can become
# confused by previous contents in that directory.
# WORKAROUND: try to find and purge the archives
MYSTERIOUS_ARCHIVE=`find $HOME/Library/Developer/Xcode/DerivedData -type d -name WebRTCPlugin | head -1`
if [ ! -z $MYSTERIOUS_ARCHIVE && -d "$MYSTERIOUS_ARCHIVE" ]; then
    echo "HACK: Found MYSTERIOUS_ARCHIVE='$MYSTERIOUS_ARCHIVE'"
    rm -rf $MYSTERIOUS_ARCHIVE
fi

# Build webrtc Unity plugin 
cd "$SOLUTION_DIR"
echo "CMake..."
cmake . \
  -G Xcode \
  -D CMAKE_SYSTEM_NAME=iOS \
  -D "CMAKE_OSX_ARCHITECTURES=arm64;x86_64" \
  -D CMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH=NO \
  -D CMAKE_XCODE_ATTRIBUTE_ENABLE_BITCODE=YES \
  -B build

echo "Build step 1..."
xcodebuild \
  -sdk iphonesimulator \
  -arch 'x86_64' \
  -project build/webrtc.xcodeproj \
  -target WebRTCLib \
  -configuration Release

# BUG: !@#$%^&*() xcodebuild is looking for libwebrtc.a in the wrong spot
# WORKAROUND: copy it to the where it should be
echo "HACK: copy libwebrtc.a to where it should be..."
mkdir -vp $CWD/Plugin~/webrtc/lib/x64
cp -v $CWD/Plugin~/webrtc/lib/libwebrtc.a $CWD/Plugin~/webrtc/lib/x64/libwebrtc.a
cp -v $CWD/Plugin~/webrtc/lib/libwebrtcd.a $CWD/Plugin~/webrtc/lib/x64/libwebrtcd.a

echo "Archive step 1..."
xcodebuild archive \
  -sdk iphonesimulator \
  -arch 'x86_64' \
  -scheme WebRTCPlugin \
  -project build/webrtc.xcodeproj \
  -configuration Release \
  -archivePath "$WEBRTC_SIM_ARCHIVE_DIR"

# BUG: !@#$%^&*()ing xcodebuild is not obeying the --archivePath directive
# WORKAROUND: we copy from where it is (wtf?!!!)
echo "HACK: copy archives to where they should have been placed..."
mkdir -p $WEBRTC_SIM_ARCHIVE_DIR/Products/@rpath
cp -rf $MYSTERIOUS_ARCHIVE/InstallationBuildProductsLocation@rpath/webrtc.framework "$WEBRTC_SIM_ARCHIVE_DIR/Products/@rpath/webrtc.framework"
cp -rf $MYSTERIOUS_ARCHIVE/InstallationBuildProductsLocation@rpath/webrtc.framework "$WEBRTC_SIM_ARCHIVE_DIR/Products/@rpath/webrtc.framework"
# Remove the archive again to make room from for the next step
if [ -d $MYSTERIOUS_ARCHIVE ]; then
    rm -rf $MYSTERIOUS_ARCHIVE
fi

echo "Build step 2..."
xcodebuild \
  -sdk iphoneos \
  -project build/webrtc.xcodeproj \
  -target WebRTCLib \
  -configuration Release

echo "Archive step 2..."
xcodebuild archive \
  -sdk iphoneos \
  -scheme WebRTCPlugin \
  -project build/webrtc.xcodeproj \
  -configuration Release \
  -archivePath "$WEBRTC_ARCHIVE_DIR"

if [ -d "$WEBRTC_FRAMEWORK_DIR/webrtc.framework" ]; then
    rm -rvf "$WEBRTC_FRAMEWORK_DIR/webrtc.framework"
fi

# BUG: !@#$%^&*()ing xcodebuild is not obeying the --archivePath directive
# WORKAROUND: we copy from where it is (wtf?!!!)
echo "HACK: copy archives again to where they should have been placed..."
mkdir -p $WEBRTC_ARCHIVE_DIR/Products/@rpath
cp -rf $MYSTERIOUS_ARCHIVE/InstallationBuildProductsLocation@rpath/webrtc.framework "$WEBRTC_ARCHIVE_DIR/Products/@rpath/webrtc.framework"

echo "Final lipo (whatever that is)..."
lipo -create -o "$WEBRTC_FRAMEWORK_DIR/webrtc.framework/webrtc" \
  "$WEBRTC_ARCHIVE_DIR/Products/@rpath/webrtc.framework/webrtc" \
  "$WEBRTC_SIM_ARCHIVE_DIR/Products/@rpath/webrtc.framework/webrtc"
