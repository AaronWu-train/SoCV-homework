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
    ripple_carry_adder #(.W(6)) u_stage1 (
        .a({2'b0, m0}),
        .b({1'b0, m1, 1'b0}),
        .cin(1'b0),
        .sum(s1),
        .cout(c1)
    );

    // s2 = s1 + (m2 << 2)
    ripple_carry_adder #(.W(7)) u_stage2 (
        .a({1'b0, s1}),
        .b({1'b0, m2, 2'b0}),
        .cin(1'b0),
        .sum(s2),
        .cout(c2)
    );

    // s3 = s2 + (m3 << 3)
    ripple_carry_adder #(.W(8)) u_stage3 (
        .a({1'b0, s2}),
        .b({1'b0, m3, 3'b0}),
        .cin(1'b0),
        .sum(s3),
        .cout(c3)
    );

    assign p = s3;
endmodule
