#include "ClientWorker.h"
#include "protocol.h"
#include <QCoreApplication>
#include <QDebug>
#include <QTimer>
#include <cstdio>

static const char* rspName(uint8_t t) {
    switch (t) {
    case RSP_TRADE:     return "RSP_TRADE";
    case RSP_OK:        return "RSP_OK";
    case RSP_FILLED:    return "RSP_FILLED";
    case RSP_CANCELLED: return "RSP_CANCELLED";
    case RSP_ERROR:     return "RSP_ERROR";
    case RSP_BOOK:      return "RSP_BOOK";
    case RSP_CLOSE:     return "RSP_CLOSE";
    default:            return "UNKNOWN";
    }
}

static const char* sideName(int s) {
    return s == SIDE_BUY ? "BUY" : "SELL";
}

int main(int argc, char* argv[])
{
    QCoreApplication app(argc, argv);

    int bookCount = 0, ackCount = 0, tradeCount = 0;
    int fillCount = 0, cancelCount = 0, errCount = 0;

    ClientWorker worker;

    QObject::connect(&worker, &ClientWorker::connectedChanged, [&]() {
        printf("\n=== CONNECTED = %d ===\n", worker.connected());
        if (worker.connected()) {
            printf("--- Phase 1: query book ---\n");
            worker.sendBookQuery();
        }
    });

    QObject::connect(&worker, &ClientWorker::bookUpdated, [&](uint32_t bp, uint32_t bv, uint32_t ap, uint32_t av) {
        bookCount++;
        printf("\n--- BOOK #%d ---\n", bookCount);
        printf("  bid_price=%u  bid_vol=%u\n", bp, bv);
        printf("  ask_price=%u  ask_vol=%u\n", ap, av);
        if (ap && bp) printf("  spread=%d\n", (int)(ap - bp));
        printf("  (raw bytes: type=RSP_BOOK bid_p=%u bid_v=%u ask_p=%u ask_v=%u)\n", bp, bv, ap, av);

        if (bookCount == 1) {
            printf("\n--- Phase 2: send BUY price=200 qty=50 uid=9999 ---\n");
            worker.sendNewOrder(SIDE_BUY, 200, 50, 9999);
            printf("--- Phase 2: send SELL price=100 qty=30 uid=9999 ---\n");
            worker.sendNewOrder(SIDE_SELL, 100, 30, 9999);
        } else if (bookCount == 2) {
            printf("\n--- Final book after trades ---\n");
        }
    });

    QObject::connect(&worker, &ClientWorker::orderAck, [&](uint64_t id, int side, uint32_t price, uint32_t qty, uint64_t uid) {
        ackCount++;
        printf("\n--- ORDER ACK #%d ---\n", ackCount);
        printf("  order_id=%llu  side=%s  price=%u  qty=%u  uid=%llu\n",
               (unsigned long long)id, sideName(side), price, qty, (unsigned long long)uid);
        if (ackCount == 1) {
            printf("--- Cancelling order %llu with uid=%llu ---\n",
                   (unsigned long long)id, (unsigned long long)uid);
            worker.sendCancel(id, uid);
        }
    });

    QObject::connect(&worker, &ClientWorker::orderFilled, [&](uint64_t id) {
        fillCount++;
        printf("\n--- FILLED #%d order_id=%llu ---\n", fillCount, (unsigned long long)id);
    });

    QObject::connect(&worker, &ClientWorker::tradeExecuted, [&](uint64_t price, uint32_t qty, uint64_t buyId, uint64_t sellId) {
        tradeCount++;
        printf("\n--- TRADE #%d ---\n", tradeCount);
        printf("  price=%llu  qty=%u\n", (unsigned long long)price, qty);
        printf("  buy_order_id=%llu  sell_order_id=%llu\n",
               (unsigned long long)buyId, (unsigned long long)sellId);
    });

    QObject::connect(&worker, &ClientWorker::cancelAck, [&](uint64_t id) {
        cancelCount++;
        printf("\n--- CANCEL ACK #%d order_id=%llu ---\n", cancelCount, (unsigned long long)id);
    });

    QObject::connect(&worker, &ClientWorker::errorReceived, [&](uint16_t code) {
        errCount++;
        printf("\n--- ERROR #%d code=%u ---\n", errCount, code);
    });

    // Phase 3: re-query after 3s
    QTimer::singleShot(3000, [&]() {
        printf("\n--- Phase 3: re-query book ---\n");
        worker.sendBookQuery();
    });

    // Summary after 6s
    QTimer::singleShot(6000, [&]() {
        printf("\n========== SUMMARY ==========\n");
        printf("  book updates:  %d\n", bookCount);
        printf("  order acks:    %d\n", ackCount);
        printf("  trades:        %d\n", tradeCount);
        printf("  fills:         %d\n", fillCount);
        printf("  cancels:       %d\n", cancelCount);
        printf("  errors:        %d\n", errCount);
        printf("=============================\n");
        worker.disconnect();
        QCoreApplication::quit();
    });

    printf("Connecting to 127.0.0.1:2250...\n");
    bool ok = worker.connectToHost("127.0.0.1", 2250);
    printf("connectToHost returned: %d\n", ok);

    return app.exec();
}
