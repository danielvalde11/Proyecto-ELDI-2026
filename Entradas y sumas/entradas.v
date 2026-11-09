module controlador_entradas (
    input wire clk,
    input wire rst, // Reset síncrono activo en alto
    
    // Puertos físicos Matriz 1 (numeros)
    input wire [3:0] col_num,
    output wire [3:0] fila_num,
    
    // Puertos físicos Matriz 2 (Operaciones, Graficar, X, Igual)
    input wire [3:0] col_op,
    output wire [3:0] fila_op,
    
    // Salidas hacia el Hardware de Conversión IEEE 754
    output wire [3:0] tecla_num_out,
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

    reg [1:0] contador;
    always @(posedge clk_lento or posedge rst) begin
        if (rst) begin
            state <= ESTADO_A;
            opcode_alu <= 3'b000;
            modo_grafica <= 1'b0;
            flag_var_x <= 1'b0;
        end else begin
            state <= next_state;
            
            if (valid_op) begin
                case (tecla_op)
                    4'h1: opcode_alu <= 3'b000; // Suma
                    4'h2: opcode_alu <= 3'b100; // Resta
                    4'h3: opcode_alu <= 3'b001; // Multiplicación
                    4'h4: opcode_alu <= 3'b101; // División
                    4'h5: opcode_alu <= 3'b010; // Seno
                    4'h6: opcode_alu <= 3'b110; // Coseno
                    4'h7: modo_grafica <= 1'b1; // Activar Modo Gráfica
                    4'h8: flag_var_x   <= 1'b1; // Activar Variable X
                    default: ; 
                endcase
            end
        end
    end

    always @(*) begin
        tecla = 4'h0;
        ena = 1'b0;
        case ({y, x})
//columna0
            8'b1110_1110: begin tecla = 4'h1; ena = 1'b1; end
            8'b1110_1101: begin tecla = 4'h4; ena = 1'b1; end
            8'b1110_1011: begin tecla = 4'h7; ena = 1'b1; end
            8'b1110_0111: begin tecla = 4'hE; ena = 1'b1; end 
//columna1  
            8'b1101_1110: begin tecla = 4'h2; ena = 1'b1; end
            8'b1101_1101: begin tecla = 4'h5; ena = 1'b1; end
            8'b1101_1011: begin tecla = 4'h8; ena = 1'b1; end
            8'b1101_0111: begin tecla = 4'h0; ena = 1'b1; end 
//columna2            
            8'b1011_1110: begin tecla = 4'h3; ena = 1'b1; end
            8'b1011_1101: begin tecla = 4'h6; ena = 1'b1; end
            8'b1011_1011: begin tecla = 4'h9; ena = 1'b1; end
            8'b1011_0111: begin tecla = 4'hF; ena = 1'b1; end 
//columna 3
            8'b0111_1110: begin tecla = 4'hA; ena = 1'b1; end
            8'b0111_1101: begin tecla = 4'hB; ena = 1'b1; end
            8'b0111_1011: begin tecla = 4'hC; ena = 1'b1; end
            8'b0111_0111: begin tecla = 4'hD; ena = 1'b1; end            
            default: begin tecla = 4'h0; ena = 1'b0; end
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            registro <= 4'h0;
            validar <= 1'b0;
        end else begin
            if (ena) begin
                registro <= tecla;
                validar <= 1'b1;
            end else begin
                validar <= 1'b0;
            end
            
            ESTADO_B: begin
                enable_B = 1'b1; 
            end
            
            CALCULAR: begin
                calcular_trigger = 1'b1; 
            end
            
            default: ;
        endcase
    end

endmodule
