module vending_machine (
    input         clk,
    input         reset,

    input  [1:0]  coinInNTD_50,
    input  [1:0]  coinInNTD_10,
    input  [1:0]  coinInNTD_5,
    input  [1:0]  coinInNTD_1,
    input  [1:0]  itemTypeIn,

    output [2:0]  coinOutNTD_50,
    output [2:0]  coinOutNTD_10,
    output [2:0]  coinOutNTD_5,
    output [2:0]  coinOutNTD_1,
    output [1:0]  itemTypeOut,
    output [1:0]  serviceTypeOut
);

    // =========================================================
    // Local parameters
    // =========================================================
    localparam [1:0] ITEM_NONE = 2'd0;
    localparam [1:0] ITEM_A    = 2'd1;
    localparam [1:0] ITEM_B    = 2'd2;
    localparam [1:0] ITEM_C    = 2'd3;

    localparam [1:0] SERVICE_OFF  = 2'd0;
    localparam [1:0] SERVICE_ON   = 2'd1;
    localparam [1:0] SERVICE_BUSY = 2'd2;

    localparam [7:0] PRICE_A = 8'd8;
    localparam [7:0] PRICE_B = 8'd15;
    localparam [7:0] PRICE_C = 8'd22;

    // =========================================================
    // State / data registers
    // =========================================================
    reg [1:0] state, next_state;

    // coins stored inside machine
    reg [2:0] store50, next_store50;
    reg [2:0] store10, next_store10;
    reg [2:0] store5,  next_store5;
    reg [2:0] store1,  next_store1;

    // latched request
    reg [1:0] req_item, next_req_item;
    reg [1:0] req_in50, next_req_in50;
    reg [1:0] req_in10, next_req_in10;
    reg [1:0] req_in5,  next_req_in5;
    reg [1:0] req_in1,  next_req_in1;

    // latched result to be shown in SERVICE_OFF
    reg [1:0] disp_item, next_disp_item;
    reg [2:0] disp50, next_disp50;
    reg [2:0] disp10, next_disp10;
    reg [2:0] disp5,  next_disp5;
    reg [2:0] disp1,  next_disp1;

    // =========================================================
    // Combinational helper signals
    // =========================================================
    reg [7:0] item_price;
    reg [7:0] inserted_value;
    reg [7:0] change_value;

    reg [2:0] avail50, avail10, avail5, avail1;
    reg [2:0] use50, use10, use5, use1;

    reg       enough_money;
    reg       success;

    integer remain;

    // =========================================================
    // Output logic
    // Outputs are only visible in SERVICE_OFF
    // =========================================================
    assign serviceTypeOut = state;

    assign itemTypeOut    = (state == SERVICE_OFF) ? disp_item : ITEM_NONE;
    assign coinOutNTD_50  = (state == SERVICE_OFF) ? disp50    : 3'd0;
    assign coinOutNTD_10  = (state == SERVICE_OFF) ? disp10    : 3'd0;
    assign coinOutNTD_5   = (state == SERVICE_OFF) ? disp5     : 3'd0;
    assign coinOutNTD_1   = (state == SERVICE_OFF) ? disp1     : 3'd0;

    // =========================================================
    // Price decoder
    // =========================================================
    function [7:0] price_of_item;
        input [1:0] item;
        begin
            case (item)
                ITEM_A: price_of_item = PRICE_A;
                ITEM_B: price_of_item = PRICE_B;
                ITEM_C: price_of_item = PRICE_C;
                default: price_of_item = 8'd0;
            endcase
        end
    endfunction

    // cap stored coins to 7
    function [2:0] sat_add3;
        input [2:0] a;
        input [1:0] b;
        reg   [3:0] sum;
        begin
            sum = a + b;
            if (sum > 4'd7)
                sat_add3 = 3'd7;
            else
                sat_add3 = sum[2:0];
        end
    endfunction

    // =========================================================
    // Sequential logic
    // =========================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= SERVICE_ON;

            store50 <= 3'd2;
            store10 <= 3'd2;
            store5  <= 3'd2;
            store1  <= 3'd2;

            req_item <= ITEM_NONE;
            req_in50 <= 2'd0;
            req_in10 <= 2'd0;
            req_in5  <= 2'd0;
            req_in1  <= 2'd0;

            disp_item <= ITEM_NONE;
            disp50 <= 3'd0;
            disp10 <= 3'd0;
            disp5  <= 3'd0;
            disp1  <= 3'd0;
        end
        else begin
            state <= next_state;

            store50 <= next_store50;
            store10 <= next_store10;
            store5  <= next_store5;
            store1  <= next_store1;

            req_item <= next_req_item;
            req_in50 <= next_req_in50;
            req_in10 <= next_req_in10;
            req_in5  <= next_req_in5;
            req_in1  <= next_req_in1;

            disp_item <= next_disp_item;
            disp50 <= next_disp50;
            disp10 <= next_disp10;
            disp5  <= next_disp5;
            disp1  <= next_disp1;
        end
    end

    // =========================================================
    // Combinational datapath
    // Derived from currently latched request
    // =========================================================
    always @(*) begin
        item_price     = price_of_item(req_item);
        inserted_value = (req_in50 * 8'd50) +
                         (req_in10 * 8'd10) +
                         (req_in5  * 8'd5 ) +
                         (req_in1  * 8'd1 );

        enough_money = (inserted_value >= item_price);

        // machine first receives input coins, but stored amount saturates at 7
        avail50 = sat_add3(store50, req_in50);
        avail10 = sat_add3(store10, req_in10);
        avail5  = sat_add3(store5,  req_in5);
        avail1  = sat_add3(store1,  req_in1);

        change_value = inserted_value - item_price;

        use50 = 3'd0;
        use10 = 3'd0;
        use5  = 3'd0;
        use1  = 3'd0;

        remain = change_value;

        if (enough_money) begin
            while ((remain >= 50) && (use50 < avail50)) begin
                remain = remain - 50;
                use50  = use50 + 3'd1;
            end

            while ((remain >= 10) && (use10 < avail10)) begin
                remain = remain - 10;
                use10  = use10 + 3'd1;
            end

            while ((remain >= 5) && (use5 < avail5)) begin
                remain = remain - 5;
                use5   = use5 + 3'd1;
            end

            while ((remain >= 1) && (use1 < avail1)) begin
                remain = remain - 1;
                use1   = use1 + 3'd1;
            end
        end

        success = enough_money && (remain == 0);
    end

    // =========================================================
    // Next-state / next-data logic
    // =========================================================
    always @(*) begin
        // default: hold current values
        next_state = state;

        next_store50 = store50;
        next_store10 = store10;
        next_store5  = store5;
        next_store1  = store1;

        next_req_item = req_item;
        next_req_in50 = req_in50;
        next_req_in10 = req_in10;
        next_req_in5  = req_in5;
        next_req_in1  = req_in1;

        next_disp_item = disp_item;
        next_disp50 = disp50;
        next_disp10 = disp10;
        next_disp5  = disp5;
        next_disp1  = disp1;

        case (state)
            // -------------------------------------------------
            // Wait for request
            // Accept input only in SERVICE_ON and item != NONE
            // -------------------------------------------------
            SERVICE_ON: begin
                if (itemTypeIn != ITEM_NONE) begin
                    next_req_item = itemTypeIn;
                    next_req_in50 = coinInNTD_50;
                    next_req_in10 = coinInNTD_10;
                    next_req_in5  = coinInNTD_5;
                    next_req_in1  = coinInNTD_1;
                    next_state    = SERVICE_BUSY;
                end
            end

            // -------------------------------------------------
            // Calculate one transaction
            // -------------------------------------------------
            SERVICE_BUSY: begin
                if (success) begin
                    // give item and change
                    next_disp_item = req_item;
                    next_disp50    = use50;
                    next_disp10    = use10;
                    next_disp5     = use5;
                    next_disp1     = use1;

                    // machine stores accepted coins and then pays change
                    next_store50 = avail50 - use50;
                    next_store10 = avail10 - use10;
                    next_store5  = avail5  - use5;
                    next_store1  = avail1  - use1;
                end
                else begin
                    // fail: return exactly the inserted coins, give no item
                    next_disp_item = ITEM_NONE;
                    next_disp50    = {1'b0, req_in50};
                    next_disp10    = {1'b0, req_in10};
                    next_disp5     = {1'b0, req_in5};
                    next_disp1     = {1'b0, req_in1};

                    // machine never eats money
                    next_store50 = store50;
                    next_store10 = store10;
                    next_store5  = store5;
                    next_store1  = store1;
                end

                next_state = SERVICE_OFF;
            end

            // -------------------------------------------------
            // Output result for one cycle, then go back to ON
            // -------------------------------------------------
            SERVICE_OFF: begin
                next_req_item = ITEM_NONE;
                next_req_in50 = 2'd0;
                next_req_in10 = 2'd0;
                next_req_in5  = 2'd0;
                next_req_in1  = 2'd0;

                next_disp_item = ITEM_NONE;
                next_disp50    = 3'd0;
                next_disp10    = 3'd0;
                next_disp5     = 3'd0;
                next_disp1     = 3'd0;

                next_state = SERVICE_ON;
            end

            default: begin
                next_state = SERVICE_ON;
            end
        endcase
    end

endmodule