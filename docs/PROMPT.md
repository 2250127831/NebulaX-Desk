你是 Qt/QML 桌面应用开发者，接下来要实现 NebulaX-Desk——一个通过 TCP 二进制协议连接 NebulaX 撮合引擎的下单客户端。

## 项目上下文

所有设计文档在 `DESIGN.md`，内容涵盖：

- 架构（独立 Worker 线程收/发分离，`Q_PROPERTY` + signal 驱动 UI）
- 页面设计（连接 / 下单 / 行情 / 订单列表，共 4 页，TabBar 导航）
- 二进制协议（`/home/qiwang/NebulaX/include/protocol.h`，已拷贝到 `include/protocol.h`）
- 订单列表维护（本地靠响应推断状态，`ListModel` 驱动）
- 交互（右键菜单、多选模式切换、长按触发多选）

## 要求

1. **先读 DESIGN.md，完全理解架构和页面设计再动手**
2. **设计讨论优先**——先对齐方案再写代码
3. **不修改 NebulaX 源码**，Desk 是独立进程
4. **充分利用 QML 现代特性**：`required` 属性、`Connections`、`Behavior` 动画、`StackLayout` 页面管理

## 目录结构

```
NebulaX-Desk/
├── PROMPT.md              # 本文件
├── DESIGN.md              # 设计文档
├── CMakeLists.txt         # Qt6, qt_add_qml_module, URI NebulaX.Desk
├── src/
│   ├── main.cpp           # qmlRegisterSingletonInstance<ClientWorker>
│   ├── ClientWorker.h     # QObject, 独立 recv 线程
│   └── ClientWorker.cpp
├── qml/
│   ├── Main.qml           # ApplicationWindow + TabBar + StackLayout
│   ├── pages/
│   │   ├── ConnectionPage.qml
│   │   ├── OrderPage.qml
│   │   ├── MarketPage.qml
│   │   └── OrderListPage.qml
│   ├── components/
│   │   └── OrderCard.qml
│   └── assets/
└── include/
    └── protocol.h
```

## QML 模块注册

`ClientWorker` 通过 `qmlRegisterSingletonInstance("NebulaX.Desk", 1, 0, "ClientWorker", &worker)` 注册为 QML 单例。

QML 中直接用 `ClientWorker.connected` / `ClientWorker.sendNewOrder(...)`。

## 启动 NebulaX 服务端（用于测试）

```bash
# 在 VM 上
taskset -c 6,7 ~/NebulaX/build/nebulaX 2250 --io-core 6 --send-core 7 &

# 测试
python3 ~/NebulaX/scripts/l2_replay.py 2250
```

## 协议速查

| 命令 | 值 | 发送 |
|------|----|------|
| CMD_NEW | 0x01 | `send(fd, &cmd, 32, 0)` |
| CMD_CANCEL | 0x02 | 同上 |
| CMD_BOOK | 0x03 | 同上 |

接收：`recv(fd, &rsp, 48, MSG_WAITALL)`，`SO_RCVTIMEO=5s`。

开始吧。
