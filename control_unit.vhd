library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control_unit is
	generic (
		challenge_bits:		positive := 4;
		clock_frequency:	positive := 50;	-- in MHz
		delay_us:			positive := 1000		-- in microseconds
	);
	port (
		clock:	in	std_logic;
		reset:	in	std_logic;
		enable:	in	std_logic;
		
		counter_enable:	out	std_logic;
		counter_reset:	out	std_logic;
		challenge:		out	std_logic_vector(2*challenge_bits - 1 downto 0); 
		store_response:	out	std_logic;
		done:	out	std_logic
	);
end entity control_unit;

architecture fsm of control_unit is
	constant counter_delay_max: positive := clock_frequency * delay_us - 1;
	constant max_challenges: positive := (4**challenge_bits) - 1;

	type state_type is
		( reset_state, enable_state, wait_time, disable, next_challenge, store, all_done);

	signal state, next_state: state_type := reset_state;
	signal wait_counter: natural range 0 to counter_delay_max := 0;
	signal challenge_counter: natural range 0 to max_challenges := 0;
	
	signal last_challenge: boolean := false;
begin

	-- assign outputs
	challenge <= std_logic_vector(to_unsigned(challenge_counter, challenge'length));
	store_response <= '1' when state = store else '0';
	done <= '1' when state = all_done else '0';
	counter_enable <= '1' when (state =  enable_state or state = wait_time) else '0';
	counter_reset <= '0' when state = reset_state else '1';

	-- last challenge logic
	last_challenge <= challenge_counter = max_challenges;

	save_state: process(clock) is
	begin
		if rising_edge(clock) then
			if reset = '0' then
				state <= reset_state;
			elsif enable = '1' then
				state <= next_state;
			end if;
		end if;
	end process save_state;
	
	counter_process: process(clock) is
	begin
		if rising_edge(clock) then
			if reset = '0' then
				wait_counter <= 0;
			elsif state = wait_time then
				if wait_counter < counter_delay_max then
					wait_counter <= wait_counter + 1;
				end if;
			end if;
		end if;
	end process counter_process;

	challenge_process: process(clock) is
	begin
		if rising_edge(clock) then
			if reset = '0' then
				challenge_counter <= 0;
			elsif state = next_challenge then
				if challenge_counter < max_challenges then
					challenge_counter <= challenge_counter + 1;
				end if;
			end if;
		end if;
	end process challenge_process;
	
	transition_function: process(state, wait_counter, last_challenge) is
	begin
		case state is
			when reset_state => next_state <= enable_state;
			when enable_state => next_state <= wait_time;
			when wait_time =>
					if wait_counter = counter_delay_max then
						next_state <= disable;
					else
						next_state <= wait_time;
					end if;
			when disable => next_state <= store;
			when store => next_state <= next_challenge;
			when next_challenge =>
					if last_challenge then
						next_state <= all_done;
					else
						next_state <= store; -- couble be enable_state
					end if;
			when all_done => next_state <= all_done;
			when others => next_state <= reset_state;
		end case;
	end process transition_function;
	
end architecture fsm;
