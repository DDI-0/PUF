library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity puf_toplevel is
    generic (
        challenge_bits:     positive := 4;       -- Number of challenge bits
        clock_frequency:    positive := 50;     -- Clock frequency in MHz
        delay_us:           positive := 1;    -- Delay in microseconds
        ro_length:          positive := 13;      -- RO chain length
        ro_count:           positive := 32       -- Number of RO chains
    );
    port (
        -- FPGA clock and reset
        clock:      in  std_logic;               -- FPGA clock
		puf_reset:	in  std_logic;
		puf_enable:	in	std_logic;

		puf_done:	out std_logic;
		shift_reg:	out std_logic_vector(255 downto 0)

    );
end entity puf_toplevel;

architecture structural of puf_toplevel is
    -- Internal signals
    signal counter_enable: std_logic;
    signal counter_reset:  std_logic;
    signal challenge: std_logic_vector(7 downto 0);  
    signal store_response: std_logic;
    signal puf_response:   std_logic;

	signal puf_response_data: std_logic_vector(shift_reg'range);

begin
	shift_reg <= puf_response_data;

    -- Instantiate the control unit
    control_unit_inst: entity work.control_unit
        generic map (
            challenge_bits => challenge_bits,
            clock_frequency => clock_frequency,
            delay_us => delay_us
        )
        port map (
            clock => clock,		-- Avalon-MM clock
            reset => puf_reset,  -- comes from the control register
            enable => puf_enable,  -- comes from the control register
			
            counter_enable => counter_enable,
            counter_reset => counter_reset,
            challenge => challenge,
            store_response => store_response,
            done => puf_done
        );

    -- Instantiate the RO PUF
    ro_puf_inst: entity work.ro_puf
        generic map (
            ro_length => ro_length,
            ro_count => ro_count
        )
        port map (
            reset => counter_reset,
            enable => counter_enable,
            challenge => challenge,  -- Connect the challenge signal
            response => puf_response
        );

    -- Shift register process with synchronous reset
    shift_register_process: process(clock)
    begin
        if counter_reset = '0' then  -- Asynchronous reset (active low)
            puf_response_data <= (others => '0');  -- Reset the shift register
        elsif rising_edge(clock) then
            if store_response = '1' then
                puf_response_data <= puf_response_data(shift_reg'high - 1 downto 0) & puf_response;  -- Shift in the response
            end if;
        end if;
    end process shift_register_process;

end architecture structural;
