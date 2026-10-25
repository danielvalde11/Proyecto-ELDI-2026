`timescale 1ns / 1ps

module Multipler_tb();

 
    reg [31:0] A;
    reg [31:0] B;
    wire [31:0] S;

   
    Multipler uut (
        .A(A),
        .B(B),
        .S(S)
    );

    
    initial begin
   
        $monitor("Time=%0t ns | A = %h | B = %h | S (Resultado) = %h", $time, A, B, S);

//caso1
        A = 32'h3F800000; 
        B = 32'h3F800000;
        #20;

//caso2
        A = 32'h40000000;
        B = 32'h40400000;
        #20;

  
//caso3
        A = 32'h40000000;
        B = 32'hC0400000;
        #20;

//caso4
        A = 32'h41200000; 
        B = 32'h41200000; 
        #20;
        $finish;
    end

endmodule
