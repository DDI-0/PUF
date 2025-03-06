library ieee;
use ieee.std_logic_1164.all;

entity ring_oscillator is
	generic (
		ro_length:	positive	:= 13
	);
	port (
		enable:		in	std_logic;
		osc_out:	out	std_logic
	);
end entity ring_oscillator;

architecture gen of ring_oscillator is
	-- declare any signals you may need
	signal ro_chain: std_logic_vector(0 to ro_length - 1);
	attribute keep: boolean;
	attribute keep of ro_chain: signal is true;
	
	-- issue supposed to be 12 but generating 13 not gates?
	
begin
	assert ro_length mod 2 = 1
		report "ro_length must be an odd number"
		severity failure;

	-- TODO: place nand gate
	-- one input is enable, the other one the output of the last inverter
	-- output goes into the first inverter in the chain
	ro_chain(0) <= enable nand ro_chain(ro_length - 1);

	--  place inverters
	inverters: for i in 1 to ro_length - 1 generate
		ro_chain(i) <= not ro_chain(i - 1);
	end generate inverters;
	

	-- drive osc_out with output of last inverter in the chain
	osc_out <= ro_chain(ro_length - 1);
end architecture gen;
