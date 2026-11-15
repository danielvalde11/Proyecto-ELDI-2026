`timescale 1ns / 1ps

module tb_captura_y_bcd_a_float;

    reg         clk;
    reg         reset;
    reg         enable_A;
    reg         enable_B;
    reg         clear_op;
    reg         tecla_valida;
    reg         pulso_signo;
    reg  [3:0]  teclado_in;
    wire [31:0] A_float;
    wire [31:0] B_float;

    conversor_dual_AB dut (
        .clk          (clk),
        .reset        (reset),
        .enable_A     (enable_A),
        .enable_B     (enable_B),
        .clear_op     (clear_op),
        .tecla_valida (tecla_valida),
        .pulso_signo  (pulso_signo),
        .teclado_in   (teclado_in),
        .A_float      (A_float),
        .B_float      (B_float)
    );

    always #5 clk = ~clk;

    task presionar_tecla;
        input [3:0] codigo;
        begin
            @(posedge clk);
            teclado_in   <= codigo;
            tecla_valida <= 1'b1;
            @(posedge clk);
            tecla_valida <= 1'b0;
            #20;
        end
    endtask

    initial begin
        clk = 0; reset = 1; enable_A = 0; enable_B = 0; clear_op = 0;
        tecla_valida = 0; pulso_signo = 0; teclado_in = 4'd0;

        #20 reset = 0;
        #10 enable_A = 1;
        presionar_tecla(4'd1);
        presionar_tecla(4'd2);
        presionar_tecla(4'd5); 

        #20;
        $display("Turno A -> A_float: %h | B_float: %h", A_float, B_float);
        enable_A = 0;
        enable_B = 1;
        #10;
        presionar_tecla(4'd4);
        presionar_tecla(4'd2); 

        #20;
        $display("Turno B -> A_float: %h | B_float: %h", A_float, B_float);

        #40 $finish;
    end

endmodule
