proc place_inverters {num_inverters num_chains} {
    set partial_chain [expr ${num_chains} / 2]
    set X_start 10
    set Y_start 72
    set N_start 0

    set x_coord ${X_start}
    set y_coord ${Y_start}
    set chains_per_row 4
    set chain_counter 0

    for {set chain_index 0} {$chain_index < $partial_chain} {incr chain_index} {
        set n_coord ${N_start}
        for {set inverter_index 0} {$inverter_index < $num_inverters} {incr inverter_index} {
            set_location_assignment LABCELL_X${x_coord}_Y${y_coord}_N${n_coord} \
                -to ro_puf:puf|ring_oscillator:\\group_a:${chain_index}:ring_osc_instance|out_stages\[${inverter_index}\]
            incr n_coord 3
            if { ${n_coord} > 42 } {
                set n_coord 0
                incr y_coord -1  ;# Decrement y_coord by 1
            }
        }
        incr x_coord
        incr chain_counter

        if { ${chain_counter} >= ${chains_per_row} } {
            set x_coord ${X_start}
            incr y_coord -1  ;# Decrement y_coord by 1
            set chain_counter 0
        }
    }

    for {set chain_index ${partial_chain}} {$chain_index < $num_chains} {incr chain_index} {
        set n_coord ${N_start}
        for {set inverter_index 0} {$inverter_index < $num_inverters} {incr inverter_index} {
            set_location_assignment LABCELL_X${x_coord}_Y${y_coord}_N${n_coord} \
                -to ro_puf:puf|ring_oscillator:\\group_b:${chain_index}:ring_osc_instance|out_stages\[${inverter_index}\]
            incr n_coord 3
            if { ${n_coord} > 42 } {
                set n_coord 0
                incr y_coord -1  ;# Decrement y_coord by 1
            }
        }
        incr x_coord
        incr chain_counter

        if { ${chain_counter} >= ${chains_per_row} } {
            set x_coord ${X_start}
            incr y_coord -1  ;# Decrement y_coord by 1
            set chain_counter 0
        }
    }
}