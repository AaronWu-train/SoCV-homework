`timescale 1ns/1ps

module tb_vending_machine;

    reg         clk;
    reg         reset;

    reg  [1:0]  coinInNTD_50;
    reg  [1:0]  coinInNTD_10;
    reg  [1:0]  coinInNTD_5;
    reg  [1:0]  coinInNTD_1;
    reg  [1:0]  itemTypeIn;

    wire [2:0]  coinOutNTD_50;
    wire [2:0]  coinOutNTD_10;
    wire [2:0]  coinOutNTD_5;
    wire [2:0]  coinOutNTD_1;
    wire [1:0]  itemTypeOut;
    wire [1:0]  serviceTypeOut;

    localparam [1:0] ITEM_NONE = 2'd0;
    localparam [1:0] ITEM_A    = 2'd1;
    localparam [1:0] ITEM_B    = 2'd2;
    localparam [1:0] ITEM_C    = 2'd3;

    vending_machine dut (
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
        .serviceTypeOut(serviceTypeOut)
    );

    // clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // 觀察輸出
    always @(posedge clk) begin
        $display("\n time=%0t \n reset=%0b | itemIn=%0d | in50=%0d in10=%0d in5=%0d in1=%0d \n service=%0d \n itemOut=%0d \n out50=%0d out10=%0d out5=%0d out1=%0d \n",
                 $time,
                 reset,
                 itemTypeIn,
                 coinInNTD_50, coinInNTD_10, coinInNTD_5, coinInNTD_1,
                 serviceTypeOut,
                 itemTypeOut,
                 coinOutNTD_50, coinOutNTD_10, coinOutNTD_5, coinOutNTD_1);
    end

    initial begin
        // 初始化
        reset = 1;
        coinInNTD_50 = 0;
        coinInNTD_10 = 0;
        coinInNTD_5  = 0;
        coinInNTD_1  = 0;
        itemTypeIn   = ITEM_NONE;

        // reset 一段時間
        #12;
        reset = 0;

        // =========================================
        // Case 1: 買 ITEM_A，投 1 個 10 元
        // ITEM_A = 8，預期找 2 個 1 元
        // =========================================
        #8;
        $display("=== Case 1: 買 ITEM_A，投 1 個 10 元 ===");
        itemTypeIn   = ITEM_A;
        coinInNTD_10 = 2'd1;

        #10;  // 撐一個 clock
        itemTypeIn   = ITEM_NONE;
        coinInNTD_10 = 2'd0;

        // 等 machine 跑完
        #30;

        // =========================================
        // Case 2: 買 ITEM_C，投 2 個 10 元
        // ITEM_C = 22，錢不夠，應退回 2 個 10 元
        // =========================================
        $display("=== Case 2: 買 ITEM_C，投 2 個 10 元 ===");
        itemTypeIn   = ITEM_C;
        coinInNTD_10 = 2'd2;

        #10;
        itemTypeIn   = ITEM_NONE;
        coinInNTD_10 = 2'd0;

        #30;

        // =========================================
        // Case 3: 買 ITEM_B，投 2 個 10 元
        // ITEM_B = 15，預期找 1 個 5 元
        // =========================================
        $display("=== Case 3: 買 ITEM_B，投 2 個 10 元 ===");
        itemTypeIn   = ITEM_B;
        coinInNTD_10 = 2'd2;

        #10;
        itemTypeIn   = ITEM_NONE;
        coinInNTD_10 = 2'd0;

        #30;

        $finish;
    end

endmodule