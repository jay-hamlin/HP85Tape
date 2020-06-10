onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /top_tb/DUT/clk
add wave -noupdate /top_tb/DUT/rst_button
add wave -noupdate /top_tb/DUT/rst
add wave -noupdate -divider {HP-85 System}
add wave -noupdate /top_tb/HP85_data
add wave -noupdate /top_tb/HP85_nLMA
add wave -noupdate /top_tb/HP85_nRD
add wave -noupdate /top_tb/HP85_nWR
add wave -noupdate /top_tb/HP85_ph1_clk
add wave -noupdate /top_tb/HP85_ph12_clk
add wave -noupdate /top_tb/HP85_ph2_clk
add wave -noupdate /top_tb/HP85_ph22_clk
add wave -noupdate /top_tb/HP85_output_enable
add wave -noupdate -divider {UART Backend}
add wave -noupdate -divider Protocol_Module
add wave -noupdate /top_tb/DUT/PROTOCOL_MACH_INST/status_register
add wave -noupdate /top_tb/DUT/PROTOCOL_MACH_INST/control_register
add wave -noupdate /top_tb/DUT/PROTOCOL_MACH_INST/control_reg_avail
add wave -noupdate /top_tb/DUT/PROTOCOL_MACH_INST/data_register_from
add wave -noupdate /top_tb/DUT/PROTOCOL_MACH_INST/data_register_to
add wave -noupdate /top_tb/DUT/PROTOCOL_MACH_INST/data_reg_avail
add wave -noupdate /top_tb/DUT/PROTOCOL_MACH_INST/uart_tx
add wave -noupdate /top_tb/DUT/PROTOCOL_MACH_INST/uart_rx
add wave -noupdate /top_tb/DUT/PROTOCOL_MACH_INST/tx_start
add wave -noupdate /top_tb/DUT/PROTOCOL_MACH_INST/tx_data
add wave -noupdate /top_tb/DUT/PROTOCOL_MACH_INST/tx_busy
add wave -noupdate /top_tb/DUT/PROTOCOL_MACH_INST/rx_data
add wave -noupdate /top_tb/DUT/PROTOCOL_MACH_INST/rx_valid
add wave -noupdate /top_tb/DUT/PROTOCOL_MACH_INST/rx_stop_bit_error
add wave -noupdate /top_tb/DUT/PROTOCOL_MACH_INST/misc_register
add wave -noupdate /top_tb/DUT/PROTOCOL_MACH_INST/pkt_byte_0
add wave -noupdate /top_tb/DUT/PROTOCOL_MACH_INST/pkt_byte_1
add wave -noupdate /top_tb/DUT/PROTOCOL_MACH_INST/control_reg_serviced
add wave -noupdate /top_tb/DUT/PROTOCOL_MACH_INST/data_reg_serviced
add wave -noupdate /top_tb/DUT/PROTOCOL_MACH_INST/rx_valid_serviced
add wave -noupdate /top_tb/DUT/PROTOCOL_MACH_INST/pktHdChr
add wave -noupdate /top_tb/DUT/PROTOCOL_MACH_INST/state
add wave -noupdate /top_tb/DUT/PROTOCOL_MACH_INST/tx_pkt_state
add wave -noupdate -divider UART_TX
add wave -noupdate /top_tb/DUT/PROTOCOL_MACH_INST/UART_TX_INST/TX_UART_FIFO/push
add wave -noupdate /top_tb/DUT/PROTOCOL_MACH_INST/UART_TX_INST/TX_UART_FIFO/pop
add wave -noupdate /top_tb/DUT/PROTOCOL_MACH_INST/UART_TX_INST/state
add wave -noupdate /top_tb/DUT/PROTOCOL_MACH_INST/UART_TX_INST/bit_counter
add wave -noupdate /top_tb/DUT/PROTOCOL_MACH_INST/UART_TX_INST/tx
add wave -noupdate -divider UART_RX
add wave -noupdate /top_tb/DUT/PROTOCOL_MACH_INST/UART_RX_INST/rx
add wave -noupdate /top_tb/DUT/PROTOCOL_MACH_INST/UART_RX_INST/data
add wave -noupdate /top_tb/DUT/PROTOCOL_MACH_INST/UART_RX_INST/valid
add wave -noupdate /top_tb/DUT/PROTOCOL_MACH_INST/UART_RX_INST/bit_counter
add wave -noupdate /top_tb/DUT/PROTOCOL_MACH_INST/UART_RX_INST/state
add wave -noupdate /top_tb/TB_UART_TX/push_pulse
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1292370 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits us
update
WaveRestoreZoom {1231448 ns} {1764952 ns}
