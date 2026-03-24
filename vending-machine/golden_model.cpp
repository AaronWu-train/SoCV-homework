#include <algorithm>
#include <iostream>
using namespace std;

int main() {
    int status       = 1;  // 1: ON, 2: BUSY, 0: OFF
    int itemTypeIn   = 0;  // 0: no item, 1: ITEM_A, 2: ITEM_B, 3: ITEM_C
    int coinInNTD_1  = 0;  // number of 1 NTD coins
    int coinInNTD_5  = 0;  // number of 5 NTD coins
    int coinInNTD_10 = 0;  // number of 10 NTD coins
    int coinInNTD_50 = 0;  // number of 50 NTD coins
    int reset        = 0;

    int coinStoredNTD_1  = 2;  // number of 1 NTD coins stored in the machine
    int coinStoredNTD_5  = 2;  // number of 5 NTD coins stored in the machine
    int coinStoredNTD_10 = 2;  // number of 10 NTD coins stored in the machine
    int coinStoredNTD_50 = 2;  // number of 50 NTD coins stored in the machine

    int coinOutNTD_50 = 0;  // number of 50 NTD coins to be returned
    int coinOutNTD_10 = 0;  // number of 10 NTD coins to be returned
    int coinOutNTD_5  = 0;  // number of 5 NTD coins to be returned
    int coinOutNTD_1  = 0;  // number of 1 NTD coins to be returned
    int itemTypeOut   = 0;  // 0: no item, 1: ITEM_A, 2: ITEM_B, 3: ITEM_C

    while (cin >> reset) {
        cin >> coinInNTD_50 >> coinInNTD_10 >> coinInNTD_5 >> coinInNTD_1 >>
            itemTypeIn;
        if (reset == 1) {
            status           = 1;
            coinStoredNTD_1  = 2;
            coinStoredNTD_5  = 2;
            coinStoredNTD_10 = 2;
            coinStoredNTD_50 = 2;
            coinOutNTD_50    = 0;
            coinOutNTD_10    = 0;
            coinOutNTD_5     = 0;
            coinOutNTD_1     = 0;
            itemTypeOut      = 0;
        }
        if (status == 1) {
            cout << 0 << " " << 0 << " " << 0 << " " << 0 << " " << 0 << " "
                 << 1 << endl;
            if (reset == 1) continue;
        } else if (status == 2) {
            cout << 0 << " " << 0 << " " << 0 << " " << 0 << " " << 0 << " "
                 << 2 << endl;
            status = 0;
            continue;
        } else if (status == 0) {
            cout << coinOutNTD_50 << " " << coinOutNTD_10 << " " << coinOutNTD_5
                 << " " << coinOutNTD_1 << " " << itemTypeOut << " " << 0
                 << endl;
            coinOutNTD_1  = 0;
            coinOutNTD_5  = 0;
            coinOutNTD_10 = 0;
            coinOutNTD_50 = 0;
            itemTypeOut   = 0;
            status        = 1;
            continue;
        }

        if (status == 1 && itemTypeIn != 0) {
            status         = 2;
            int totalMoney = coinInNTD_1 * 1 + coinInNTD_5 * 5 +
                             coinInNTD_10 * 10 + coinInNTD_50 * 50;
            int itemPrice  = 0;
            if (itemTypeIn == 1) {
                itemPrice = 8;
            } else if (itemTypeIn == 2) {
                itemPrice = 15;
            } else if (itemTypeIn == 3) {
                itemPrice = 22;
            }

            if (totalMoney < itemPrice) {
                coinOutNTD_1  = coinInNTD_1;
                coinOutNTD_5  = coinInNTD_5;
                coinOutNTD_10 = coinInNTD_10;
                coinOutNTD_50 = coinInNTD_50;
                itemTypeOut   = 0;
            } else {
                coinStoredNTD_1 += coinInNTD_1;
                coinStoredNTD_5 += coinInNTD_5;
                coinStoredNTD_10 += coinInNTD_10;
                coinStoredNTD_50 += coinInNTD_50;

                coinStoredNTD_1  = min(coinStoredNTD_1, 7);
                coinStoredNTD_5  = min(coinStoredNTD_5, 7);
                coinStoredNTD_10 = min(coinStoredNTD_10, 7);
                coinStoredNTD_50 = min(coinStoredNTD_50, 7);

                int change    = totalMoney - itemPrice;
                coinOutNTD_50 = min(change / 50, coinStoredNTD_50);
                change -= coinOutNTD_50 * 50;
                coinOutNTD_10 = min(change / 10, coinStoredNTD_10);
                change -= coinOutNTD_10 * 10;
                coinOutNTD_5 = min(change / 5, coinStoredNTD_5);
                change -= coinOutNTD_5 * 5;
                coinOutNTD_1 = min(change, coinStoredNTD_1);
                change -= coinOutNTD_1;
                if (change == 0) {
                    itemTypeOut = itemTypeIn;
                    coinStoredNTD_1 -= coinOutNTD_1;
                    coinStoredNTD_5 -= coinOutNTD_5;
                    coinStoredNTD_10 -= coinOutNTD_10;
                    coinStoredNTD_50 -= coinOutNTD_50;
                } else {
                    // Not enough change, return all coins
                    coinOutNTD_1  = coinInNTD_1;
                    coinOutNTD_5  = coinInNTD_5;
                    coinOutNTD_10 = coinInNTD_10;
                    coinOutNTD_50 = coinInNTD_50;
                    coinStoredNTD_1 -= coinInNTD_1;
                    coinStoredNTD_5 -= coinInNTD_5;
                    coinStoredNTD_10 -= coinInNTD_10;
                    coinStoredNTD_50 -= coinInNTD_50;
                    itemTypeOut = 0;
                }
            }
        }
    }
}