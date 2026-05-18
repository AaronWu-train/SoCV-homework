module vending_machine (
    input         clk,
    input         reset,

    input  [1:0]  coinInNTD_50,
    input  [1:0]  coinInNTD_10,
    input  [1:0]  coinInNTD_5,
    input  [1:0]  coinInNTD_1,
    input  [1:0]  itemTypeIn,

    // Abstraction: 1-bit flags for OFF-state outputs (over-approximate)
    input         free_give_item,
    input         free_give_coin,

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
    localparam [1:0] ITEM_A    = 2'd1;

    localparam [1:0] SERVICE_OFF  = 2'd0;
    localparam [1:0] SERVICE_ON   = 2'd1;
    localparam [1:0] SERVICE_BUSY = 2'd2;

    reg [1:0] state, next_state;

    wire in_off = (state == SERVICE_OFF);

    assign serviceTypeOut = state;

    assign itemTypeOut =
        in_off && free_give_item ? ITEM_A : ITEM_NONE;

    assign coinOutNTD_50 = in_off && free_give_coin ? 3'd1 : 3'd0;
    assign coinOutNTD_10 = in_off && free_give_coin ? 3'd1 : 3'd0;
    assign coinOutNTD_5  = in_off && free_give_coin ? 3'd1 : 3'd0;
    assign coinOutNTD_1  = in_off && free_give_coin ? 3'd1 : 3'd0;

    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= SERVICE_ON;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;

        case (state)
            SERVICE_ON: begin
                if (itemTypeIn != ITEM_NONE)
                    next_state = SERVICE_BUSY;
            end

            SERVICE_BUSY: begin
                next_state = SERVICE_OFF;
            end

            SERVICE_OFF: begin
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
