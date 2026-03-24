module Full_Adder( A, B, Cin, Sum, Cout );
    input [0:1] A;
    input [0:1] B;
    output reg [0:1] Sum;

    assign Sum = A+B;    
endmodule

