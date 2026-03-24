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

    integer r;
    integer item, in50, in10, in5, in1, reset_signal;

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
        $display("%d %d %d %d %d %d", coinOutNTD_50, coinOutNTD_10, coinOutNTD_5, coinOutNTD_1, itemTypeOut, serviceTypeOut);
    end

    integer file;

    initial begin
        // 初始化
        reset = 1;
        coinInNTD_50 = 0;
        coinInNTD_10 = 0;
        coinInNTD_5  = 0;
        coinInNTD_1  = 0;
        itemTypeIn   = ITEM_NONE;
        file = $fopen("input.txt", "r");

        #1
        r = $fscanf(file, "%d %d %d %d %d %d\n", reset_signal, in50, in10, in5, in1, item);
        while (r != -1) begin
            reset = reset_signal;
            itemTypeIn = item;
            coinInNTD_50 = in50;
            coinInNTD_10 = in10;
            coinInNTD_5  = in5;
            coinInNTD_1  = in1;

            #10
            r = $fscanf(file, "%d %d %d %d %d %d\n", reset_signal, in50, in10, in5, in1, item);
        end
        $fclose(file);
        $finish;
    end

endmodule