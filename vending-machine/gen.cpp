#include <cstdlib>
#include <iostream>
#include <random>
using namespace std;

int main(int argc, char* argv[]) {
    // 用法:
    //   ./gen [N] [seed]
    // 例:
    //   ./gen 100 42
    //
    // 輸出 N 行測資
    // 每行格式:
    //   reset coinInNTD_50 coinInNTD_10 coinInNTD_5 coinInNTD_1 itemTypeIn

    int          N    = 50;
    unsigned int seed = 712271227;

    if (argc >= 2) N = atoi(argv[1]);
    if (argc >= 3) seed = static_cast<unsigned int>(atoi(argv[2]));

    mt19937 rng(seed);

    uniform_int_distribution<int> reset_dist(0, 19);  // 約 1/20 機率 reset
    uniform_int_distribution<int> item_dist(0, 3);    // 0~3
    uniform_int_distribution<int> coin_dist(0, 3);    // 每種 coin 0~3 枚

    for (int i = 0; i < N; i++) {
        int reset = (reset_dist(rng) == 0) ? 1 : 0;

        int itemTypeIn;
        int coinInNTD_1;
        int coinInNTD_5;
        int coinInNTD_10;
        int coinInNTD_50;

        if (reset) {
            // reset 這拍通常不送 request，比較乾淨
            itemTypeIn   = 0;
            coinInNTD_1  = 0;
            coinInNTD_5  = 0;
            coinInNTD_10 = 0;
            coinInNTD_50 = 0;
        } else {
            itemTypeIn   = item_dist(rng);
            coinInNTD_1  = coin_dist(rng);
            coinInNTD_5  = coin_dist(rng);
            coinInNTD_10 = coin_dist(rng);
            coinInNTD_50 = coin_dist(rng);

            // 如果沒有選商品，通常也不投錢，比較像真實使用情境
            if (itemTypeIn == 0) {
                coinInNTD_1  = 0;
                coinInNTD_5  = 0;
                coinInNTD_10 = 0;
                coinInNTD_50 = 0;
            }
        }

        cout << reset << ' ' << coinInNTD_50 << ' ' << coinInNTD_10 << ' '
             << coinInNTD_5 << ' ' << coinInNTD_1 << ' ' << itemTypeIn << '\n';
    }

    return 0;
}