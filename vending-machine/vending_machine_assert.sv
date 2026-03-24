module vending_machine_sva (
    input logic        clk,
    input logic        reset,

    input logic [1:0]  coinInNTD_50,
    input logic [1:0]  coinInNTD_10,
    input logic [1:0]  coinInNTD_5,
    input logic [1:0]  coinInNTD_1,
    input logic [1:0]  itemTypeIn,

    input logic [2:0]  coinOutNTD_50,
    input logic [2:0]  coinOutNTD_10,
    input logic [2:0]  coinOutNTD_5,
    input logic [2:0]  coinOutNTD_1,
    input logic [1:0]  itemTypeOut,
    input logic [1:0]  serviceTypeOut,

    input logic [1:0]  state,
    input logic [1:0]  next_state,

    input logic [2:0]  store50,
    input logic [2:0]  store10,
    input logic [2:0]  store5,
    input logic [2:0]  store1,
    input logic [2:0]  next_store50,
    input logic [2:0]  next_store10,
    input logic [2:0]  next_store5,
    input logic [2:0]  next_store1,

    input logic [1:0]  req_item,
    input logic [1:0]  next_req_item,
    input logic [1:0]  req_in50,
    input logic [1:0]  req_in10,
    input logic [1:0]  req_in5,
    input logic [1:0]  req_in1,
    input logic [1:0]  next_req_in50,
    input logic [1:0]  next_req_in10,
    input logic [1:0]  next_req_in5,
    input logic [1:0]  next_req_in1,

    input logic [1:0]  disp_item,
    input logic [1:0]  next_disp_item,
    input logic [2:0]  disp50,
    input logic [2:0]  disp10,
    input logic [2:0]  disp5,
    input logic [2:0]  disp1,
    input logic [2:0]  next_disp50,
    input logic [2:0]  next_disp10,
    input logic [2:0]  next_disp5,
    input logic [2:0]  next_disp1,

    input logic [7:0]  item_price,
    input logic [7:0]  inserted_value,
    input logic [7:0]  change_value,

    input logic [2:0]  avail50,
    input logic [2:0]  avail10,
    input logic [2:0]  avail5,
    input logic [2:0]  avail1,
    input logic [2:0]  use50,
    input logic [2:0]  use10,
    input logic [2:0]  use5,
    input logic [2:0]  use1,

    input logic        enough_money,
    input logic        success
);

    // 基本常數
    localparam [1:0] ITEM_NONE    = 2'd0;
    localparam [1:0] ITEM_A       = 2'd1;
    localparam [1:0] ITEM_B       = 2'd2;
    localparam [1:0] ITEM_C       = 2'd3;

    localparam [1:0] SERVICE_OFF  = 2'd0;
    localparam [1:0] SERVICE_ON   = 2'd1;
    localparam [1:0] SERVICE_BUSY = 2'd2;

    localparam [7:0] PRICE_A      = 8'd8;
    localparam [7:0] PRICE_B      = 8'd15;
    localparam [7:0] PRICE_C      = 8'd22;

    // 小工具：算輸入總額
    function automatic [7:0] in_value(
        input logic [1:0] c50,
        input logic [1:0] c10,
        input logic [1:0] c5,
        input logic [1:0] c1
    );
        in_value = c50 * 8'd50 + c10 * 8'd10 + c5 * 8'd5 + c1;
    endfunction

    // 小工具：算輸出總額
    function automatic [7:0] out_value(
        input logic [2:0] c50,
        input logic [2:0] c10,
        input logic [2:0] c5,
        input logic [2:0] c1
    );
        out_value = c50 * 8'd50 + c10 * 8'd10 + c5 * 8'd5 + c1;
    endfunction

    // 小工具：商品價格
    function automatic [7:0] price_of_item_sva(
        input logic [1:0] item
    );
        case (item)
            ITEM_A:   price_of_item_sva = PRICE_A;
            ITEM_B:   price_of_item_sva = PRICE_B;
            ITEM_C:   price_of_item_sva = PRICE_C;
            default:  price_of_item_sva = 8'd0;
        endcase
    endfunction

    // -------------------------
    // 合法值 / 範圍
    // -------------------------

    // assert property (@(posedge clk) state inside {SERVICE_OFF, SERVICE_ON, SERVICE_BUSY}); // state 合法
    // assert property (@(posedge clk) next_state inside {SERVICE_OFF, SERVICE_ON, SERVICE_BUSY}); // next_state 合法
    assert property (@(posedge clk) serviceTypeOut == state); // 輸出狀態等於內部 state
    // assert property (@(posedge clk) itemTypeOut inside {ITEM_NONE, ITEM_A, ITEM_B, ITEM_C}); // itemTypeOut 合法

    assert property (@(posedge clk) store50      <= 3'd7); // store50 上限
    assert property (@(posedge clk) store10      <= 3'd7); // store10 上限
    assert property (@(posedge clk) store5       <= 3'd7); // store5 上限
    assert property (@(posedge clk) store1       <= 3'd7); // store1 上限
    assert property (@(posedge clk) next_store50 <= 3'd7); // next_store50 上限
    assert property (@(posedge clk) next_store10 <= 3'd7); // next_store10 上限
    assert property (@(posedge clk) next_store5  <= 3'd7); // next_store5 上限
    assert property (@(posedge clk) next_store1  <= 3'd7); // next_store1 上限

    assert property (@(posedge clk) use50 <= avail50); // 找零不能超用 50
    assert property (@(posedge clk) use10 <= avail10); // 找零不能超用 10
    assert property (@(posedge clk) use5  <= avail5 ); // 找零不能超用 5
    assert property (@(posedge clk) use1  <= avail1 ); // 找零不能超用 1

    // -------------------------
    // reset
    // -------------------------

    assert property (@(posedge clk) reset |=> state    == SERVICE_ON); // reset 後回 ON
    assert property (@(posedge clk) reset |=> store50  == 3'd2); // reset 後 50 元存量 = 2
    assert property (@(posedge clk) reset |=> store10  == 3'd2); // reset 後 10 元存量 = 2
    assert property (@(posedge clk) reset |=> store5   == 3'd2); // reset 後 5 元存量 = 2
    assert property (@(posedge clk) reset |=> store1   == 3'd2); // reset 後 1 元存量 = 2
    assert property (@(posedge clk) reset |=> req_item == ITEM_NONE); // reset 後 request 清空
    assert property (@(posedge clk) reset |=> req_in50 == 2'd0); // reset 後 req_in50 清零
    assert property (@(posedge clk) reset |=> req_in10 == 2'd0); // reset 後 req_in10 清零
    assert property (@(posedge clk) reset |=> req_in5  == 2'd0); // reset 後 req_in5 清零
    assert property (@(posedge clk) reset |=> req_in1  == 2'd0); // reset 後 req_in1 清零
    assert property (@(posedge clk) reset |=> disp_item == ITEM_NONE); // reset 後輸出 item 清空
    assert property (@(posedge clk) reset |=> disp50 == 3'd0); // reset 後 disp50 清零
    assert property (@(posedge clk) reset |=> disp10 == 3'd0); // reset 後 disp10 清零
    assert property (@(posedge clk) reset |=> disp5  == 3'd0); // reset 後 disp5 清零
    assert property (@(posedge clk) reset |=> disp1  == 3'd0); // reset 後 disp1 清零

    // -------------------------
    // 輸出 gating
    // -------------------------

    assert property (@(posedge clk) disable iff (reset)
        (state != SERVICE_OFF) |-> (itemTypeOut == ITEM_NONE)); // 非 OFF 時不出 item

    assert property (@(posedge clk) disable iff (reset)
        (state != SERVICE_OFF) |-> (coinOutNTD_50 == 3'd0 &&
                                    coinOutNTD_10 == 3'd0 &&
                                    coinOutNTD_5  == 3'd0 &&
                                    coinOutNTD_1  == 3'd0)); // 非 OFF 時不出 change

    assert property (@(posedge clk) disable iff (reset)
        (state == SERVICE_OFF) |-> (itemTypeOut   == disp_item &&
                                    coinOutNTD_50 == disp50 &&
                                    coinOutNTD_10 == disp10 &&
                                    coinOutNTD_5  == disp5  &&
                                    coinOutNTD_1  == disp1)); // OFF 時輸出等於 latched result

    // -------------------------
    // datapath 一致性
    // -------------------------

    assert property (@(posedge clk) item_price == price_of_item_sva(req_item)); // 價格解碼正確

    assert property (@(posedge clk)
        inserted_value == in_value(req_in50, req_in10, req_in5, req_in1)); // 投幣總額正確

    assert property (@(posedge clk)
        enough_money == (inserted_value >= item_price)); // enough_money 定義正確

    assert property (@(posedge clk) success |-> enough_money); // success 一定先 enough_money

    assert property (@(posedge clk) disable iff (reset)
        success |-> (out_value(use50, use10, use5, use1) == change_value)); // success 時找零總額正確

    // -------------------------
    // SERVICE_ON
    // -------------------------

    assert property (@(posedge clk) disable iff (reset)
        (state == SERVICE_ON && itemTypeIn != ITEM_NONE) |=> (state == SERVICE_BUSY)); // ON 收到 request 後進 BUSY

    assert property (@(posedge clk) disable iff (reset)
        (state == SERVICE_ON && itemTypeIn != ITEM_NONE) |=> (req_item == $past(itemTypeIn))); // 接收 item

    assert property (@(posedge clk) disable iff (reset)
        (state == SERVICE_ON && itemTypeIn != ITEM_NONE) |=> (req_in50 == $past(coinInNTD_50))); // 接收 50 元數量

    assert property (@(posedge clk) disable iff (reset)
        (state == SERVICE_ON && itemTypeIn != ITEM_NONE) |=> (req_in10 == $past(coinInNTD_10))); // 接收 10 元數量

    assert property (@(posedge clk) disable iff (reset)
        (state == SERVICE_ON && itemTypeIn != ITEM_NONE) |=> (req_in5 == $past(coinInNTD_5))); // 接收 5 元數量

    assert property (@(posedge clk) disable iff (reset)
        (state == SERVICE_ON && itemTypeIn != ITEM_NONE) |=> (req_in1 == $past(coinInNTD_1))); // 接收 1 元數量

    assert property (@(posedge clk) disable iff (reset)
        (state == SERVICE_ON && itemTypeIn == ITEM_NONE) |=> (state == SERVICE_ON)); // ON 且無 request 時留在 ON

    // -------------------------
    // SERVICE_BUSY
    // -------------------------

    assert property (@(posedge clk) disable iff (reset)
        (state == SERVICE_BUSY) |=> (state == SERVICE_OFF)); // BUSY 下一拍進 OFF

    assert property (@(posedge clk) disable iff (reset)
        (state == SERVICE_BUSY && success) |=> (disp_item == $past(req_item))); // success 時輸出 item

    assert property (@(posedge clk) disable iff (reset)
        (state == SERVICE_BUSY && success) |=> (disp50 == $past(use50) &&
                                                disp10 == $past(use10) &&
                                                disp5  == $past(use5 ) &&
                                                disp1  == $past(use1 ))); // success 時輸出 change

    assert property (@(posedge clk) disable iff (reset)
        (state == SERVICE_BUSY && success) |=> (store50 == $past(avail50 - use50) &&
                                                store10 == $past(avail10 - use10) &&
                                                store5  == $past(avail5  - use5 ) &&
                                                store1  == $past(avail1  - use1 ))); // success 時更新存量

    assert property (@(posedge clk) disable iff (reset)
        (state == SERVICE_BUSY && !success) |=> (disp_item == ITEM_NONE)); // fail 時不出 item

    assert property (@(posedge clk) disable iff (reset)
        (state == SERVICE_BUSY && !success) |=> (disp50 == {1'b0, $past(req_in50)} &&
                                                 disp10 == {1'b0, $past(req_in10)} &&
                                                 disp5  == {1'b0, $past(req_in5 )} &&
                                                 disp1  == {1'b0, $past(req_in1 )})); // fail 時原幣退回

    assert property (@(posedge clk) disable iff (reset)
        (state == SERVICE_BUSY && !success) |=> (store50 == $past(store50) &&
                                                 store10 == $past(store10) &&
                                                 store5  == $past(store5 ) &&
                                                 store1  == $past(store1 ))); // fail 時不吃錢

    // -------------------------
    // SERVICE_OFF
    // -------------------------

    assert property (@(posedge clk) disable iff (reset)
        (state == SERVICE_OFF) |=> (state == SERVICE_ON)); // OFF 下一拍回 ON

    assert property (@(posedge clk) disable iff (reset)
        (state == SERVICE_OFF) |=> (req_item == ITEM_NONE)); // OFF 後清 request item

    assert property (@(posedge clk) disable iff (reset)
        (state == SERVICE_OFF) |=> (req_in50 == 2'd0 &&
                                    req_in10 == 2'd0 &&
                                    req_in5  == 2'd0 &&
                                    req_in1  == 2'd0)); // OFF 後清 request coins

    assert property (@(posedge clk) disable iff (reset)
        (state == SERVICE_OFF) |=> (disp_item == ITEM_NONE &&
                                    disp50 == 3'd0 &&
                                    disp10 == 3'd0 &&
                                    disp5  == 3'd0 &&
                                    disp1  == 3'd0)); // OFF 後清 display latch

    // -------------------------
    // 端對端結果
    // -------------------------

    assert property (@(posedge clk) disable iff (reset)
        (state == SERVICE_OFF && itemTypeOut == ITEM_NONE)
        |-> (out_value(coinOutNTD_50, coinOutNTD_10, coinOutNTD_5, coinOutNTD_1)
             == in_value(req_in50, req_in10, req_in5, req_in1))); // fail 時退幣總額 = 原投幣

    assert property (@(posedge clk) disable iff (reset)
        (state == SERVICE_OFF && itemTypeOut != ITEM_NONE)
        |-> (itemTypeOut == req_item)); // success 時輸出 item 正確

    assert property (@(posedge clk) disable iff (reset)
        (state == SERVICE_OFF && itemTypeOut != ITEM_NONE)
        |-> (out_value(coinOutNTD_50, coinOutNTD_10, coinOutNTD_5, coinOutNTD_1)
             == in_value(req_in50, req_in10, req_in5, req_in1) - price_of_item_sva(req_item))); // success 時找零總額正確

endmodule

// 直接 bind 到 DUT
bind vending_machine vending_machine_sva u_vending_machine_sva (
    .clk(clk),
    .reset(reset),

    .coinInNTD_50(coinInNTD_50),
    .coinInNTD_10(coinInNTD_10),
    .coinInNTD_5(coinInNTD_5),
    .coinInNTD_1(coinInNTD_1),
    .itemTypeIn(itemTypeIn),

    .coinOutNTD_50(coinOutNTD_50),
    .coinOutNTD_10(coinOutNTD_10),
    .coinOutNTD_5(coinOutNTD_5),
    .coinOutNTD_1(coinOutNTD_1),
    .itemTypeOut(itemTypeOut),
    .serviceTypeOut(serviceTypeOut),

    .state(state),
    .next_state(next_state),

    .store50(store50),
    .store10(store10),
    .store5(store5),
    .store1(store1),
    .next_store50(next_store50),
    .next_store10(next_store10),
    .next_store5(next_store5),
    .next_store1(next_store1),

    .req_item(req_item),
    .next_req_item(next_req_item),
    .req_in50(req_in50),
    .req_in10(req_in10),
    .req_in5(req_in5),
    .req_in1(req_in1),
    .next_req_in50(next_req_in50),
    .next_req_in10(next_req_in10),
    .next_req_in5(next_req_in5),
    .next_req_in1(next_req_in1),

    .disp_item(disp_item),
    .next_disp_item(next_disp_item),
    .disp50(disp50),
    .disp10(disp10),
    .disp5(disp5),
    .disp1(disp1),
    .next_disp50(next_disp50),
    .next_disp10(next_disp10),
    .next_disp5(next_disp5),
    .next_disp1(next_disp1),

    .item_price(item_price),
    .inserted_value(inserted_value),
    .change_value(change_value),

    .avail50(avail50),
    .avail10(avail10),
    .avail5(avail5),
    .avail1(avail1),
    .use50(use50),
    .use10(use10),
    .use5(use5),
    .use1(use1),

    .enough_money(enough_money),
    .success(success)
);