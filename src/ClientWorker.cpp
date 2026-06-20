#include "ClientWorker.h"
#include "protocol.h"

#include <cstring>
#include <QMetaType>

ClientWorker::ClientWorker(QObject* parent)
    : QObject(parent)
{
    qRegisterMetaType<uint32_t>("uint32_t");
    qRegisterMetaType<uint64_t>("uint64_t");
    qRegisterMetaType<uint16_t>("uint16_t");
}

ClientWorker::~ClientWorker()
{
    disconnect();
}

bool ClientWorker::connectToHost(const QString& host, int port)
{
    disconnect();

    net_init();

    socket_t fd = ::socket(AF_INET, SOCK_STREAM, 0);
    if (fd == kInvalidSocket)
        return false;

    struct sockaddr_in addr{};
    addr.sin_family = AF_INET;
    addr.sin_port = htons(static_cast<uint16_t>(port));
    if (::inet_pton(AF_INET, host.toUtf8().constData(), &addr.sin_addr) <= 0) {
        closeSocket(fd);
        return false;
    }

    if (::connect(fd, reinterpret_cast<struct sockaddr*>(&addr), sizeof(addr)) < 0) {
        closeSocket(fd);
        return false;
    }

    // SO_KEEPALIVE
    int optval = 1;
    net_setsockopt(fd, SOL_SOCKET, SO_KEEPALIVE, &optval, sizeof(optval));

#ifdef Q_OS_WIN
    // Windows: Vista+ keepalive via WSAIoctl
    tcp_keepalive ka{};
    ka.onoff = 1;
    ka.keepalivetime = 5000;
    ka.keepaliveinterval = 1000;
    DWORD bytes = 0;
    WSAIoctl(fd, SIO_KEEPALIVE_VALS, &ka, sizeof(ka),
             nullptr, 0, &bytes, nullptr, nullptr);
#else
    {
        int idle = 5;
        int interval = 1;
        int count = 3;
        net_setsockopt(fd, IPPROTO_TCP, TCP_KEEPIDLE, &idle, sizeof(idle));
        net_setsockopt(fd, IPPROTO_TCP, TCP_KEEPINTVL, &interval, sizeof(interval));
        net_setsockopt(fd, IPPROTO_TCP, TCP_KEEPCNT, &count, sizeof(count));
    }
#endif

    // Receive timeout 5s
    net_set_rcvtimeo(fd, 5);

    fd_.store(fd, std::memory_order_release);
    running_ = true;
    recvThread_ = std::thread(&ClientWorker::recvLoop, this);

    emit connectedChanged();
    return true;
}

void ClientWorker::disconnect()
{
    std::lock_guard lock(disconnectMutex_);

    socket_t fd = fd_.exchange(kInvalidSocket, std::memory_order_acq_rel);
    if (fd == kInvalidSocket)
        return;

    running_ = false;
    closeSocket(fd);

    if (recvThread_.joinable())
        recvThread_.join();

    {
        std::lock_guard pl(pendingMutex_);
        while (!pending_.empty())
            pending_.pop();
    }

    emit connectedChanged();
}

void ClientWorker::sendNewOrder(int side, uint32_t price, uint32_t qty, uint64_t uid)
{
    socket_t fd = fd_.load(std::memory_order_acquire);
    if (fd == kInvalidSocket)
        return;

    BinaryCommand cmd{};
    cmd.type = CMD_NEW;
    cmd.side = static_cast<uint8_t>(side);
    cmd.price = price;
    cmd.quantity = qty;
    cmd.user_id = uid;

    {
        std::lock_guard pl(pendingMutex_);
        pending_.push({side, price, qty, uid});
    }

    if (net_send(fd, &cmd, (int)sizeof(cmd), 0) <= 0)
        disconnect();
}

void ClientWorker::sendCancel(uint64_t order_id, uint64_t uid)
{
    socket_t fd = fd_.load(std::memory_order_acquire);
    if (fd == kInvalidSocket)
        return;

    BinaryCommand cmd{};
    cmd.type = CMD_CANCEL;
    cmd.order_id = order_id;
    cmd.user_id = uid;

    if (net_send(fd, &cmd, (int)sizeof(cmd), 0) <= 0)
        disconnect();
}

void ClientWorker::sendBookQuery()
{
    socket_t fd = fd_.load(std::memory_order_acquire);
    if (fd == kInvalidSocket)
        return;

    BinaryCommand cmd{};
    cmd.type = CMD_BOOK;

    if (net_send(fd, &cmd, (int)sizeof(cmd), 0) <= 0)
        disconnect();
}

void ClientWorker::recvLoop()
{
    BinaryResponse rsp{};

    while (running_) {
        socket_t fd = fd_.load(std::memory_order_relaxed);
        if (fd == kInvalidSocket)
            break;

        int ret = net_recv_all(fd, &rsp, sizeof(rsp));
        if (ret <= 0) {
            if (ret == 0) {
                QMetaObject::invokeMethod(this, "disconnect", Qt::QueuedConnection);
            } else if (net_is_timeout()) {
                continue;
            }
            break;
        }

        switch (rsp.type) {
        case RSP_OK: {
            PendingOrder po{};
            {
                std::lock_guard pl(pendingMutex_);
                if (!pending_.empty()) {
                    po = pending_.front();
                    pending_.pop();
                }
            }
            emit orderAck(rsp.data.ack.order_id, po.side, po.price, po.qty, po.uid);
            break;
        }
        case RSP_FILLED: {
            // Immediate fill: no RSP_OK preceded, pop pending for order details
            PendingOrder po{};
            bool hadPending = false;
            {
                std::lock_guard pl(pendingMutex_);
                if (!pending_.empty()) {
                    po = pending_.front();
                    pending_.pop();
                    hadPending = true;
                }
            }
            if (hadPending)
                emit orderAck(rsp.data.ack.order_id, po.side, po.price, po.qty, po.uid);
            emit orderFilled(rsp.data.ack.order_id);
            break;
        }
        case RSP_TRADE:
            emit tradeExecuted(rsp.data.trade.price, rsp.data.trade.quantity,
                               rsp.data.trade.buy_order_id, rsp.data.trade.sell_order_id);
            break;
        case RSP_CANCELLED:
            emit cancelAck(rsp.data.ack.order_id);
            break;
        case RSP_ERROR: {
            {
                std::lock_guard pl(pendingMutex_);
                if (!pending_.empty())
                    pending_.pop();
            }
            emit errorReceived(rsp.data.error.code);
            break;
        }
        case RSP_BOOK:
            emit bookUpdated(rsp.data.book.bid_price, rsp.data.book.bid_volume,
                             rsp.data.book.ask_price, rsp.data.book.ask_volume);
            break;
        case RSP_CLOSE:
            QMetaObject::invokeMethod(this, "disconnect", Qt::QueuedConnection);
            return;
        default:
            break;
        }
    }
}
