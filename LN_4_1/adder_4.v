// 1-bit full adder: sum = a XOR b XOR cin, carry out to next stage.
module full_adder (
    input  wire a,
    input  wire b,
    input  wire cin,
    output wire sum,
    output wire cout
);
    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (cin & (a ^ b));
endmodule


// 4-bit ripple-carry adder with carry in/out (full_adder chain, no generate).
module adder_4 (
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire       cin,
    output wire [3:0] sum,
    output wire       cout
);
    wire [4:0] c;
    assign c[0] = cin;

    full_adder u_fa0 (
        .a(a[0]),
        .b(b[0]),
        .cin(c[0]),
        .sum(sum[0]),
        .cout(c[1])
    );
    full_adder u_fa1 (
        .a(a[1]),
        .b(b[1]),
        .cin(c[1]),
        .sum(sum[1]),
        .cout(c[2])
    );
    full_adder u_fa2 (
        .a(a[2]),
        .b(b[2]),
        .cin(c[2]),
        .sum(sum[2]),
        .cout(c[3])
    );
    full_adder u_fa3 (
        .a(a[3]),
        .b(b[3]),
        .cin(c[3]),
        .sum(sum[3]),
        .cout(c[4])
    );

    assign cout = c[4];
endmodule
