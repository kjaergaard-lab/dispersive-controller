library IEEE;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.ALL;
use ieee.std_logic_unsigned.all; 
use work.CustomTypes.all;

 
entity Dispersive_Control is
port(
	clk		:	in	std_logic;
	trig_i	:	in	std_logic;

	params_i:	in 	t_param_disp_array(MAX_DISP-1 downto 0);
	disp_o	:	out	t_disp
);
end Dispersive_Control;

architecture Behavioral of Dispersive_Control is

type t_state_local is (idle, delaying, pulsing);

--Generates a pulse train given a period, pulse width, and number of pulses.  
component PulseGen
port(
	clk         :   in  std_logic;
	cntrl_i     :   in  t_control;
	
	period		:	in	unsigned(31 downto 0);
	width		:	in	unsigned(31 downto 0);
	numpulses	:	in	unsigned(15 downto 0);
	
	pulse_o     :   out std_logic;
	status_o    :   out t_module_status
);
end component;

signal trigSync		:	std_logic_vector(1 downto 0)	:= (others => '0');
signal cntrl		:	t_control	:=	INIT_CONTROL_ENABLED;
signal index		:	integer range 0 to MAX_DISP-1	:=	0;
signal state		:	t_state_local	:=	idle;

signal delayCount	:	unsigned(31 downto 0)	:=	(others => '0');
signal status		:	t_module_status	:=	(others => '0');
signal disp			:	t_disp	:=	(others => '0');

signal params		:	t_param_disp	:=	INIT_DISP;

begin

DispersivePulses: PulseGen 
port map(
	clk			=>	clk,
	cntrl_i		=>	cntrl,
	period		=>	params.period,
	width			=>	params.width,
	numpulses	=>	params.numpulses,
	pulse_o		=>	disp.pulse,
	status_o		=>	status
);
	
disp_o.pulse <= disp.pulse;
disp_o.trig <= disp.pulse;


--
--Synchronously triggers pulse train on rising edge of trigIn
--
PulseTrig: process(clk) is
	begin
		if rising_edge(clk) then
			trigSync <= (trigSync(0),trig_i);
		end if;
end process;


ParameterParse: process(clk) is
begin
	if rising_edge(clk) then
		DispStateMachine: case state is
			--
			-- Default wait for initial trigger
			--
			when idle =>
				index <= 0;
				cntrl <= INIT_CONTROL_ENABLED;
				params <= params_i(0);
				if trigSync = "01" then
					delayCount <= (others => '0');
					state <= delaying;
				else
					delayCount <= (others => '0');
				end if;
				
			--
			-- Count off current delay value
			--
			when delaying =>
				if delayCount < params.delay then
					delayCount <= delayCount + 1;
				else
					cntrl.start <= '1';
					delayCount <= (others => '0');
					state <= pulsing;
				end if;
				
			--
			-- Wait for PulseGen to signal that it is done
			--
			when pulsing =>
				cntrl.start <= '0';
				if status.done = '1' then
					if index < (MAX_DISP - 1) then
						index <= index + 1;
						state <= delaying;
						params <= params_i(index+1);
					else
						index <= 0;
						state <= idle;
					end if;
				end if;

			when others => null;
		end case;
	end if;


end process;




end Behavioral;

