onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /hp85bus_tb/clk
add wave -noupdate /hp85bus_tb/rst
add wave -noupdate -divider {HP-85 Sysyem Bus}
add wave -noupdate /hp85bus_tb/hp85_ph1_clk
add wave -noupdate /hp85bus_tb/hp85_ph12_clk
add wave -noupdate /hp85bus_tb/hp85_ph2_clk
add wave -noupdate /hp85bus_tb/hp85_ph22_clk
add wave -noupdate /hp85bus_tb/hp85_bus_data
add wave -noupdate /hp85bus_tb/hp85_bus_nLMA
add wave -noupdate /hp85bus_tb/hp85_bus_nRD
add wave -noupdate /hp85bus_tb/hp85_bus_nWR
add wave -noupdate -divider {Backend Interface}
add wave -noupdate /hp85bus_tb/status_reg_wr
add wave -noupdate /hp85bus_tb/control_reg_rd
add wave -noupdate /hp85bus_tb/control_reg_avail
add wave -noupdate /hp85bus_tb/data_reg_wr
add wave -noupdate /hp85bus_tb/data_reg_rd
add wave -noupdate /hp85bus_tb/data_reg_avail
add wave -noupdate /hp85bus_tb/register_data_out
add wave -noupdate /hp85bus_tb/register_data_in
add wave -noupdate /hp85bus_tb/read_data
add wave -noupdate /hp85bus_tb/bus_phase
add wave -noupdate -divider {BUS Interface}
add wave -noupdate /hp85bus_tb/HP85BUS_INTERFACE/latched_address
add wave -noupdate /hp85bus_tb/HP85BUS_INTERFACE/status_register
add wave -noupdate /hp85bus_tb/HP85BUS_INTERFACE/control_register
add wave -noupdate /hp85bus_tb/HP85BUS_INTERFACE/data_register
add wave -noupdate /hp85bus_tb/HP85BUS_INTERFACE/nLMA_event
add wave -noupdate /hp85bus_tb/HP85BUS_INTERFACE/nWR_event
add wave -noupdate /hp85bus_tb/HP85BUS_INTERFACE/nRD_event
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {42746 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 302
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1000
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {31408 ns}
