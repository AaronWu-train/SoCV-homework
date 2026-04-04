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


// Fixed-width ripple-carry adders for mult_4 stages (explicit full_adder chains).

module adder_6 (
    input  wire [5:0] a,
    input  wire [5:0] b,
    input  wire       cin,
    output wire [5:0] sum,
    output wire       cout
);
    wire [6:0] c;
    assign c[0] = cin;

    full_adder u_fa0 (.a(a[0]), .b(b[0]), .cin(c[0]), .sum(sum[0]), .cout(c[1]));
    full_adder u_fa1 (.a(a[1]), .b(b[1]), .cin(c[1]), .sum(sum[1]), .cout(c[2]));
    full_adder u_fa2 (.a(a[2]), .b(b[2]), .cin(c[2]), .sum(sum[2]), .cout(c[3]));
    full_adder u_fa3 (.a(a[3]), .b(b[3]), .cin(c[3]), .sum(sum[3]), .cout(c[4]));
    full_adder u_fa4 (.a(a[4]), .b(b[4]), .cin(c[4]), .sum(sum[4]), .cout(c[5]));
    full_adder u_fa5 (.a(a[5]), .b(b[5]), .cin(c[5]), .sum(sum[5]), .cout(c[6]));

    assign cout = c[6];
endmodule

module adder_7 (
    input  wire [6:0] a,
    input  wire [6:0] b,
    input  wire       cin,
    output wire [6:0] sum,
    output wire       cout
);
    wire [7:0] c;
    assign c[0] = cin;

    full_adder u_fa0 (.a(a[0]), .b(b[0]), .cin(c[0]), .sum(sum[0]), .cout(c[1]));
    full_adder u_fa1 (.a(a[1]), .b(b[1]), .cin(c[1]), .sum(sum[1]), .cout(c[2]));
    full_adder u_fa2 (.a(a[2]), .b(b[2]), .cin(c[2]), .sum(sum[2]), .cout(c[3]));
    full_adder u_fa3 (.a(a[3]), .b(b[3]), .cin(c[3]), .sum(sum[3]), .cout(c[4]));
    full_adder u_fa4 (.a(a[4]), .b(b[4]), .cin(c[4]), .sum(sum[4]), .cout(c[5]));
    full_adder u_fa5 (.a(a[5]), .b(b[5]), .cin(c[5]), .sum(sum[5]), .cout(c[6]));
    full_adder u_fa6 (.a(a[6]), .b(b[6]), .cin(c[6]), .sum(sum[6]), .cout(c[7]));

    assign cout = c[7];
endmodule

module adder_8 (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire       cin,
    output wire [7:0] sum,
    output wire       cout
);
    wire [8:0] c;
    assign c[0] = cin;

    full_adder u_fa0 (.a(a[0]), .b(b[0]), .cin(c[0]), .sum(sum[0]), .cout(c[1]));
    full_adder u_fa1 (.a(a[1]), .b(b[1]), .cin(c[1]), .sum(sum[1]), .cout(c[2]));
    full_adder u_fa2 (.a(a[2]), .b(b[2]), .cin(c[2]), .sum(sum[2]), .cout(c[3]));
    full_adder u_fa3 (.a(a[3]), .b(b[3]), .cin(c[3]), .sum(sum[3]), .cout(c[4]));
    full_adder u_fa4 (.a(a[4]), .b(b[4]), .cin(c[4]), .sum(sum[4]), .cout(c[5]));
    full_adder u_fa5 (.a(a[5]), .b(b[5]), .cin(c[5]), .sum(sum[5]), .cout(c[6]));
    full_adder u_fa6 (.a(a[6]), .b(b[6]), .cin(c[6]), .sum(sum[6]), .cout(c[7]));
    full_adder u_fa7 (.a(a[7]), .b(b[7]), .cin(c[7]), .sum(sum[7]), .cout(c[8]));

    assign cout = c[8];
endmodule


// 4x4 unsigned multiplier: partial products summed in three ripple-carry stages.
module mult_4 (
    input  wire [3:0] a,
    input  wire [3:0] b,
    output wire [7:0] p
);
    wire [3:0] m0, m1, m2, m3;
    assign m0 = a & {4{b[0]}};
    assign m1 = a & {4{b[1]}};
    assign m2 = a & {4{b[2]}};
    assign m3 = a & {4{b[3]}};

    wire [5:0] s1;
    wire [6:0] s2;
    wire [7:0] s3;
    wire       c1, c2, c3;

    // s1 = m0 + (m1 << 1)
    adder_6 u_stage1 (
        .a({2'b0, m0}),
        .b({1'b0, m1, 1'b0}),
        .cin(1'b0),
        .sum(s1),
        .cout(c1)
    );

    // s2 = s1 + (m2 << 2)
    adder_7 u_stage2 (
        .a({1'b0, s1}),
        .b({1'b0, m2, 2'b0}),
        .cin(1'b0),
        .sum(s2),
        .cout(c2)
    );

    // s3 = s2 + (m3 << 3)
    adder_8 u_stage3 (
        .a({1'b0, s2}),
        .b({1'b0, m3, 3'b0}),
        .cin(1'b0),
        .sum(s3),
        .cout(c3)
    );

    assign p = s3;
endmodule
