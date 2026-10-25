`timescale 1ns / 1ps

module tb_floating_point_divider();

    reg clk;
    reg reset;
    reg start;
    reg [31:0] A;
    reg [31:0] B;
    wire [31:0] S;
    wire done;

    floating_point_divider uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .A(A),
        .B(B),
        .S(S),
        .done(done)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $monitor("Tiempo=%0t ns | A=%h | B=%h | Resultado S=%h | Terminó=%b", $time, A, B, S, done);

        reset = 1;
        start = 0;
        A = 32'd0;
        B = 32'd0;
        #20;
        reset = 0;
        #20;

        A = 32'h41200000;
        B = 32'h40000000;
        start = 1;       
        #10 start = 0;   
        @(posedge done); 
        #20;

        A = 32'hC0C00000;
        B = 32'h40400000;
        start = 1;
        #10 start = 0;
        @(posedge done);
        #20;

        A = 32'h3F800000;
        B = 32'h3F800000;
        start = 1;
        #10 start = 0;
        @(posedge done);
        #40;

        $finish;
    end

endmodule
