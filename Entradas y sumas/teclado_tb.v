`timescale 1ns / 1ps

module controlador_entradas_tb;

    
    reg clk;
    reg rst;
    reg [3:0] col_num;
    reg [3:0] col_op;
    
    wire [3:0] fila_num;
    wire [3:0] fila_op;
    wire [3:0] tecla_num_out;
    wire enable_A;
    wire enable_B;
    wire [2:0] opcode_alu;
    wire modo_grafica;
    wire flag_var_x;
    wire calcular_trigger;

    
    controlador_entradas uut (
        .clk(clk),
        .rst(rst),
        .col_num(col_num),
        .fila_num(fila_num),
        .col_op(col_op),
        .fila_op(fila_op),
        .tecla_num_out(tecla_num_out),
        .enable_A(enable_A),
        .enable_B(enable_B),
        .opcode_alu(opcode_alu),
        .modo_grafica(modo_grafica),
        .flag_var_x(flag_var_x),
        .calcular_trigger(calcular_trigger)
    );

    
    always #5 clk = ~clk;

   
    initial begin
 
        clk = 0;
        rst = 1;
        col_num = 4'b0000; 
        col_op = 4'b0000;  
        #100;
        rst = 0;
        
        
        
       
        wait (uut.fila_num == 4'b1110);
        @(posedge uut.clk_lento);
        col_num = 4'b1110; 
        @(posedge uut.clk_lento); 
        col_num = 4'b0000; 
        
      
        #200; 
        
       
        wait (uut.fila_op == 4'b1110); 
        @(posedge uut.clk_lento);
        col_op = 4'b1110; 
        @(posedge uut.clk_lento); 
        col_op = 4'b0000; 
       
        wait (uut.fila_op == 4'b0111); 
        @(posedge uut.clk_lento);
        col_op = 4'b0111; 
        @(posedge uut.clk_lento);
        col_op = 4'b0000; 
        
        #500;
        
    end

endmodule
