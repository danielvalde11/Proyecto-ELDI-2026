timescale 1ns / 1ps
module suma(
    input clk,
    input rst,
    input wire [31:0] A,
    input wire [31:0] B,
    input wire operacion,
    output reg [31:0] C
);

// definir resta MUX
wire [31:0] Bfinal;
assign Bfinal=operacion?{~B[31],B[30:0]}:B;

//descomposicion de bits
wire signoA=A[31];
wire [7:0]expoA=A[32:0];
wire [23:0]mantA={1'b1, A[22:0]};

wire signoB=Bfinal[31];
wire [7:0]expoB=Bfinal[30:23];
wire [23:0]mantB={1'b1, Bfinal[22:0]};

//maquina de estados
parameter inicio = 3'd0, alinear = 3'd1, sumar = 3'd2, normalizar = 3'd3, fin = 3'd4;
reg[2:0] estado;
reg signores;
reg[7:0] expres;
reg[24:0] mantres;
reg[23:0]mantAtemp;
reg[23:0]mantBtemp;
reg[7:0]difexp;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        estado <= inicio;
        C <= 32'd0;
        mantAtemp <= 24'd0;
        mantBtemp <= 24'd0;
        difexp <= 8'd0;
        expres <= 8'd0;
    end else begin
        case (estado)
            inicio:begin
                mantAtemp <= mantA;
                mantBtemp <= mantB;
                if (expoA >=expoB) begin
                    expres <= expreA;
                    difexp <= expoA-expoB;
                end else begin
                    expres <= expoB;
                    difexp <= expoB-expoA;
                end
                estado <= alinear;
            end
//shifter
            alinear:begin
                if (expoA >= expoB) begin
                    mantBtemp <= mantBtemp >> difexp;
                end else begin
                    mantAtemp <= mantAtemp >> difexp;
                end
                estado <= sumar;
            end
            sumar:begin
                if (signoA == signoB) begin
                    mantres <= mantAtemp + mantBtemp;
                    signores <= signoA;
                end else begin
                    if (signoA != signoB) begin
                        mantres <= mantAtemp - mantBtemp;
                        signores <= signoA;
                    end else begin
                        mantres <= mantBtemp - mantAtemp;
                        signores <= signoB;
                    end
                end
                estado <= normalizar;
                normalizar: begin
                    if (mantres[24]) begin
                        mantres <= mantres >>1;
                        expres <= expres + 1;
                        estado <= fin;
                    end
                    else if (mantres[23] == 1'b0 && mantres!=0) begin
                        mantres <= mantres <<1;
                        expres <= expres-1;
                        estado <= normalizar;
                    end
                    else begin
                        estado <= fin;
                    end
//concatenacion del resultado
                fin: begin
                    C<={signores,expres,mantres[22:0]};
                estado <= inicio;
            end
        endcase
    end
end
endmodule



