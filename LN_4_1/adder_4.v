// 4-bit ripple-carry adder with carry in/out.
module adder_4 (
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire       cin,
    output wire [3:0] sum,
    output wire       cout
);
    ripple_carry_adder #(.W(4)) u_rca (
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum),
        .cout(cout)
    );
endmodule
