# NebulaX Client — 下单客户端设计

## 架构

```
UI 线程 (QML)          Worker 线程 (C++ QObject)
  │                        │
  │  emit send(cmd)  ─────→│  socket write (非阻塞)
  │                        │
  │  ←── signal ──────────│  recv 循环:
  │  orderAck/rsp          │    recv(fd, buf, 48, MSG_WAITALL)
  │  tradeExecuted         │    → 超时 5s（SO_RCVTIMEO）
  │  bookUpdated           │    → 收到数据 → emit signal
  │  disconnected          │    → 断连 → emit disconnected
  │                        │
  │  ←── signal ──────────│  TCP keepalive 自动检测死连接
```

### 关键设计决策

| 决策 | 方案 |
|------|------|
| 收/发分离 | Worker 线程 `recv` 循环独立运行，发命令由 UI 调用 `send()` 写入 socket（Qt 信号跨线程） |
| recv 阻塞 | 设 `SO_RCVTIMEO = 5s`，超时返回 EAGAIN 继续循环；ECONNRESET 则断连。不设超时的话 recv 永久阻塞，连接断了也无法感知 |
| 断连检测 | `recv` 返回 0（服务端关连接）或 ECONNRESET → emit disconnected |
| TCP keepalive | 客户端 `setsockopt SO_KEEPALIVE, TCP_KEEPIDLE=10, KEEPINTVL=5, KEEPCNT=3`，服务端已配了同样的参数 |
| 跨线程通信 | Qt `QObject::connect` + signal/slot（Worker 线程 emit，UI 线程自动接收） |

### Worker 类设计

```cpp
class ClientWorker : public QObject {
    Q_OBJECT
public:
    Q_INVOKABLE bool connectToHost(QString host, int port);
    Q_INVOKABLE void disconnect();
    Q_INVOKABLE void sendNewOrder(int side, uint32_t price, uint32_t qty, uint64_t uid);
    Q_INVOKABLE void sendCancel(uint64_t order_id, uint64_t uid);
    Q_INVOKABLE void sendBookQuery();

signals:
    void connected();
    void disconnected();
    void orderAck(uint64_t order_id);
    void orderFilled(uint64_t order_id);
    void tradeExecuted(uint64_t price, uint32_t qty, uint64_t buy_id, uint64_t sell_id);
    void cancelAck(uint64_t order_id);
    void errorReceived(uint16_t code);
    void bookUpdated(uint32_t bid_price, uint32_t bid_vol, uint32_t ask_price, uint32_t ask_vol);

private:
    void recvLoop();
    int fd_ = -1;
    std::atomic<bool> running_{false};
};
```

---

## 页面设计

底部 TabBar 导航，4 页。左上角全局连接指示灯（🟢/🔴）。

### 页面切换

```
┌──────────────────────────────────────┐
│ [🟢]    下单    行情    订单列表      │ ← TabBar
└──────────────────────────────────────┘
```

### 1. 连接页

```
┌──────────────────────────────────┐
│ 连接设置                          │
│ 主机    127.0.0.1                │
│ 端口    2250                     │
│          🟢 已连接               │
│ [ 连接 ] [ 断开 ]                │
├──────────────────────────────────┤
│ 连接记录                          │
│ 12:01:23  已连接到 127.0.0.1:2250│
│ 12:05:00  连接断开                │
└──────────────────────────────────┘
```

### 2. 下单页

```
┌──────────────────────────────────┐
│ 下单                              │
│ Side    ◉ Buy  ○ Sell            │
│ Price         [ 12345       ]    │
│ Quantity      [ 100         ]    │
│ User ID       [ 42          ]    │
│                                  │
│ [ 发送 ]  [ 批量买 x1000 ]       │
│           [ 批量卖 x1000 ]       │
├──────────────────────────────────┤
│ 响应日志                          │
│ 12:01:23  NEW 12345 x100  → OK   │
│ 12:01:24  NEW 12350 x100  → FILL │
└──────────────────────────────────┘
```

### 3. 行情页

当前 CMD_BOOK 只返回 best bid/ask。

```
┌──────────────────────────────────┐
│ 行情                              │
│                                  │
│ 卖一   12330    700              │
│ ─────────────────────────────── │
│ 买一   12320    400              │
│                                  │
│ 价差   10                        │
│ [ 刷新 ]  [ 自动刷新 2s ]        │
└──────────────────────────────────┘
```

### 4. 订单列表页

**订单卡片列表**，每行显示一个订单，卡片本身可点击响应。

#### 普通模式（默认）

```
┌──────────────────────────────────────┐
│ [批量撤选择]         [☐] 多选       │ ← 顶部栏
│                                      │
│ ┌ 1001  BUY  12345  x100  OPEN     ┐ │
│ │ 12:01:23                        │ │
│ └──────────────────────────────────┘ │
│ ┌ 1002  SELL 12340  x200  OPEN     ┐ │
│ │ 12:01:24                        │ │ ← 右键弹出菜单
│ └──────────────────────────────────┘ │    ┌──────────┐
│ ┌ 1003  BUY  12350  x300  OPEN     ┐ │    │ 撤单     │
│ │ 12:01:25                        │ │    │ 复制 ID  │
│ └──────────────────────────────────┘ │    └──────────┘
│ ────────────────────────────────── │
│ ┌ 1004  BUY  12400  x100  FILLED   ┐ │
│ │ 12:01:26                        │ │
│ └──────────────────────────────────┘ │
│ ┌ 1005  SELL 12200  x100  CANCELLED┐ │
│ │ 12:01:27                        │ │
│ └──────────────────────────────────┘ │
│                                      │
│ 共 5 笔        3 笔活跃              │
└──────────────────────────────────────┘
```

- **右键**（活跃订单）：弹出菜单，显示"撤单"和"复制 ID"
- **右键**（已结束订单）：只显示"复制 ID"
- **左键单击**：暂不响应，或显示详情

#### 多选模式

顶部 **多选按钮** 切换，或者**长按某个卡片**触发多选模式：

```
┌──────────────────────────────────────┐
│ [批量撤单 (2)]      [☑] 取消多选    │ ← 多选模式下顶部栏变化
│                                      │
│ ┌ ○ 1001  BUY  12345  x100  OPEN   ┐ │
│ │ 12:01:23                        │ │
│ └──────────────────────────────────┘ │
│ ┌ ● 1002  SELL 12340  x200  OPEN   ┐ │ ← 已勾选
│ │ 12:01:24                        │ │
│ └──────────────────────────────────┘ │
│ ┌ ● 1003  BUY  12350  x300  OPEN   ┐ │ ← 已勾选
│ │ 12:01:25                        │ │
│ └──────────────────────────────────┘ │
│ ────────────────────────────────── │
│ ┌ □ 1004  BUY  12400  x100  FILLED ┐ │ ← 已结束，不可选（灰色）
│ │ 12:01:26                        │ │
│ └──────────────────────────────────┘ │
│                                      │
│ 共 5 笔        已选 2 笔             │
└──────────────────────────────────────┘
```

#### 交互逻辑

| 操作 | 普通模式 | 多选模式 |
|------|----------|----------|
| 左键点击卡片 | 无操作 | 切换勾选/取消 |
| 右键卡片 | 弹出菜单（撤单/复制ID） | 弹出菜单 |
| 长按卡片 | 切换到多选模式，该卡片勾选 | 切换勾选 |
| 点击顶部多选按钮 | 切换到多选模式 | 切回普通模式 |

多选模式下仅活跃订单（OPEN/PARTIALLY_FILLED）可勾选，已结束订单显示灰色不可选。

---

## 导航结构

```qml
Window {
    TabBar {
        id: nav
        TabButton { text: "连接" }
        TabButton { text: "下单" }
        TabButton { text: "行情" }
        TabButton { text: "订单列表" }
    }
    StackLayout {
        currentIndex: nav.currentIndex
        ConnectionPage { worker: clientWorker }
        OrderPage { worker: clientWorker }
        MarketPage { worker: clientWorker }
        OrderListPage {
            worker: clientWorker
            orders: orderModel   // ListModel，由响应更新
        }
    }
}
```

---

## 订单列表维护（本地）

Worker 收到响应后 emit signal，UI 层更新 `orderModel`：

| 信号 | 操作 |
|------|------|
| `orderAck(order_id, side, price, qty)` | 新增到列表，status=OPEN |
| `orderFilled(order_id)` | 更新 status=FILLED |
| `tradeExecuted(price, qty, buy_id, sell_id)` | buy_id 或 sell_id 在列表中 → 更新 status=FILLED |
| `cancelAck(order_id)` | 更新 status=CANCELLED |
| `errorReceived(code, order_id?)` | 可选的错误记录 |
| `disconnected()` | 清空列表 |

```qml
ListModel {
    ListElement {
        orderId: 1001; side: "BUY"; price: 12345
        qty: 100; status: "OPEN"; time: "12:01:23"
    }
}
```

---

## 二进制协议学习

协议定义在 NebulaX 项目的 `/home/qiwang/NebulaX/include/protocol.h`，已拷贝到 `include/protocol.h`。

### 文件结构

```
protocol.h
├── 命令常量: CMD_NEW(0x01) / CMD_CANCEL(0x02) / CMD_BOOK(0x03)
├── 响应常量: RSP_TRADE(0x81) / RSP_OK(0x82) / RSP_FILLED(0x83)
│            RSP_CANCELLED(0x84) / RSP_ERROR(0x85) / RSP_BOOK(0x86)
│            RSP_HEADER(0x87) / RSP_CLOSE(0x88)
├── struct BinaryCommand (32 bytes, packed)
│   └── type / side / price / quantity / user_id / order_id
├── struct BinaryResponse (48 bytes, packed)
│   └── union {
│         trade: price/qty/buyer/seller/order_id
│         ack:   order_id
│         error: code
│         book:  bid_price/vol, ask_price/vol
│         header: client_fd/count/ack_ptr
│       }
├── ErrorCode 枚举
├── validateCommand(cmd) 函数
└── Side / OrderStatus 枚举
```

### 理解要点

1. **定长帧**：命令固定 32 字节，响应固定 48 字节，TCP 流按固定长度分割
2. **发送方式**：`send(fd, &cmd, 32, 0)` 一次写完整帧
3. **接收方式**：`recv(fd, &rsp, 48, MSG_WAITALL)` 一次读完整帧
4. **side 值**：`SIDE_BUY=0x01` / `SIDE_SELL=0x02`
5. **RSP_HEADER**：仅在服务端内部线程间使用（SPSC ring 发送批次头），客户端永远不会收到
6. **RSP_CLOSE**：服务端关闭连接前发的最后一条，客户端收到后应主动关闭连接

### 快速测试

```cpp
#include "protocol.h"

BinaryCommand cmd{};
cmd.type = CMD_NEW;
cmd.side = SIDE_BUY;
cmd.price = 12345;
cmd.quantity = 100;
cmd.user_id = 42;

send(fd, &cmd, sizeof(cmd), 0);

BinaryResponse rsp;
recv(fd, &rsp, sizeof(rsp), MSG_WAITALL);
// rsp.type == RSP_OK → success, rsp.data.ack.order_id
// rsp.type == RSP_ERROR → error, rsp.data.error.code
```

---

## 项目结构

```
NebulaX-Desk/
├── PROMPT.md                   # AI 接手提示词
├── DESIGN.md                   # 本设计文档
├── CMakeLists.txt              # Qt6 Qml, qt_add_qml_module
├── src/
│   ├── main.cpp                # qmlRegisterSingletonInstance<ClientWorker>
│   ├── ClientWorker.h           # QObject, 独立 recv 线程
│   └── ClientWorker.cpp
├── qml/
│   ├── Main.qml                # ApplicationWindow + TabBar + StackLayout
│   ├── pages/
│   │   ├── ConnectionPage.qml
│   │   ├── OrderPage.qml
│   │   ├── MarketPage.qml
│   │   └── OrderListPage.qml
│   ├── components/
│   │   ├── OrderCard.qml       # 订单卡片（右键菜单 + 多选模式 + 长按触发）
│   │   └── ...                 # 后续提取更多组件
│   └── assets/                 # 图标、静态资源
├── include/
│   └── protocol.h              # 从 /home/qiwang/NebulaX/include/ 拷贝
└── scripts/                    # 辅助脚本
```

---

## 注意事项

1. **协议头文件已拷贝到 `include/protocol.h`**，不要 `#include "../NebulaX/include/protocol.h"`
2. **先实现连接页和下单页**，再逐步加行情和订单列表
3. **`connectToHost()` 要在子线程调**
4. **`SO_RCVTIMEO = 5s`**，连接后 `setsockopt SO_KEEPALIVE`
5. **跨线程连接用 `Qt::QueuedConnection`**
6. **订单列表只反映本地视角**——断连重连后订单列表为空，在册订单不自动恢复（服务端有但客户端不知道 ID）
