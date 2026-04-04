// Self-checking testbench for adder_4 and mult_4.
`timescale 1ns / 1ps

module tb_ln41;
    reg  [3:0] a, b;
    reg        cin;
    wire [3:0] sum;
    wire       cout;
    wire [7:0] p;

    adder_4 u_adder (
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum),
        .cout(cout)
    );

    mult_4 u_mult (
        .a(a),
        .b(b),
        .p(p)
    );

    integer ia, ib, ic;
    integer err;
    reg [4:0] exp_add;
    reg [7:0] exp_mul;

    initial begin
        err = 0;
        // adder_4: all a, b, cin
        for (ic = 0; ic <= 1; ic = ic + 1) begin
            cin = ic[0];
            for (ia = 0; ia < 16; ia = ia + 1) begin
                for (ib = 0; ib < 16; ib = ib + 1) begin
                    a   = ia[3:0];
                    b   = ib[3:0];
                    exp_add = ia + ib + ic;
                    #1;
                    if ({cout, sum} !== exp_add) begin
                        $display("FAIL adder: %0d + %0d + cin=%0d => got {%b,%b} expect %0d",
                                 ia, ib, ic, cout, sum, exp_add);
                        err = err + 1;
                    end
                end
            end
        end

        // mult_4: all a, b (cin unused)
        cin = 0;
        for (ia = 0; ia < 16; ia = ia + 1) begin
            for (ib = 0; ib < 16; ib = ib + 1) begin
                a = ia[3:0];
                b = ib[3:0];
                exp_mul = ia * ib;
                #1;
                if (p !== exp_mul) begin
                    $display("FAIL mult: %0d * %0d => got %0d expect %0d", ia, ib, p, exp_mul);
                    err = err + 1;
                end
            end
        end

        if (err == 0)
            $display("PASS tb_ln41 (adder exhaustive + mult exhaustive)");
        else
            $display("FAIL tb_ln41: %0d error(s)", err);
        $finish;
    end
endmodule
