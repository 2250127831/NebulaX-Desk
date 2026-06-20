#!/usr/bin/env bash
# Build NebulaX-Desk
set -e
cd "$(dirname "$0")/.."

if [ -n "$MSYSTEM" ]; then
    # MSYS2 / Git Bash on Windows
    export PATH="/mingw64/bin:/usr/bin:/bin"
    export TMP=/tmp TEMP=/tmp
    GEN="Unix Makefiles"
    EXTRA="-DCMAKE_CXX_COMPILER=g++ -DQT_QML_NO_CACHEGEN=ON"
else
    # Linux / macOS
    GEN="Unix Makefiles"
    EXTRA=""
fi

rm -rf build
cmake -S . -B build -G "$GEN" $EXTRA

if [ -n "$MSYSTEM" ]; then
    # Workaround: qt_setup_tool_path.bat needs absolute path under MSYS2
    sed -i 's|\.qt/bin/qt_setup_tool_path.bat|'"$PWD/build/.qt/bin/qt_setup_tool_path.bat"'|g' \
        build/CMakeFiles/nebulaX-desk.dir/build.make 2>/dev/null || true
fi

cmake --build build
echo "=== BUILD OK ==="
