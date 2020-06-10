onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider TB
add wave -noupdate /uart_tb/clk
add wave -noupdate /uart_tb/rst
add wave -noupdate /uart_tb/tx_rx
add wave -noupdate /uart_tb/tx_start
add wave -noupdate /uart_tb/tx_data
add wave -noupdate /uart_tb/tx_busy
add wave -noupdate -divider UART_TX
add wave -noupdate /uart_tb/UART_TX/state
add wave -noupdate /uart_tb/UART_TX/clk_counter
add wave -noupdate /uart_tb/UART_TX/data_sampled
add wave -noupdate /uart_tb/UART_TX/bit_counter
add wave -noupdate -divider UART_FIFO
add wave -noupdate /uart_tb/UART_TX/TX_UART_FIFO/clk
add wave -noupdate /uart_tb/UART_TX/TX_UART_FIFO/rst
add wave -noupdate /uart_tb/UART_TX/TX_UART_FIFO/push
add wave -noupdate /uart_tb/UART_TX/TX_UART_FIFO/pop
add wave -noupdate /uart_tb/UART_TX/TX_UART_FIFO/data_in
add wave -noupdate /uart_tb/UART_TX/TX_UART_FIFO/data_out
add wave -noupdate /uart_tb/UART_TX/TX_UART_FIFO/full
add wave -noupdate /uart_tb/UART_TX/TX_UART_FIFO/empty
add wave -noupdate /uart_tb/UART_TX/TX_UART_FIFO/loop_counter
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 350
configure wave -valuecolwidth 93
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {6760 ns}
