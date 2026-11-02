module cordic(
    input wire clk,
    input wire rst,
    input wire inicio,
    input wire signed [31:0] angulo,
    output reg signed [31:0] cos,
    output reg signed [31:0] sen,
    output reg A,
    output reg B
);
    reg signed [31:0] x;
    reg signed [31:0] y;
    reg signed [31:0] z;
    reg signed [31:0] xn;
    reg signed [31:0] yn;
    reg signed [31:0] zn;
    reg [4:0] i;    
    wire signed [31:0] angulo_rom;
    arctan ROM(
        .direccion(i),
        .dato(angulo_rom)
    );
    always @(*) begin
        if (z >= 0) begin
            xn = x - (y >>> i);
            yn = y + (x >>> i);
            zn = z - angulo_rom;
        end
        else begin
            xn = x + (y >>> i);
            yn = y - (x >>> i);
            zn = z + angulo_rom;
        end
    end
    always @(posedge clk) begin
        if (rst) begin
            x <= 32'sd326016437;
            y <= 32'sd0;
            z <= 32'sd0;
            i <= 0;
            cos <= 0;
            sen <= 0;
            A <= 0;
            B <= 0;
        end
        else begin
            B <= 0;
            if (inicio && !A) begin
                x <= 32'sd326016437;
                y <= 32'sd0;
                z <= angulo;
                i <= 0;
                A <= 1;
            end
            else if (A) begin
                x <= xn;
                y <= yn;
                z <= zn;
                if (i == 15) begin
                    cos <= xn;
                    sen <= yn;
                    A <= 0;
                    B <= 1;
                end
                else begin
                    i <= i + 1;
                end
            end
        end
    end
endmodule
module arctan(
    input wire [4:0] direccion,
    output reg signed [31:0] dato
);
    always @(*) begin
        case (direccion)
            0: dato = 32'sd421657428;
            1: dato = 32'sd248918915;
            2: dato = 32'sd131521918;
            3: dato = 32'sd66762579;
            4: dato = 32'sd33510843;
            5: dato = 32'sd16771758;
            6: dato = 32'sd8387925;
            7: dato = 32'sd4194219;
            8: dato = 32'sd2097145;
            9: dato = 32'sd1048575;
            10: dato = 32'sd524288;
            11: dato = 32'sd262144;
            12: dato = 32'sd131072;
            13: dato = 32'sd65536;
            14: dato = 32'sd32768;
            15: dato = 32'sd16384;
            default: dato = 0;
        endcase
    end
endmodule
module reduccion(
    input wire signed [31:0] angulo,
    output reg signed [31:0] angulo_reducido,
    output reg signo_cos,
    output reg signo_sen
);
reg signed [31:0] normalizado;
always @(*)begin
    normalizado=angulo%360;
    if(normalizado<0)
        normalizado = normalizado + 360;
    if(normalizado<=90) begin
        angulo_reducido=normalizado;
        signo_cos=0;
        signo_sen=0;
    end
    else if (normalizado <=180) begin
        angulo_reducido=180-normalizado;
        signo_cos=1;
        signo_sen=0;
    end
    else if (normalizado <=270) begin
        angulo_reducido= normalizado-180;
        signo_cos=1;
        signo_sen=1;
    end
    else if (normalizado <=360) begin
        angulo_reducido = 360-normalizado;
        signo_cos=0;
        signo_sen=1;
    end
end
endmodule