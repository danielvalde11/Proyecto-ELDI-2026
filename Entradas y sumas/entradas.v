`timescale 1ns / 1ps

module controlador_entradas (
    input wire clk,
    input wire rst, 
    
    // Puertos físicos Matriz 1 (numeros)
    input wire [3:0] col_num,
    output wire [3:0] fila_num,
    
    // Puertos físicos Matriz 2 (Operaciones, Graficar, X, Igual)
    input wire [3:0] col_op,
    output wire [3:0] fila_op,
    
    // Salidas hacia el Hardware de Conversión IEEE 754
    output reg [3:0] tecla_num_out,
    output reg enable_A,
    output reg enable_B,
    
    // Salidas hacia la ALU 
    output reg [2:0] opcode_alu,
    output reg modo_grafica,
    output reg flag_var_x,
    output reg calcular_trigger
);

  
    reg [19:0] div_clk;
    wire clk_lento = div_clk[19]; 
    always @(posedge clk or posedge rst) begin
        if (rst) div_clk <= 20'd0;
        else div_clk <= div_clk + 1;
    end

    reg [3:0] anillo;
    always @(posedge clk_lento or posedge rst) begin
        if (rst) begin
            anillo <= 4'b1110; 
        end else begin
            
            anillo <= {anillo[2:0], anillo[3]};
        end
    end
   
    assign fila_num = anillo;
    assign fila_op  = anillo;

  
    reg [3:0] tecla;
    reg ena; 
    
    always @(*) begin
        tecla = 4'h0;
        ena = 1'b0;
        case ({fila_num, col_num})
          
            8'b1110_1110: begin tecla = 4'h1; ena = 1'b1; end
            8'b1110_1101: begin tecla = 4'h4; ena = 1'b1; end
            8'b1110_1011: begin tecla = 4'h7; ena = 1'b1; end
            8'b1110_0111: begin tecla = 4'hE; ena = 1'b1; end 
            
            8'b1101_1110: begin tecla = 4'h2; ena = 1'b1; end
            8'b1101_1101: begin tecla = 4'h5; ena = 1'b1; end
            8'b1101_1011: begin tecla = 4'h8; ena = 1'b1; end
            8'b1101_0111: begin tecla = 4'h0; ena = 1'b1; end 
            
            8'b1011_1110: begin tecla = 4'h3; ena = 1'b1; end
            8'b1011_1101: begin tecla = 4'h6; ena = 1'b1; end
            8'b1011_1011: begin tecla = 4'h9; ena = 1'b1; end
            8'b1011_0111: begin tecla = 4'hF; ena = 1'b1; end 
            
            8'b0111_1110: begin tecla = 4'hA; ena = 1'b1; end
            8'b0111_1101: begin tecla = 4'hB; ena = 1'b1; end
            8'b0111_1011: begin tecla = 4'hC; ena = 1'b1; end
            8'b0111_0111: begin tecla = 4'hD; ena = 1'b1; end            
            default:      begin tecla = 4'h0; ena = 1'b0; end
        endcase
    end

    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tecla_num_out <= 4'h0;
        end else if (ena) begin
            tecla_num_out <= tecla;
        end
    end

    
    reg [3:0] tecla_op_reg;
    reg valid_op;
    
    always @(*) begin
        tecla_op_reg = 4'h0;
        valid_op = 1'b0;
        case ({fila_op, col_op})
            
            8'b1110_1110: begin tecla_op_reg = 4'h1; valid_op = 1'b1; end // Suma
            8'b1110_1101: begin tecla_op_reg = 4'h2; valid_op = 1'b1; end // Resta
            8'b1110_1011: begin tecla_op_reg = 4'h3; valid_op = 1'b1; end // Multiplicación
            8'b1110_0111: begin tecla_op_reg = 4'h4; valid_op = 1'b1; end // División
            8'b1101_1110: begin tecla_op_reg = 4'h5; valid_op = 1'b1; end // Seno
            8'b1101_1101: begin tecla_op_reg = 4'h6; valid_op = 1'b1; end // Coseno
            8'b1101_1011: begin tecla_op_reg = 4'h7; valid_op = 1'b1; end // Gráfica
            8'b1101_0111: begin tecla_op_reg = 4'h8; valid_op = 1'b1; end // Var X
            
            8'b0111_0111: begin tecla_op_reg = 4'h9; valid_op = 1'b1; end 
            default:      begin tecla_op_reg = 4'h0; valid_op = 1'b0; end
        endcase
    end

    // --- 6. FSM Máquina de Estados ---
    parameter ESTADO_A = 2'b00;
    parameter ESTADO_B = 2'b01;
    parameter CALCULAR = 2'b10;
    
    reg [1:0] state, next_state;

    always @(posedge clk_lento or posedge rst) begin
        if (rst) state <= ESTADO_A;
        else     state <= next_state;
    end

    always @(*) begin
        next_state = state;
        enable_A = 1'b0;
        enable_B = 1'b0;
        calcular_trigger = 1'b0;
        
        case (state)
            ESTADO_A: begin
                enable_A = 1'b1;
                
                if (valid_op && tecla_op_reg != 4'h9) begin 
                    next_state = ESTADO_B;
                end
            end
            
            ESTADO_B: begin
                enable_B = 1'b1; 
               
                if (valid_op && tecla_op_reg == 4'h9) begin 
                    next_state = CALCULAR;
                end
            end
            
            CALCULAR: begin
                calcular_trigger = 1'b1; 
                next_state = ESTADO_A;
            end
            
            default: next_state = ESTADO_A;
        endcase
    end


    always @(posedge clk_lento or posedge rst) begin
        if (rst) begin
            opcode_alu <= 3'b000;
            modo_grafica <= 1'b0;
            flag_var_x <= 1'b0;
        end else if (valid_op) begin
            case (tecla_op_reg)
                4'h1: opcode_alu <= 3'b000; // Suma
                4'h2: opcode_alu <= 3'b100; // Resta
                4'h3: opcode_alu <= 3'b001; // Multiplicación
                4'h4: opcode_alu <= 3'b101; // División
                4'h5: opcode_alu <= 3'b010; // Seno
                4'h6: opcode_alu <= 3'b110; // Coseno
                4'h7: modo_grafica <= 1'b1; // Activar Gráfica
                4'h8: flag_var_x   <= 1'b1; // Activar X
                default: ; 
            endcase
        end
    end

endmodule
