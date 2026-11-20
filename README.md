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
  - 
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

# DECLARACIÓN DEL USO DE IA:
Para el proyecto fue necesario el uso de IA principalmente Gemini IA y CLuade. Los usos que se le dierona estas fue la generación/acompañamiento del desarrollo del codigo en los diferentes modulos, generación de imagenes y consultación de información requerida durante el proyecto. A continuación presentamos todos los usos de estas dos IAs en nuestro proyecto:
   - Para el modulo de entradas lógicas se utilizo la IA para generar el codigo que representa la FSM y asignar los valores BCD a cada posición de la matriz de botones.
   - Para el modulo de conversión de BCD a IEEE 754, se genero el código totalmente con Gemini IA, en donde se le envió el diagrama del diseño y la explicación del funcionamiento para que   genere 
