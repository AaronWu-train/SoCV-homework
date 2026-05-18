module vending_machine (
    input         clk,
    input         reset,

    input  [1:0]  coinInNTD_50,
    input  [1:0]  coinInNTD_10,
    input  [1:0]  coinInNTD_5,
    input  [1:0]  coinInNTD_1,
    input  [1:0]  itemTypeIn,

    // Abstraction: transaction outcome and change/return (over-approximate)
    input         free_success,
    input         free_give_change,
    input         free_return_coins,

    output [2:0]  coinOutNTD_50,
    output [2:0]  coinOutNTD_10,
    output [2:0]  coinOutNTD_5,
    output [2:0]  coinOutNTD_1,
    output [1:0]  itemTypeOut,
    output [1:0]  serviceTypeOut,

    output        bad_illegal_service,
    output        bad_item_not_off,
    output        bad_on_req_not_busy,
    output        bad_busy_not_off,
    output        bad_off_not_on
);

    localparam [1:0] ITEM_NONE = 2'd0;

    localparam [1:0] SERVICE_OFF  = 2'd0;
    localparam [1:0] SERVICE_ON   = 2'd1;
    localparam [1:0] SERVICE_BUSY = 2'd2;

    reg [1:0] state, next_state;

    reg [1:0] req_item, next_req_item;

    reg [1:0] disp_item, next_disp_item;
    reg       disp_coin, next_disp_coin;

    reg       success;

    wire [2:0] disp_coin_val = disp_coin ? 3'd1 : 3'd0;

    assign serviceTypeOut = state;

    assign itemTypeOut    = (state == SERVICE_OFF) ? disp_item : ITEM_NONE;
    assign coinOutNTD_50  = (state == SERVICE_OFF) ? disp_coin_val : 3'd0;
    assign coinOutNTD_10  = (state == SERVICE_OFF) ? disp_coin_val : 3'd0;
    assign coinOutNTD_5   = (state == SERVICE_OFF) ? disp_coin_val : 3'd0;
    assign coinOutNTD_1   = (state == SERVICE_OFF) ? disp_coin_val : 3'd0;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= SERVICE_ON;

            req_item <= ITEM_NONE;

            disp_item <= ITEM_NONE;
            disp_coin <= 1'b0;
        end
        else begin
            state <= next_state;

            req_item <= next_req_item;

            disp_item <= next_disp_item;
            disp_coin <= next_disp_coin;
        end
    end

    always @(*) begin
        success = free_success;
    end

    always @(*) begin
        next_state = state;

        next_req_item = req_item;

        next_disp_item = disp_item;
        next_disp_coin = disp_coin;

        case (state)
            SERVICE_ON: begin
                if (itemTypeIn != ITEM_NONE) begin
                    next_req_item = itemTypeIn;
                    next_state    = SERVICE_BUSY;
                end
            end

            SERVICE_BUSY: begin
                if (success) begin
                    next_disp_item = req_item;
                    next_disp_coin = free_give_change;
                end
                else begin
                    next_disp_item = ITEM_NONE;
                    next_disp_coin = free_return_coins;
                end

                next_state = SERVICE_OFF;
            end

            SERVICE_OFF: begin
                next_req_item = ITEM_NONE;

                next_disp_item = ITEM_NONE;
                next_disp_coin = 1'b0;

                next_state = SERVICE_ON;
            end

            default: begin
                next_state = SERVICE_ON;
            end
        endcase
    end

    assign bad_illegal_service =
        (serviceTypeOut == 2'd3);

    assign bad_item_not_off =
        (!reset) && (serviceTypeOut != SERVICE_OFF) && (itemTypeOut != ITEM_NONE);

    assign bad_on_req_not_busy =
        (!reset) && (state == SERVICE_ON) &&
        (itemTypeIn != ITEM_NONE) &&
        (next_state != SERVICE_BUSY);

    assign bad_busy_not_off =
        (!reset) && (state == SERVICE_BUSY) &&
        (next_state != SERVICE_OFF);

    assign bad_off_not_on =
        (!reset) && (state == SERVICE_OFF) &&
        (next_state != SERVICE_ON);

endmodule
