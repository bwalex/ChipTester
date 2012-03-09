onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider CLK_RESET
add wave -noupdate /top/clock

add wave -noupdate -divider AVALON_MM
add wave -noupdate -radix hexadecimal /top/address
add wave -noupdate /top/byteenable
add wave -noupdate -radix hexadecimal /top/readdata
add wave -noupdate /top/read
add wave -noupdate /top/readdataready
add wave -noupdate /top/write
add wave -noupdate -radix hexadecimal /top/writedata
add wave -noupdate /top/waitrequest

add wave -noupdate -divider READ_DATA
add wave -noupdate -radix hexadecimal /top/READDATA

add wave -noupdate -divider SRAM_IF
add wave -noupdate -radix hexadecimal /top/sram_address
add wave -noupdate -radix hexadecimal /top/sram_data
add wave -noupdate /top/sram_ce_n
add wave -noupdate /top/sram_oe_n
add wave -noupdate /top/sram_we_n
add wave -noupdate /top/sram_be_n
TreeUpdate [SetDefaultTree]
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
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
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {150 ns}
