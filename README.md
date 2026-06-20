# NebulaX-Desk

**A professional Qt 6 / QML trading terminal with real-time binary protocol connectivity.**

[![Qt](https://img.shields.io/badge/Qt-6.2%2B-41CD52?logo=qt&logoColor=white)](https://www.qt.io)
[![C++](https://img.shields.io/badge/C%2B%2B-17-00599C?logo=c%2B%2B&logoColor=white)](https://en.cppreference.com/w/cpp/17)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## Features

- **Real-time trading** — Binary TCP protocol to NebulaX matching engine (32B command / 48B response frames)
- **Order management** — Place buy/sell orders, track fills, partial fills, and cancellations
- **Market data** — Live order book with depth visualization and auto-refresh (200ms)
- **Dark professional UI** — Trading terminal aesthetic with breathing ambient animations
- **Frameless window** — Custom title bar with drag, snap, and resize (Windows Aero Snap support)
- **Order persistence** — Orders survive app restart via JSON file
- **Cross-platform** — Windows (MSYS2 MinGW) and Linux (Ubuntu 22.04+)

### Screenshots

*(Add screenshots here)*

---

## Architecture

```
┌──────────────────────────────────────────────────┐
│  QML Frontend (NebulaX.Desk module)              │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌──────────┐  │
│  │Connect │ │ Order  │ │ Market │ │  Orders  │  │
│  │  Page  │ │  Page  │ │  Page  │ │ List Page│  │
│  └────────┘ └────────┘ └────────┘ └──────────┘  │
│         ┌────────────────────────────┐          │
│         │     OrderCard / DepthBar   │          │
│         └────────────────────────────┘          │
├──────────────────────────────────────────────────┤
│  C++ Backend                                     │
│  ┌──────────────────────────────────────────────┐│
│  │  ClientWorker                                ││
│  │  ├─ Socket abstraction (cross-platform)     ││
│  │  ├─ Recv thread (std::thread + signals)     ││
│  │  ├─ Pending order queue                     ││
│  │  └─ Order persistence (JSON file)           ││
│  └──────────────────────────────────────────────┘│
├──────────────────────────────────────────────────┤
│  Protocol Layer                                  │
│  ┌──────────────────────────────────────────────┐│
│  │  BinaryCommand (32B) / BinaryResponse (48B) ││
│  │  Commands: NEW · CANCEL · BOOK              ││
│  │  Responses: OK · FILLED · TRADE · ERROR ·   ││
│  │            CANCELLED · BOOK · CLOSE         ││
│  └──────────────────────────────────────────────┘│
└──────────────────────────────────────────────────┘
```

### Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| **`std::thread` for recv loop** | QThread + event loop would block on blocking I/O; dedicated thread with Qt queued signals is minimal and correct |
| **`qRegisterMetaType` for cross-thread signals** | `uint32_t`/`uint64_t` are not registered by default; without this, Qt cannot queue them across threads |
| **Fusion style** | Only style that allows full customization of all controls (background, indicator, contentItem) |
| **Frameless + `startSystemMove()`** | Delegates window drag to OS for smooth snapping, multi-monitor, and Wayland support |
| **Inline QML for Theme singleton** | Avoids Qt 6.2 file-based singleton loading race; `qmlRegisterSingletonInstance` with inlined QmlObject |
| **Pending order queue** | Server only returns `order_id` in RSP_OK without echoing side/price/qty; FIFO queue correlates sends with acks |

---

## Build

### Prerequisites

| Platform | Qt 6 | Compiler | CMake |
|----------|------|----------|-------|
| Windows (MSYS2) | `mingw-w64-x86_64-qt6-base` + `mingw-w64-x86_64-qt6-declarative` (6.9) | MSYS2 MinGW g++ ≥ 13 | ≥ 3.22 |
| Linux (Ubuntu 22.04) | `qt6-base-dev` + `qt6-declarative-dev` (6.2+) | g++ ≥ 11 | ≥ 3.22 |

### Quick Start

```bash
git clone https://github.com/yourusername/NebulaX-Desk.git
cd NebulaX-Desk
bash scripts/build.sh
```

The binary is at `build/nebulaX-desk` (or `build/nebulaX-desk.exe` on Windows).

### Manual Build

```bash
cmake -S . -B build -G "Unix Makefiles"
cmake --build build
```

### Platform Notes

See [scripts/BUILD.md](scripts/BUILD.md) for cross-platform workarounds (MSYS2 TMP path, .bat path patch, QML cache).

---

## Usage

1. **Launch** the application
2. **Connect** — enter server host:port (default: `192.168.1.13:2250`) on the Connection page
3. **Place orders** — select Buy/Sell, enter price, quantity, and user ID on the Order page
4. **View market data** — the Market page shows the order book with depth visualization
5. **Track orders** — the Order List page shows all orders with status filtering (ALL / OPEN / PARTIAL / FILLED / CANCELLED)
6. **Multi-select** — long-press an order card or click Select to enter multi-select mode for batch cancellation

---

## Protocol

### Command Format (32 bytes)

```
Offset  Size  Field       Description
─────────────────────────────────────
  0      1     type       CMD_NEW (0x01) / CMD_CANCEL (0x02) / CMD_BOOK (0x03)
  1      1     side       SIDE_BUY (0x01) / SIDE_SELL (0x02) — NEW only
  2-3    2     _pad
  4-7    4     price      price × 100 (NEW only)
  8-11   4     quantity   (NEW only)
 16-23   8     user_id    (NEW, CANCEL)
 24-31   8     order_id   (CANCEL only)
 ```

### Response Format (48 bytes)

See [include/protocol.h](include/protocol.h) for the complete definition.

---

## Project Structure

```
NebulaX-Desk/
├── CMakeLists.txt          # Build configuration
├── docs/                   # Design documents
│   ├── DESIGN.md
│   └── PROMPT.md
├── include/
│   └── protocol.h          # Binary protocol definitions
├── qml/
│   ├── Main.qml            # Application root (frameless window + sidebar)
│   ├── components/
│   │   ├── DepthBar.qml    # Order book depth bar with shimmer effect
│   │   └── OrderCard.qml   # Order entry card with status + progress
│   └── pages/
│       ├── ConnectionPage.qml
│       ├── MarketPage.qml
│       ├── OrderListPage.qml
│       └── OrderPage.qml
├── scripts/
│   ├── BUILD.md            # Build instructions
│   └── build.sh            # Build script
├── src/
│   ├── main.cpp            # Entry point + Theme singleton registration
│   ├── ClientWorker.h      # Socket abstraction + ClientWorker class
│   └── ClientWorker.cpp    # Networking + persistence implementation
```

---

## Technology Stack

- **Language**: C++17, QML (Qt Quick)
- **UI Framework**: Qt 6.2+ (Qt Quick Controls 2 Fusion style)
- **Build System**: CMake 3.16+ with `qt_add_qml_module`
- **Networking**: Raw TCP sockets (Winsock2 / POSIX), abstracted via inline functions
- **Threading**: `std::thread` for I/O, `QObject` signals for cross-thread communication
- **Persistence**: JSON file via `QJsonDocument`

---

## License

MIT
