module adder_4 (
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire       cin,
    output wire [3:0] sum,
    output wire       cout
);
    wire [4:0] c;
    assign c[0] = cin;

    assign {c[1], sum[0]} = a[0] + b[0] + c[0];
    assign {c[2], sum[1]} = a[1] + b[1] + c[1];
    assign {c[3], sum[2]} = a[2] + b[2] + c[2];
    assign {c[4], sum[3]} = a[3] + b[3] + c[3];
    assign cout = c[4];
endmodule
