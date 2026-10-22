module teclado (
    input wire clk, rst, wire [3:0] x,
    output reg [3:0] y, reg [3:0] tecla, reg ena, reg [3:0] registro, reg validar         
);
// 1. Decodificador 
    reg [1:0] contador;
    always @(posedge clk) begin
        if (rst) begin
            contador <= 2'b00;
            y <= 4'b1110;
        end else begin
            contador <= contador + 1;
            case (contador)
                2'b00: y <= 4'b1110;
                2'b01: y <= 4'b1101;
                2'b10: y <= 4'b1011;
                2'b11: y <= 4'b0111;
            endcase
        end
    end
    // 2. Codificador
    always @(*) begin
        tecla = 4'h0;
        ena = 1'b0;
        case ({y, x})
            // Columna 0
            8'b1110_1110: begin tecla = 4'h1; ena = 1'b1; end
            8'b1110_1101: begin tecla = 4'h4; ena = 1'b1; end
            8'b1110_1011: begin tecla = 4'h7; ena = 1'b1; end
            8'b1110_0111: begin tecla = 4'hE; ena = 1'b1; end 
            // Columna 1
            8'b1101_1110: begin tecla = 4'h2; ena = 1'b1; end
            8'b1101_1101: begin tecla = 4'h5; ena = 1'b1; end
            8'b1101_1011: begin tecla = 4'h8; ena = 1'b1; end
            8'b1101_0111: begin tecla = 4'h0; ena = 1'b1; end 
            // Columna 2 
            8'b1011_1110: begin tecla = 4'h3; ena = 1'b1; end
            8'b1011_1101: begin tecla = 4'h6; ena = 1'b1; end
            8'b1011_1011: begin tecla = 4'h9; ena = 1'b1; end
            8'b1011_0111: begin tecla = 4'hF; ena = 1'b1; end 
            // Columna 3
            8'b0111_1110: begin tecla = 4'hA; ena = 1'b1; end
            8'b0111_1101: begin tecla = 4'hB; ena = 1'b1; end
            8'b0111_1011: begin tecla = 4'hC; ena = 1'b1; end
            8'b0111_0111: begin tecla = 4'hD; ena = 1'b1; end
            default: begin 
                tecla = 4'h0; 
                ena = 1'b0; 
            end
        endcase
    end
//3. Registro
    always @(posedge clk) begin
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
        end 
    end
endmodule