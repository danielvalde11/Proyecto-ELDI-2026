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

always @(*) begin
    normalizado = angulo % 32'sd23592960;

    if (normalizado < 0)
        normalizado = normalizado + 32'sd23592960;

    if (normalizado <= 32'sd5898240) begin
        angulo_reducido = normalizado;
        signo_cos = 0;
        signo_sen = 0;
    end
    else if (normalizado <= 32'sd11796480) begin
        angulo_reducido = 32'sd11796480 - normalizado;
        signo_cos = 1;
        signo_sen = 0;
    end
    else if (normalizado <= 32'sd17694720) begin
        angulo_reducido = normalizado - 32'sd11796480;
        signo_cos = 1;
        signo_sen = 1;
    end
    else begin
        angulo_reducido = 32'sd23592960 - normalizado;
        signo_cos = 0;
        signo_sen = 1;
    end
end

endmodule

module conversor(
    input wire [31:0] flotante,
    output reg signed [31:0] q1616
);

reg signo;
reg [7:0] exponente;
reg [22:0] mantisa;
reg [23:0] significand;
reg [63:0] magnitud;
integer shift_amount;

always @(*) begin
    signo = flotante[31];
    exponente = flotante[30:23];
    mantisa = flotante[22:0];

    significand = 0;
    magnitud = 0;
    shift_amount = 0;
    q1616 = 0;

    if (exponente == 8'hFF) begin
        if (mantisa == 0) begin
            if (signo)
                q1616 = 32'h80000000;
            else
                q1616 = 32'h7FFFFFFF;
        end
        else
            q1616 = 0;
    end
    else if (exponente != 0) begin
        significand = {1'b1, mantisa};

        if (exponente >= 134) begin
            shift_amount = exponente - 134;

            if (shift_amount >= 64)
                magnitud = 64'hFFFFFFFFFFFFFFFF;
            else
                magnitud = {40'b0, significand} << shift_amount;
        end
        else begin
            shift_amount = 134 - exponente;

            if (shift_amount >= 64)
                magnitud = 0;
            else
                magnitud = {40'b0, significand} >> shift_amount;
        end

        if (signo) begin
            if (magnitud >= 64'd2147483648)
                q1616 = 32'h80000000;
            else
                q1616 = -$signed(magnitud[31:0]);
        end
        else begin
            if (magnitud > 64'd2147483647)
                q1616 = 32'h7FFFFFFF;
            else
                q1616 = magnitud[31:0];
        end
    end
end

endmodule

module grados_a_radianes(
    input wire signed [31:0] grados,
    output reg signed [31:0] radianes
);

reg signed [63:0] producto;

always @(*) begin
    producto = grados * 64'sd149922641;
    radianes = producto >>> 20;
end

endmodule
module calculadora_trig(
    input wire clk,
    input wire rst,
    input wire inicio,
    input wire [31:0] angulo_float,
    output reg signed [31:0] coseno,
    output reg signed [31:0] seno,
    output reg listo
);

    reg signed [31:0] grados_reg;
    reg [1:0] estado;

    wire signed [31:0] q1616;
    wire signed [31:0] angulo_reducido;
    wire signo_cos;
    wire signo_sen;
    wire signed [31:0] angulo_radianes;

    wire signed [31:0] cos_cordic;
    wire signed [31:0] sen_cordic;
    wire cordic_busy;
    wire cordic_done;

    wire cordic_inicio;

    localparam ESPERA = 2'b00;
    localparam INICIAR = 2'b01;
    localparam CALCULANDO = 2'b10;

    conversor U1(
        .flotante(angulo_float),
        .q1616(q1616)
    );

    reduccion U2(
        .angulo(grados_reg),
        .angulo_reducido(angulo_reducido),
        .signo_cos(signo_cos),
        .signo_sen(signo_sen)
    );

    grados_a_radianes U3(
        .grados(angulo_reducido),
        .radianes(angulo_radianes)
    );

    assign cordic_inicio = (estado == INICIAR);

    cordic U4(
        .clk(clk),
        .rst(rst),
        .inicio(cordic_inicio),
        .angulo(angulo_radianes),
        .cos(cos_cordic),
        .sen(sen_cordic),
        .A(cordic_busy),
        .B(cordic_done)
    );

    always @(posedge clk) begin
        if (rst) begin
            estado <= ESPERA;
            grados_reg <= 0;
            coseno <= 0;
            seno <= 0;
            listo <= 0;
        end
        else begin
            listo <= 0;

            case (estado)

                ESPERA: begin
                    if (inicio) begin
                        grados_reg <= q1616;
                        estado <= INICIAR;
                    end
                end

                INICIAR: begin
                    estado <= CALCULANDO;
                end

                CALCULANDO: begin
                    if (cordic_done) begin
                        coseno <= signo_cos ? -cos_cordic : cos_cordic;
                        seno <= signo_sen ? -sen_cordic : sen_cordic;
                        listo <= 1;
                        estado <= ESPERA;
                    end
                end

                default: estado <= ESPERA;

            endcase
        end
    end

endmodule