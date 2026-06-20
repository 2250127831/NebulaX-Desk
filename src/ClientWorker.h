#pragma once

#include <QObject>
#include <QString>
#include <atomic>
#include <cstdint>
#include <thread>
#include <mutex>
#include <queue>

// ── Platform-abstracted socket API (unchanged) ──
#ifdef Q_OS_WIN
  #define WIN32_LEAN_AND_MEAN
  #include <winsock2.h>
  #include <ws2tcpip.h>
  using socket_t = SOCKET;
  constexpr socket_t kInvalidSocket = INVALID_SOCKET;
  inline void closeSocket(socket_t s) { closesocket(s); }
  inline void net_shutdown(socket_t s) { ::shutdown(s, SD_BOTH); }
  inline int net_init()   { WSADATA d; return WSAStartup(MAKEWORD(2,2), &d); }
  inline int net_cleanup() { return WSACleanup(); }
  inline int net_send(socket_t s, const void* b, int l, int f)
      { return ::send(s, (const char*)b, l, f); }
  inline int net_recv(socket_t s, void* b, int l, int f)
      { return ::recv(s, (char*)b, l, f); }
  inline int net_setsockopt(socket_t s, int l, int o, const void* v, int n)
      { return ::setsockopt(s, l, o, (const char*)v, n); }
  inline int net_recv_all(socket_t s, void* buf, int len) {
      auto p = (char*)buf; int remained = len;
      while (remained > 0) { int r = ::recv(s, p, remained, 0); if (r <= 0) return r; p += r; remained -= r; }
      return len;
  }
  inline int net_set_rcvtimeo(socket_t s, int sec) {
      DWORD ms = sec * 1000U; return ::setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, (const char*)&ms, sizeof(ms));
  }
  inline bool net_is_timeout() { int e = WSAGetLastError(); return e == WSAETIMEDOUT || e == WSAEWOULDBLOCK; }
#else
  #include <sys/socket.h>
  #include <netinet/in.h>
  #include <netinet/tcp.h>
  #include <arpa/inet.h>
  #include <unistd.h>
  #include <cerrno>
  using socket_t = int;
  constexpr socket_t kInvalidSocket = -1;
  inline void closeSocket(socket_t s) { ::close(s); }
  inline void net_shutdown(socket_t s) { ::shutdown(s, SHUT_RDWR); }
  inline int net_init()   { return 0; }
  inline int net_cleanup() { return 0; }
  inline int net_send(socket_t s, const void* b, int l, int f) { return (int)::send(s, b, (size_t)l, f); }
  inline int net_recv(socket_t s, void* b, int l, int f) { return (int)::recv(s, b, (size_t)l, f); }
  inline int net_setsockopt(socket_t s, int l, int o, const void* v, int n)
      { return ::setsockopt(s, l, o, v, (socklen_t)n); }
  inline int net_recv_all(socket_t s, void* buf, int len) {
      auto p = (char*)buf; int remained = len;
      while (remained > 0) { int r = (int)::recv(s, p, (size_t)remained, 0); if (r <= 0) return r; p += r; remained -= r; }
      return len;
  }
  inline int net_set_rcvtimeo(socket_t s, int sec) {
      struct timeval tv = {sec, 0}; return ::setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));
  }
  inline bool net_is_timeout() { return errno == EAGAIN || errno == EWOULDBLOCK; }
#endif

class ClientWorker : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)

public:
    explicit ClientWorker(QObject* parent = nullptr);
    ~ClientWorker();

    bool connected() const { return fd_.load(std::memory_order_acquire) != kInvalidSocket; }

    Q_INVOKABLE bool connectToHost(const QString& host, int port);
    Q_INVOKABLE void disconnect();
    Q_INVOKABLE void sendNewOrder(int side, uint32_t price, uint32_t qty, uint64_t uid);
    Q_INVOKABLE void sendCancel(uint64_t order_id, uint64_t uid);
    Q_INVOKABLE void sendBookQuery();

    // Order persistence
    Q_INVOKABLE void persistOrder(uint64_t orderId, int side, uint32_t price,
                                   uint32_t qty, uint64_t uid,
                                   const QString& status, const QString& timeStr);
    Q_INVOKABLE void updateOrderStatus(uint64_t orderId, const QString& status);
    Q_INVOKABLE void loadPersistedOrders();
    Q_INVOKABLE void clearPersistedOrders();

signals:
    void connectedChanged();
    void orderAck(uint64_t order_id, int side, uint32_t price, uint32_t qty, uint64_t uid);
    void orderFilled(uint64_t order_id);
    void tradeExecuted(uint64_t price, uint32_t qty,
                       uint64_t buy_order_id, uint64_t sell_order_id);
    void cancelAck(uint64_t order_id);
    void errorReceived(uint16_t code);
    void bookUpdated(uint32_t bid_price, uint32_t bid_vol,
                     uint32_t ask_price, uint32_t ask_vol);
    void orderLoaded(uint64_t orderId, int side, uint32_t price,
                     uint32_t qty, uint64_t uid,
                     const QString& status, const QString& timeStr);

private:
    struct PendingOrder {
        int side; uint32_t price; uint32_t qty; uint64_t uid;
    };

    QString ordersFilePath() const;
    void recvLoop();

    std::atomic<socket_t> fd_{kInvalidSocket};
    std::atomic<bool> running_{false};
    std::thread recvThread_;
    std::mutex disconnectMutex_;

    std::queue<PendingOrder> pending_;
    std::mutex pendingMutex_;
};
