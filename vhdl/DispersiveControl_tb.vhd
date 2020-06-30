library IEEE;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.ALL;
use ieee.std_logic_unsigned.all; 
use work.CustomTypes.all;
 
ENTITY DispersiveControl_tb IS
END DispersiveControl_tb;
 
ARCHITECTURE behavior OF DispersiveControl_tb IS 
 
component Dispersive_Control is
port(
	clk		:	in	std_logic;
	trig_i	:	in	std_logic;

	params_i:	in 	t_param_disp_array(MAX_DISP-1 downto 0);
	disp_o	:	out	t_disp
);
end component;

constant clkPeriod	:	time	:=	10 ns;

signal clk, trig_i	:	std_logic	:=	'0';
signal params			:	t_param_disp_array(MAX_DISP-1 downto 0)	:=	(others => INIT_DISP);
signal disp				:	t_disp	:=	(others => '0');
 
BEGIN

uut: Dispersive_Control
port map(
	clk		=>	clk,
	trig_i	=>	trig_i,
	params_i	=>	params,
	disp_o	=>	disp
);

Clocking:process is
begin
	clk <= '0';
	wait for clkPeriod/2;
	clk <= '1';
	wait for clkPeriod/2;
end process;

Main: process is
begin
	params(0) <= (period => to_unsigned(10,32), width => to_unsigned(5,32), numpulses => to_unsigned(5,16), delay => to_unsigned(0,32));
	params(1) <= (period => to_unsigned(5,32), width => to_unsigned(2,32), numpulses => to_unsigned(10,16), delay => to_unsigned(0,32));
	params(2) <= (period => to_unsigned(10,32), width => to_unsigned(5,32), numpulses => to_unsigned(0,16), delay => to_unsigned(0,32));
	params(3) <= (period => to_unsigned(10,32), width => to_unsigned(5,32), numpulses => to_unsigned(0,16), delay => to_unsigned(0,32));
	trig_i <= '0';
	wait for 100 ns;
	wait until clk'event and clk = '1';
	trig_i <= '1';
	wait until clk'event and clk = '1';
	trig_i <= '0';
	wait for 100*clkPeriod;
	
end process;


END;
