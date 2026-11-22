# Proyecto-ELDI-2026
# Guía para reproducción del proyecto Graphing calculator:

Para la reproducción del proyecto se requiere tener los siguientes recursos de hardware y recursos de software:

# Recursos de hardware:
- Tarjeta de desarrollo **Digilent Nexys 4 DDR** (FPGA Artix-7 `xc7a100tcsg324-1`).
- Dos teclados ( Matriz de botones 4x4)
- Dos matrices de LEDs 8X32
- Jumpers macho-hembre
- Cable micro-USB para programación y alimentación

# Recursos de software:
- **Xilinx Vivado 2026.1** (síntesis, simulación comportamental, implementación y generación de bitstream).

# Pasos de construcción del Hardware externo a la FPGA:
 Para poder replicar el proyecto se necesitan hacer las conexiones externar a la FPGA, en donde se conectaran las matrices de LEDs y las matrices de Botones de la siguientes manera:
  # Pasos para la matriz de botones:
  - Conectar 8 jumpers macho-hembra a cada uno de sus pines.
  - La matriz de botones contendra cuatro pines de columnas (C4-C1), los cuales tendran que ser conectados a JA para la matriz 1 y JB para la matriz 2. Es importante que sean conectados en el       siguiente orden: C1 se conectara a la fila superior, primer pin de izquierda a derecha ( o en su defecto al pin donde aparezca un 1 en la FPGA al lado de los pines JA y JB), desde ahi se        conectara los pines faltantes de las columnas en el mismo orden, es decir, C2 ira a la segunda posición de la fila de arriba de la FPGA y los demás seran conectados en ese mismo orden.
  - La matriz de botones contendra cuatro pines de filas (R4-R1), los cuales tendran que ser conectados a JA para la matriz 1 y JB para la matriz 2. Es importante que sean conectados en el          siguiente orden: R1 se conectara a la fila superior, primer pin de izquierda a derecha ( o en su defecto al pin donde aparezca un 1 en la FPGA al lado de los pines JA y JB), desde ahi se        conectara los pines faltantes de las columnas en el mismo orden, es decir, R2 ira a la segunda posición de la fila de abajo de la FPGA y los demás seran conectados en ese mismo orden.
  - Es importante tener en cuenta que los pines de vcc y gnd tanto de JA como de JB tendran que estar desconectados
  # Pasos para la matriz de LEDs:
  - Para la visualización de las funciones trigonométricas se utilizan dos módulos de matrices LED de 8×32 píxeles, conformados por cuatro matrices de 8×8 cada uno. Al conectarlos en cascada, se obtiene una superficie de visualización de 64 columnas y 8 filas, permitiendo representar gráficamente las funciones seno, coseno o ambas simultáneamente.
  - Cada módulo incorpora controladores MAX7219, encargados de gestionar el encendido de los LEDs mediante comunicación serial, reduciendo la cantidad de conexiones necesarias entre las matrices y la FPGA.
  - Para realizar las conexiones se deben seguir los siguientes pasos:
  - **1. Identificar los pines del módulo:** Cada matriz dispone de cinco conexiones principales: VCC, GND, DIN, CS y CLK.
  - **2. Alimentación:** aunque en el datasheet de estas matrices de leds dicen que se debe alimentar con 5V, los 3.3V de la fpga bastan para su alimentación.
  - **3. Comunicación con la FPGA:** Conectar las señales DIN, CLK y CS del primer módulo a tres pines de salida digital disponibles de la tarjeta Nexys 4 DDR. La asignación de estos pines debe coincidir con las restricciones establecidas en el archivo .xdc.
  - **4. Conexión en cascada:** Conectar la salida DOUT del primer módulo a la entrada DIN del segundo módulo. Ambos módulos deben compartir las señales CLK y CS, además de contar con alimentación y tierra adecuadas. De esta manera, los ocho controladores MAX7219 quedan organizados en una cadena de comunicación serial.
  - **5. Control de visualización:**  El módulo Verilog graficadora_top genera las señales DIN, CLK_MAX y CS_MAX para transmitir la información almacenada en la memoria gráfica. Los datos se organizan en paquetes de 16 bits por controlador, permitiendo actualizar las ocho filas de las matrices.
  - **6. Representación de funciones:** La graficadora utiliza el algoritmo CORDIC para calcular 64 puntos de las funciones seno y coseno. Posteriormente, convierte los resultados al rango de filas disponible en la matriz y permite seleccionar la función representada y su amplitud.
   
# Pasos para la replicación del proyecto en vivado:
 ## 1. Creación del proyecto en Vivado
- Abrir **Xilinx Vivado** y seleccionar **Create Project**.
- Asignar un nombre y una ruta sin espacios ni tildes (por ejemplo, `C:/Proyectos/Calculadora_FPGA`) y presionar **Next**.
- Seleccionar **RTL Project**, marcar la casilla **Do not specify sources at this time** y presionar **Next**.
- En la pestaña **Boards**, seleccionar **Nexys4 DDR** (o en la pestaña **Parts** buscar el dispositivo `xc7a100tcsg324-1`), hacer clic en **Next** y finalizar con **Finish**.
 ## 2. Carga de archivos fuente y restricciones
- En el panel izquierdo (**Flow Navigator**), ir a **Add Sources** -> **Add or create design sources** -> **Add Files**, agregar todos los módulos Verilog (`.v`) de la carpeta `rtl/` y presionar **Finish**.
- Ir nuevamente a **Add Sources** -> **Add or create constraints** -> **Add Files**, cargar el archivo `.xdc` de la carpeta `constraints/` (`constraincs.xdc`) y presionar **Finish**.
- *(Opcional para simulación)* Ir a **Add Sources** -> **Add or create simulation sources** -> **Add Files** y agregar los *testbenches* de la carpeta `tb/`.
- En el panel **Sources** (`Design Sources`), verificar que `calculadora_top` sea el módulo principal (*Top-Level*); de lo contrario, hacer clic derecho sobre él y seleccionar **Set as Top**.

 ## 3. Síntesis, implementación y generación del Bitstream
- En **Flow Navigator**, ejecutar **Run Synthesis** y verificar que finalice sin errores en la pestaña *Messages*.
- Ejecutar **Run Implementation** y comprobar en el resumen de tiempos (*Timing Summary*) que no existan violaciones (`WNS >= 0 ns`).
- Hacer clic en **Generate Bitstream** para generar el archivo binario `calculadora_top.bit`.

Por último te quedara hacer las pruebas de funcionamiento correcto, recuerda que en los 8 displays se vera el resultado de las operaciones indicadas.

# LIMITACIONES DEL PROYECTO A TENER EN CUENTA:
## Limitaciones del Diseño

- **Rango de entrada decimal:** Cada operando admite un máximo de 5 dígitos decimales en la etapa de captura BCD (`captura_y_bcd_a_float`), descartando pulsaciones adicionales hasta presionar una tecla de operación o limpieza (`C`).
- **Resolución de visualización:** La etapa de salida (`float_to_bcd_nexys`) trunca el resultado a tres cifras significativas en notación científica (`±X.XX E±YY`), con un exponente decimal de hasta dos dígitos (`00` a `99`).
- **Error de truncamiento en operaciones iterativas:** La división secuencial opera con mantisas de 24 bits (error relativo menor al `0.0003%`) y el bloque trigonométrico CORDIC ejecuta 16 iteraciones en punto fijo `Q3.29` (error relativo menor al `0.1%`).
- **Filtrado mecánico de teclados:** El controlador de entrada (`controlador_entradas`) sincroniza las pulsaciones mediante detección de flanco por barrido completo, pero no incluye filtros antirrebote (*debouncers*) digitales dedicados por columna frente a ruido en cableado externo largo.
- **Estado de integración física vs. simulación:** Durante las pruebas en tarjeta Nexys 4 DDR, el módulo graficador operó de forma independiente, mientras que la integración completa presentó desfases de sincronización en el cruce de dominios de reloj y en la limpieza automática (`auto_clear`). Dichos fallos fueron corregidos en el código Verilog y validados mediante simulación comportamental en Vivado.

## Manejo de Casos Extremos y Condiciones de Frontera

- **Operando igual a cero (`0.0`):** En el conversor de salida (`float_to_bcd_nexys`), la bandera `Q3_zero` detecta cuando la mantisa es nula y transiciona directamente del estado `S2` al estado `S3`, evitando bucles infinitos de multiplicación por 10.
- **Números negativos y signos en exponentes:** El bit de signo IEEE-754 (`S[31]`) se almacena de forma independiente (`Q1`) para habilitar el signo `-` en el display correspondiente, mientras que los exponentes negativos (`Exp10[7] = 1`) se convierten mediante complemento a dos para mostrar su magnitud y signo en los displays de exponente.
- **Desbordamiento interno de mantisa en multiplicación:** Cuando el producto de las mantisas de 24 bits genera acarreo en el bit más significativo (`J[47] = 1`), el multiplexor `mux_2a1` desplaza automáticamente la mantisa resultante y suma `+1` al exponente sesgado.
- **Reducción de cuadrante en funciones trigonométricas:** Angles fuera del primer cuadrante ($< 0^\circ$ o $> 90^\circ$) se normalizan módulo $360^\circ$ en el bloque `reduccion` y se mapean al rango $[0^\circ, 90^\circ]$ ajustando los signos de seno y coseno (`signo_sen`, `signo_cos`) antes de entrar al núcleo CORDIC.
- **Casos especiales IEEE-754 (`NaN`, $\pm\infty$ y división por cero):** La ALU no implementa banderas dedicadas de excepción aritmética. Ante una división por cero (`B = 0`), el divisor secuencial completa sus 24 ciclos sin bloquear la FSM (saturando el resultado), y el conversor de entrada trigonométrica (`conversor`) satura exponentes `8'hFF` a los límites enteros `32'h7FFFFFFF` o `32'h80000000`.
- **Operaciones encadenadas tras `=`:** Al iniciar una nueva operación luego de obtener un resultado, la señal `auto_clear` reinicia los registros de operandos simultáneamente con la captura del primer dígito ingresado.

## Decisiones de Diseño y Alternativas Descartadas

- **Divisor secuencial (24 ciclos) vs. divisor combinacional:** Se descartó una arquitectura puramente combinacional debido a su alto consumo de LUTs y a un camino crítico extenso que comprometería el cierre de tiempos a `100 MHz`, optando por una FSM iterativa de desplazamiento y resta.
- **ALU multiplexada `4:1` con control de sub-operación (`opcode_alu[2]`):** Permite reutilizar el bloque sumador para la resta (invirtiendo el signo de `B`) y compartir el núcleo CORDIC para obtener seno y coseno con el mismo hardware.
-**Cordic sin Q23.19 y más iteraciones:** Sin q23.29 se acompleja por el uso de decimales, y se usan más iteraciones para generar un resultado más aproximado.
-**Graficar en VGA:** en vez de graficar en una matriz de leds, se pensó hacerlo a través de una pantalla en VGA. 

## Trabajo Futuro

- Incorporar filtros antirrebote (*debouncers*) digitales en las líneas de entrada de ambas matrices $4\times 4$ para aumentar la inmunidad al ruido físico en los puertos Pmod JA/JB.
- Añadir detección y señalización visual de excepciones IEEE-754 (`NaN`, $\pm\infty$ y división por cero) mediante indicadores LED en la tarjeta.
- Completar el acoplamiento físico entre la ALU y el módulo graficador mediante las señales de control `modo_grafica` y `flag_var_x`.

## Declaración de Uso de Inteligencia Artificial

- **Herramienta utilizada:** Google Gemini.
- **Propósito y metodología:** Apoyo en la estructuración modular en Verilog (RTL), diagnóstico de sincronización entre dominios de reloj, generación de plantillas base para *testbenches* de simulación y mapeo de restricciones físicas en `.xdc`. Todo el código fue revisado, simulado y validado por los integrantes del equipo.
- **Archivos con asistencia de IA:**
  - `rtl/calculadora_top.v` (integración de etapas, lógica `auto_clear` y señales de diagnóstico en LEDs)
  - `rtl/float_to_bcd_nexys.v` (FSM de escalado decimal y multiplexación de 8 displays)
  - `tb/` (plantillas base de estímulos para verificación comportamental)
  - `constraints/constraincs.xdc` (asignación de pines Pmod JA/JB y LEDs de diagnóstico)

# DECLARACIÓN DEL USO DE IA:
Para el proyecto fue necesario el uso de IA principalmente Gemini IA y Claude. Los usos que se le dierona estas fue la generación/acompañamiento del desarrollo del codigo en los diferentes modulos, generación de imagenes y consultación de información requerida durante el proyecto. A continuación presentamos todos los usos de estas dos IAs en nuestro proyecto:
- **Módulo de entradas lógicas (`Entradas y sumas/entradas.v`):** Se utilizó la IA para generar el código que representa la FSM y asignar los valores BCD a cada posición de la matriz de botones.
-**Módulo de Cordic (`Seno.v`):** Se utilizó la IA para entender el algoritmo de Cordic, y para convertir de sistema IEEE 754 a q23.29.
-**Módulo de graficadora (`generador_angulo.v`):** Se generó la parte del flujjo de datos a través del módulo MAX7219,y se usó como apoyo para el módulo de generador de coordenadas.
- **Módulo de conversión de BCD a IEEE 754 (`ConverterBCD to IEEE754/Verilogcode.v`):** Se generó el código totalmente con Gemini IA, enviándole el diagrama del diseño y la explicación del  funcionamiento para que implementara el código según el diseño planteado.
- **Lógica de división (`Divider Logic/Verilog code.v`):** Se pidió generar el código para el proceso de división secuencial de la mantisa.
- **Módulo de salidas (`Output logic/Output_logic.v`):** Se generó el código totalmente con Gemini IA, subiendo el diagrama del diseño y explicando la lógica requerida para guiar la generación del código.
- Se le envio a Gemini IA todos los códigos del repositorio ( excluyendo el de la graficadora) para poder unirlos y generar el codigo final que cumple con la graficadora básica.
- Se le envio a Claude los diagramas realizados a mano para que generara la imagen de estos mismos.
