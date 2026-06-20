# NebulaX-Desk

**基于 Qt 6 / QML 的专业交易终端，通过二进制 TCP 协议与撮合引擎实时通信。**

[![Qt](https://img.shields.io/badge/Qt-6.2%2B-41CD52?logo=qt&logoColor=white)](https://www.qt.io)
[![C++](https://img.shields.io/badge/C%2B%2B-17-00599C?logo=c%2B%2B&logoColor=white)](https://en.cppreference.com/w/cpp/17)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## 功能

- **实时交易** — 通过二进制 TCP 协议连接 NebulaX 撮合引擎（32 字节命令 / 48 字节响应帧）
- **订单管理** — 下单、撤单、跟踪成交和部分成交
- **行情数据** — 实时盘口深度可视化，支持 200ms 自动刷新
- **深色专业界面** — 交易终端风格，呼吸动画背景
- **无边框窗口** — 自定义标题栏、拖动、吸附、缩放
- **订单持久化** — 订单数据保存到 JSON 文件，重启不丢失
- **跨平台** — Windows（MSYS2 MinGW）和 Linux（Ubuntu 22.04+）

---

## 架构

```
┌──────────────────────────────────────────────────┐
│  QML 前端 (NebulaX.Desk 模块)                    │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌──────────┐  │
│  │ 连接页  │ │ 下单页  │ │ 行情页  │ │ 订单列表 │  │
│  └────────┘ └────────┘ └────────┘ └──────────┘  │
│         ┌────────────────────────────┐           │
│         │   OrderCard / DepthBar     │           │
│         └────────────────────────────┘           │
├──────────────────────────────────────────────────┤
│  C++ 后端                                        │
│  ┌──────────────────────────────────────────────┐│
│  │  ClientWorker                                ││
│  │  ├─ Socket 抽象层（跨平台）                   ││
│  │  ├─ 接收线程（std::thread + 信号）            ││
│  │  ├─ 待确认订单队列                            ││
│  │  └─ 订单持久化（JSON 文件）                   ││
│  └──────────────────────────────────────────────┘│
├──────────────────────────────────────────────────┤
│  协议层                                          │
│  ┌──────────────────────────────────────────────┐│
│  │  BinaryCommand (32B) / BinaryResponse (48B)  ││
│  │  命令: NEW · CANCEL · BOOK                   ││
│  │  响应: OK · FILLED · TRADE · ERROR ·         ││
│  │        CANCELLED · BOOK · CLOSE             ││
│  └──────────────────────────────────────────────┘│
└──────────────────────────────────────────────────┘
```

### 关键设计决策

| 决策 | 理由 |
|------|------|
| **`std::thread` 做接收循环** | QThread 事件循环会在阻塞 I/O 时卡住；独立线程 + Qt 队列信号是最小正确的方案 |
| **`qRegisterMetaType` 注册跨线程信号类型** | `uint32_t`/`uint64_t` 默认未注册，Qt 无法在跨线程信号中队列传递 |
| **Fusion 样式** | 唯一允许完全自定义所有控件（background、indicator、contentItem）的样式 |
| **无边框 + `startSystemMove()`** | 将窗口拖拽委托给操作系统，实现平滑吸附、多显示器和 Wayland 支持 |
| **内联 QML 注册 Theme 单例** | 避免 Qt 6.2 文件型单例加载的时序问题 |
| **待确认订单队列** | 服务端 RSP_OK 只返回 order_id，不包含 side/price/qty；FIFO 队列关联发送和确认 |

---

## 构建

### 依赖

| 平台 | Qt 6 | 编译器 | CMake |
|------|------|--------|-------|
| Windows (MSYS2) | `mingw-w64-x86_64-qt6-base` + `mingw-w64-x86_64-qt6-declarative`（6.9） | MSYS2 MinGW g++ ≥ 13 | ≥ 3.22 |
| Linux (Ubuntu 22.04) | `qt6-base-dev` + `qt6-declarative-dev`（6.2+） | g++ ≥ 11 | ≥ 3.22 |

### 一键构建

```bash
git clone https://github.com/yourusername/NebulaX-Desk.git
cd NebulaX-Desk
bash scripts/build.sh
```

可执行文件位于 `build/nebulaX-desk`（Windows 为 `build/nebulaX-desk.exe`）。

### 手动构建

```bash
cmake -S . -B build -G "Unix Makefiles"
cmake --build build
```

### 平台注意事项

详见 [scripts/BUILD.md](scripts/BUILD.md) 了解跨平台相关问题（MSYS2 TMP 路径、.bat 路径补丁、QML 缓存等）。

---

## 使用

1. **启动** 运行可执行文件
2. **连接** 在连接页输入服务器地址和端口（默认 `192.168.1.13:2250`）
3. **下单** 选择买卖方向，输入价格、数量和用户 ID
4. **查看行情** 行情页展示盘口深度可视化
5. **跟踪订单** 订单列表页支持按状态筛选（ALL / OPEN / PARTIAL / FILLED / CANCELLED）
6. **批量操作** 长按订单卡片或点击 Select 进入多选模式，支持批量撤单

---

## 协议

### 命令格式（32 字节）

```
偏移  大小  字段      说明
────────────────────────────────────
  0    1    type      CMD_NEW (0x01) / CMD_CANCEL (0x02) / CMD_BOOK (0x03)
  1    1    side      SIDE_BUY (0x01) / SIDE_SELL (0x02) — 仅 NEW
  2-3  2    _pad      填充
  4-7  4    price     价格 × 100（仅 NEW）
  8-11 4    quantity  数量（仅 NEW）
 16-23 8    user_id   用户 ID（NEW、CANCEL）
 24-31 8    order_id  订单 ID（仅 CANCEL）
```

### 响应格式（48 字节）

详见 [include/protocol.h](include/protocol.h)。

---

## 项目结构

```
NebulaX-Desk/
├── CMakeLists.txt          # 构建配置
├── README.md               # 本文件
├── docs/                   # 设计文档
│   ├── DESIGN.md
│   └── PROMPT.md
├── include/
│   └── protocol.h          # 二进制协议定义
├── qml/
│   ├── Main.qml            # 应用根窗口（无边框 + 侧边栏）
│   ├── components/
│   │   ├── DepthBar.qml    # 盘口深度条（shimmer 动画）
│   │   └── OrderCard.qml   # 订单卡片（状态 + 进度）
│   └── pages/
│       ├── ConnectionPage.qml
│       ├── MarketPage.qml
│       ├── OrderListPage.qml
│       └── OrderPage.qml
├── scripts/
│   ├── BUILD.md            # 构建说明
│   └── build.sh            # 构建脚本
└── src/
    ├── main.cpp            # 入口 + Theme 单例注册
    ├── ClientWorker.h      # Socket 抽象层 + ClientWorker 类
    └── ClientWorker.cpp    # 网络通信 + 持久化
```

---

## 技术栈

- **语言**: C++17、QML（Qt Quick）
- **UI 框架**: Qt 6.2+（Qt Quick Controls 2 Fusion 样式）
- **构建系统**: CMake 3.16+（`qt_add_qml_module`）
- **网络**: 原生 TCP Socket（Winsock2 / POSIX），通过内联函数跨平台抽象
- **线程**: `std::thread` 处理 I/O，`QObject` 信号实现跨线程通信
- **持久化**: JSON 文件（`QJsonDocument`）

---

## 许可

MIT
