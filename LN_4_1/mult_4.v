module mult_4 (
    input  wire [3:0] a,
    input  wire [3:0] b,
    output wire [7:0] p
);
    
    assign p = a * b;

endmodule
