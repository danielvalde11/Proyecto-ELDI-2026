
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { clk }];

set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 } [get_ports { rst }];
set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports { listo_led }];


set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports { seg[6] }]; # CA
set_property -dict { PACKAGE_PIN R10   IOSTANDARD LVCMOS33 } [get_ports { seg[5] }]; # CB
set_property -dict { PACKAGE_PIN K16   IOSTANDARD LVCMOS33 } [get_ports { seg[4] }]; # CC
set_property -dict { PACKAGE_PIN K13   IOSTANDARD LVCMOS33 } [get_ports { seg[3] }]; # CD
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { seg[2] }]; # CE
set_property -dict { PACKAGE_PIN T11   IOSTANDARD LVCMOS33 } [get_ports { seg[1] }]; # CF
set_property -dict { PACKAGE_PIN L18   IOSTANDARD LVCMOS33 } [get_ports { seg[0] }]; # CG
set_property -dict { PACKAGE_PIN H15   IOSTANDARD LVCMOS33 } [get_ports { dp }];     # Punto decimal


set_property -dict { PACKAGE_PIN J17   IOSTANDARD LVCMOS33 } [get_ports { AN[0] }]; # Derecha (Exp Dec)
set_property -dict { PACKAGE_PIN J18   IOSTANDARD LVCMOS33 } [get_ports { AN[1] }]; # Exp Uni
set_property -dict { PACKAGE_PIN T9    IOSTANDARD LVCMOS33 } [get_ports { AN[2] }]; # Signo Exp
set_property -dict { PACKAGE_PIN J14   IOSTANDARD LVCMOS33 } [get_ports { AN[3] }]; # Letra 'E'
set_property -dict { PACKAGE_PIN P14   IOSTANDARD LVCMOS33 } [get_ports { AN[4] }]; # Centésimas
set_property -dict { PACKAGE_PIN T14   IOSTANDARD LVCMOS33 } [get_ports { AN[5] }]; # Décimas
set_property -dict { PACKAGE_PIN K2    IOSTANDARD LVCMOS33 } [get_ports { AN[6] }]; # Signo Mantisa
set_property -dict { PACKAGE_PIN U13   IOSTANDARD LVCMOS33 } [get_ports { AN[7] }]; # Izquierda (Unidades + DP)

set_property -dict { PACKAGE_PIN C17   IOSTANDARD LVCMOS33 } [get_ports { fila_num[0] }]; # JA1
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { fila_num[1] }]; # JA2
set_property -dict { PACKAGE_PIN E18   IOSTANDARD LVCMOS33 } [get_ports { fila_num[2] }]; # JA3
set_property -dict { PACKAGE_PIN G17   IOSTANDARD LVCMOS33 } [get_ports { fila_num[3] }]; # JA4

set_property -dict { PACKAGE_PIN D17   IOSTANDARD LVCMOS33 PULLUP TRUE } [get_ports { col_num[0] }]; # JA7
set_property -dict { PACKAGE_PIN E17   IOSTANDARD LVCMOS33 PULLUP TRUE } [get_ports { col_num[1] }]; # JA8
set_property -dict { PACKAGE_PIN F18   IOSTANDARD LVCMOS33 PULLUP TRUE } [get_ports { col_num[2] }]; # JA9
set_property -dict { PACKAGE_PIN G18   IOSTANDARD LVCMOS33 PULLUP TRUE } [get_ports { col_num[3] }]; # JA10

set_property -dict { PACKAGE_PIN D14   IOSTANDARD LVCMOS33 } [get_ports { fila_op[0] }]; # JB1
set_property -dict { PACKAGE_PIN F16   IOSTANDARD LVCMOS33 } [get_ports { fila_op[1] }]; # JB2
set_property -dict { PACKAGE_PIN G16   IOSTANDARD LVCMOS33 } [get_ports { fila_op[2] }]; # JB3
set_property -dict { PACKAGE_PIN H14   IOSTANDARD LVCMOS33 } [get_ports { fila_op[3] }]; # JB4

set_property -dict { PACKAGE_PIN E16   IOSTANDARD LVCMOS33 PULLUP TRUE } [get_ports { col_op[0] }]; # JB7
set_property -dict { PACKAGE_PIN F13   IOSTANDARD LVCMOS33 PULLUP TRUE } [get_ports { col_op[1] }]; # JB8
set_property -dict { PACKAGE_PIN G13   IOSTANDARD LVCMOS33 PULLUP TRUE } [get_ports { col_op[2] }]; # JB9
set_property -dict { PACKAGE_PIN H16   IOSTANDARD LVCMOS33 PULLUP TRUE } [get_ports { col_op[3] }]; # JB10
set_property -dict { PACKAGE_PIN K15   IOSTANDARD LVCMOS33 } [get_ports { debug_led[0] }];  # LD1
set_property -dict { PACKAGE_PIN J13   IOSTANDARD LVCMOS33 } [get_ports { debug_led[1] }];  # LD2
set_property -dict { PACKAGE_PIN N14   IOSTANDARD LVCMOS33 } [get_ports { debug_led[2] }];  # LD3
set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports { debug_led[3] }];  # LD4
set_property -dict { PACKAGE_PIN V17   IOSTANDARD LVCMOS33 } [get_ports { debug_led[4] }];  # LD5
set_property -dict { PACKAGE_PIN U17   IOSTANDARD LVCMOS33 } [get_ports { debug_led[5] }];  # LD6
set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS33 } [get_ports { debug_led[6] }];  # LD7
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports { debug_led[7] }];  # LD8 (enable_B)
set_property -dict { PACKAGE_PIN T15   IOSTANDARD LVCMOS33 } [get_ports { debug_led[8] }];  # LD9 (enable_A)
set_property -dict { PACKAGE_PIN U14   IOSTANDARD LVCMOS33 } [get_ports { debug_led[9] }];  # LD10 (tecla JB)
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports { debug_led[10] }]; # LD11 (tecla JA)

#LEDs de prueba
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports { debug_led[11] }]; # LD12
set_property -dict { PACKAGE_PIN V14   IOSTANDARD LVCMOS33 } [get_ports { debug_led[12] }]; # LD13
set_property -dict { PACKAGE_PIN V12   IOSTANDARD LVCMOS33 } [get_ports { debug_led[13] }]; # LD14
set_property -dict { PACKAGE_PIN V11   IOSTANDARD LVCMOS33 } [get_ports { debug_led[14] }]; # LD15
