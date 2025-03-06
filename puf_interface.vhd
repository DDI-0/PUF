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
        interrupt  : out std_logic;              -- Interrupt line

        -- PUF Control Signals
        puf_start  : out std_logic;              -- Signal to start the PUF
        puf_done   : in  std_logic;              -- Signal indicating PUF completion
        puf_output : in  std_logic_vector(255 downto 0) -- 256-bit PUF output (shift register)
    );
end entity puf_interface;
	
architecture rtl of puf_interface is
    -- Control/Status Register Bit Positions
    constant reset_n_BIT     : integer := 0;
    constant INT_CLEAR     : integer := 1;
    constant INT_ENABLE    : integer := 2;
    constant DONE_BIT      : integer := 3;

    -- Register Storage
    signal control_status  : std_logic_vector(31 downto 0) := (others => '0');
    signal irq_flag        : std_logic := '0';
    signal puf_start_reg   : std_logic := '0';
begin
    -- Avalon-MM Read Process
    process (clk)
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                readdata <= (others => '0');
            elsif read = '1' then
                case address is
                    when "00000" => 
                        -- Control/Status Register
                        readdata <= control_status;
                        readdata(31 downto 24) <= "00000010"; -- Revision = 2
                        readdata(23 downto 3)  <= (others => '0'); -- Reserved bits
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

    -- Avalon-MM Write and PUF Control Logic
    process (clk)
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                control_status <= (others => '0');
                irq_flag <= '0';
                puf_start_reg <= '0';
            else
                -- Handle PUF completion and interrupt flag
                if puf_done = '1' then
                    control_status(DONE_BIT) <= '1'; -- Set done flag
                    if control_status(INT_ENABLE) = '1' then
                        irq_flag <= '1'; -- Assert interrupt if enabled
                    end if;
                end if;

                -- Handle Avalon-MM writes
                if write = '1' then
                    case address is
                        when "00000" => 
                            -- Only allow writes to modifiable bits
                            control_status(reset_n_BIT)   <= writedata(reset_n_BIT);
                            control_status(INT_ENABLE)  <= writedata(INT_ENABLE);
                            if writedata(INT_CLEAR) = '1' then
                                irq_flag <= '0'; -- Clear interrupt
                            end if;
                        when others => 
                            null; -- Ignore writes to read-only registers
                    end case;
                end if;

                -- Handle PUF start signal
                if control_status(reset_n_BIT) = '0' then
                    puf_start_reg <= '1'; -- Start PUF when reset_n bit is deasserted
                else
                    puf_start_reg <= '0';
                end if;
            end if;
        end if;
    end process;

    -- Assign outputs
    puf_start <= puf_start_reg;
    interrupt <= irq_flag;
end architecture rtl;