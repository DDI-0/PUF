library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity puf_interface is
    port (
        -- Avalon-MM Interface Signals
        clk        : in  std_logic;              -- Clock for memory-mapped interface
        reset_n    : in  std_logic;              -- Active-low reset_n for memory-mapped interface
        read       : in  std_logic;              -- Avalon agent read request
        write      : in  std_logic;              -- Avalon agent write request
        address    : in  std_logic_vector(4 downto 0); -- Avalon agent address
        writedata  : in  std_logic_vector(31 downto 0); -- Avalon agent write data channel
        readdata   : out std_logic_vector(31 downto 0); -- Avalon agent read data channel
        interrupt  : out std_logic              -- Interrupt line

    );
end entity puf_interface;
	
architecture rtl of puf_interface is
    -- Control/Status Register Bit Positions
	type control_status_bits_type is
		( PUF_RESET, PUF_ENABLE, INT_ENABLE, PUF_DONE, INT_CLEAR );
    constant PUF_RESET_BIT     : natural := control_status_bits_type'pos(PUF_RESET);	-- RW
	constant PUF_ENABLE_BIT    : natural := control_status_bits_type'pos(PUF_ENABLE);	-- RW
    constant INT_ENABLE_BIT    : natural := control_status_bits_type'pos(INT_ENABLE);	-- RW
    constant PUF_DONE_BIT      : natural := control_status_bits_type'pos(PUF_DONE);	-- RO, WRITE IGNORED
    constant INT_CLEAR_BIT     : natural := control_status_bits_type'pos(INT_CLEAR);	-- WO, RAZ


    -- Register Storage
    signal control_status  : std_logic_vector(31 downto 0) := (others => '0');
	signal puf_done_signal : std_logic_vector(0 to 1);
    signal irq_flag        : std_logic := '0';
    signal puf_start_reg   : std_logic := '0';
	
	signal interrupt_pending : std_logic;

	-- control signals for the PUF
	alias puf_reset_signal: std_logic is control_status(PUF_RESET_BIT);
	alias puf_enable_signal: std_logic is control_status(PUF_ENABLE_BIT);
	-- control signal for the interrupt
	alias interrupt_enable: std_logic is control_status(INT_ENABLE_BIT);
	
	-- puf response
	signal puf_output: std_logic_vector(255 downto 0);
begin

	-- drive interrupt logic
	interrupt_logic: process(clk) is
	begin
		if rising_edge(clk) then
			if reset_n = '0' then
				interrupt_pending <= '0';
			elsif write = '1' and address = "00000" and writedata(INT_CLEAR_BIT) = '1' then
				interrupt_pending <= '0';
			elsif puf_done_signal = "10" then
				interrupt_pending <= '1';
			end if;
			interrupt <= interrupt_pending and interrupt_enable;
		end if;
	end process interrupt_logic;

	done_rising_edge: process(clk) is
	begin
		if rising_edge(clk) then
			if reset_n = '0' then
				puf_done_signal(1) <= '0';
			else
				puf_done_signal(1) <= puf_done_signal(0);
			end if;
		end if;
	end process done_rising_edge;

    -- Avalon-MM Read Process
    process (clk)
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                readdata <= (others => '0');
				-- puf_done_signal(1) <= '0';
			elsif write = '1' then
					if address = "00000" then
						control_status(INT_ENABLE_BIT downto PUF_RESET_BIT) <= writedata(INT_ENABLE_BIT downto PUF_RESET_BIT);
					end if;
            elsif read = '1' then
                case address is
                    when "00000" => 
                        -- Control/Status Register
						readdata(INT_CLEAR_BIT) <= '0';
						readdata(PUF_DONE_BIT) <= puf_done_signal(0);
						readdata(PUF_ENABLE_BIT) <= puf_enable_signal;
						readdata(INT_ENABLE_BIT) <= interrupt_enable;
						readdata(PUF_RESET_BIT) <= puf_reset_signal;
                        readdata(31 downto 24) <= "00000010"; -- Revision = 2
                        readdata(23 downto 4)  <= (others => '0'); -- Reserved bits
						-- readdata(3) <= puf_done_signal(0);
                    when "00001" => readdata <= puf_output(31 downto 0);   -- rng[0] (bits 31:0)
                    when "00010" => readdata <= puf_output(63 downto 32);  -- rng[1] (bits 63:32)
                    when "00011" => readdata <= puf_output(95 downto 64);  -- rng[2] (bits 95:64)
                    when "00100" => readdata <= puf_output(127 downto 96); -- rng[3] (bits 127:96)
                    when "00101" => readdata <= puf_output(159 downto 128);-- rng[4] (bits 159:128)
                    when "00110" => readdata <= puf_output(191 downto 160);-- rng[5] (bits 191:160)
                    when "00111" => readdata <= puf_output(223 downto 192);-- rng[6] (bits 223:192)
                    when "01000" => readdata <= puf_output(255 downto 224);-- rng[7] (bits 255:224)
                    when others => readdata <= (others => '0');           -- Undefined addresses
                end case;
            end if;
        end if;
    end process;

	puf_instance: entity work.puf_toplevel
		generic map (
			challenge_bits =>	4,
			clock_frequency =>	50,
			delay_us =>			1,
			ro_length =>		13,
			ro_count =>			32
		)
		port map (
			clock =>		clk,
			puf_reset =>	puf_reset_signal,
			puf_enable =>	puf_enable_signal,
			puf_done =>		puf_done_signal(0),
			shift_reg =>	puf_output
		);

end architecture rtl;
