library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity puf_toplevel is
    generic (
        challenge_bits:     positive := 4;       -- Number of challenge bits
        clock_frequency:    positive := 50;     -- Clock frequency in MHz
        delay_us:           positive := 1000;    -- Delay in microseconds
        ro_length:          positive := 13;      -- RO chain length
        ro_count:           positive := 32       -- Number of RO chains
    );
    port (
        -- FPGA clock and reset
        clock:      in  std_logic;               -- FPGA clock
        reset:      in  std_logic;               -- Asynchronous active-low reset

        -- Avalon-MM Interface Signals
        read       : in  std_logic;              -- Avalon agent read request
        write      : in  std_logic;              -- Avalon agent write request
        address    : in  std_logic_vector(4 downto 0); -- Avalon agent address
        writedata  : in  std_logic_vector(31 downto 0); -- Avalon agent write data channel
        readdata   : out std_logic_vector(31 downto 0); -- Avalon agent read data channel
        interrupt  : out std_logic               -- Interrupt line
    );
end entity puf_toplevel;

architecture structural of puf_toplevel is
    -- Internal signals
    signal counter_enable: std_logic;
    signal counter_reset:  std_logic;
    signal challenge: std_logic_vector(7 downto 0);  -- Adjusted to match ro_puf (8 bits)
    signal store_response: std_logic;
    signal puf_response:   std_logic;

    -- Shift register to store responses (256 bits wide)
    signal shift_reg:      std_logic_vector(255 downto 0) := (others => '0');  -- 256 bits

    -- PUF interface signals
    signal puf_start:      std_logic;  -- Signal to start the PUF
    signal puf_done:       std_logic;  -- Signal indicating PUF completion

    -- Internal signals for done and response
    signal done_internal:  std_logic;  -- Internal done signal
    signal response_internal: std_logic_vector(255 downto 0);  -- Internal response signal

    -- Internal reset signal
    signal internal_reset: std_logic;  -- Internal reset signal for PUF control
begin
    -- Instantiate the control unit
    control_unit_inst: entity work.control_unit
        generic map (
            challenge_bits => challenge_bits,
            clock_frequency => clock_frequency,
            delay_us => delay_us
        )
        port map (
            clock => clock,
            reset => internal_reset,  -- Use internal_reset instead of reset
            enable => '1',  -- Always enabled
            counter_enable => counter_enable,
            counter_reset => counter_reset,
            challenge => challenge,
            store_response => store_response,
            done => done_internal
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

    -- Shift register process with asynchronous reset
    shift_register_process: process(clock, reset)
    begin
        if reset = '0' then  -- Asynchronous reset (active low)
            shift_reg <= (others => '0');  -- Reset the shift register
        elsif rising_edge(clock) then
            if store_response = '1' then
                shift_reg <= shift_reg(shift_reg'high - 1 downto 0) & puf_response;  -- Shift in the response
            end if;
        end if;
    end process shift_register_process;

    -- Output the shift register to internal response signal
    response_internal <= shift_reg;

    -- Instantiate the PUF interface
    puf_interface_inst: entity work.puf_interface
        port map (
            clk => clock,  -- Use the same clock for the Avalon interface
            reset_n => reset,  -- Use the same reset signal (active low)
            read => read,
            write => write,
            address => address,
            writedata => writedata,
            readdata => readdata,
            interrupt => interrupt,

            puf_start => puf_start,
            puf_done => puf_done,
            puf_output => shift_reg  -- Map the full 256-bit shift register to puf_output
        );

    -- Map internal signals
    done_internal <= puf_done;  -- Map the done signal
    response_internal <= shift_reg;  -- Map the shift register to internal response signal

    -- Internal reset logic
    internal_reset <= reset and not puf_start;  -- Reset when either reset is low or puf_start is high

end architecture structural;