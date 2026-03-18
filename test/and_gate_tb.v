`timescale 1ns/1ps

module and_gate_tb;

reg a;
reg b;
wire y;

and_gate uut (
    .a(a),
    .b(b),
    .y(y)
);

initial begin
    $display("time\ta\tb\ty");
    $display("----------------");

    a = 0; b = 0; #10;
    $display("%0t\t%b\t%b\t%b", $time, a, b, y);

    a = 0; b = 1; #10;
    $display("%0t\t%b\t%b\t%b", $time, a, b, y);

    a = 1; b = 0; #10;
    $display("%0t\t%b\t%b\t%b", $time, a, b, y);

    a = 1; b = 1; #10;
    $display("%0t\t%b\t%b\t%b", $time, a, b, y);

    $finish;
end

endmodule
