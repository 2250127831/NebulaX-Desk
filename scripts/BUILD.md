# Build

## 依赖

| 平台 | Qt6 | 编译器 | CMake |
|------|-----|--------|-------|
| Windows (MSYS2) | `mingw-w64-x86_64-qt6-base` + `mingw-w64-x86_64-qt6-declarative` (6.9) | MSYS2 MinGW g++ ≥ 13 | ≥ 3.22 |
| Linux (Ubuntu 22.04) | `qt6-base-dev` + `qt6-declarative-dev` (6.2+) | g++ ≥ 11 | ≥ 3.22 |

## 一键构建

```bash
bash scripts/build.sh
```

脚本自动检测所在平台，Windows 下额外处理 MSYS2 的 TMP 环境变量和 QML type registration workaround。

## 手动构建

### Linux

```bash
cmake -S . -B build -G "Unix Makefiles"
cmake --build build
```

### Windows (MSYS2 MINGW64 终端)

```bash
export TMP=/tmp TEMP=/tmp
cmake -S . -B build -G "Unix Makefiles" -DCMAKE_CXX_COMPILER=g++ -DQT_QML_NO_CACHEGEN=ON
# 补丁：qt_setup_tool_path.bat 需要绝对路径
sed -i 's|\.qt/bin/qt_setup_tool_path.bat|'"$PWD/build/.qt/bin/qt_setup_tool_path.bat"'|g' \
    build/CMakeFiles/nebulaX-desk.dir/build.make
cmake --build build
```

### 从 Git Bash 跨环境构建（Windows）

```bash
env -i MSYSTEM=MINGW64 PATH=/e/msys2/mingw64/bin:/e/msys2/usr/bin HOME=/home/1 \
  E:/msys2/usr/bin/bash.exe -c "cd '/c/Users/1/Desktop/NebulaX-Desk' && \
  TMP=/tmp TEMP=/tmp ./build.sh"
```

## 跨平台注意事项

1. **socket 抽象层** — `ClientWorker.h` 用 `#ifdef Q_OS_WIN` 区分 Winsock2 / POSIX，对外提供统一内联函数：
   - `socket_t` / `kInvalidSocket` / `closeSocket()` — 类型与销毁
   - `net_init()` / `net_cleanup()` — WSAStartup (Win) / no-op (Linux)
   - `net_send()` — 统一 `const void*` buf（Win 内部强转 `const char*`）
   - `net_recv()` / `net_recv_all()` — `net_recv_all` 在 Win 下循环读，Linux 下用 `MSG_WAITALL`
   - `net_setsockopt()` — 统一 `const void*` optval（Win 内部强转 `const char*`）
   - `kSocketAgain` — 超时错误码统一为 `WSAETIMEDOUT` / `EAGAIN`
2. **业务代码零 #ifdef** — 调用处只管 `net_send(fd, &cmd, sizeof(cmd), 0)`，不出现平台分支
3. **`ws2_32` 链接** — 仅在 `WIN32` 平台链接（CMakeLists.txt 条件判断）
4. **QML AOT 缓存** — Linux 下正常，MSYS2 下需 `-DQT_QML_NO_CACHEGEN=ON`
5. **QML 加载** — 用 `engine.load(QUrl("qrc:/qml/Main.qml"))` 兼容 Qt 6.2~6.9

## 产物

- Windows: `build/nebulaX-desk.exe` (~286KB PE32+)
- Linux: `build/nebulaX-desk` (ELF 可执行文件)
