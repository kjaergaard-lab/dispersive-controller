library IEEE;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.ALL;
use ieee.std_logic_unsigned.all; 
use work.CustomTypes.all;

--Generates a pulse train given a period, pulse width, and number of pulses.  
--This version is slightly different from versions older than 02/02/2018.
--This version does not have a synchronous trigger, and if Npulses=0
--there is no delay of 1 period before trig_done is raised
entity PulseGen is
    port(
        clk         :   in  std_logic;
        cntrl_i     :   in  t_control;
        
		period		:	in	unsigned(31 downto 0);
		width		:	in	unsigned(31 downto 0);
		numpulses	:	in	unsigned(15 downto 0);
        
        pulse_o     :   out std_logic;
        status_o    :   out t_module_status
    );
end PulseGen;

architecture Behavioral of PulseGen is

type t_status_local is (idle, pulsing, incrementing);

signal state			:	t_status_local	:=	idle;
signal count			:	unsigned(period'length-1 downto 0)		:=	(others => '0');	--Counts clock edges
signal pulseCount		:	unsigned(numpulses'length-1 downto 0)	:=	(others => '0');	--Counts number of pulses

begin

--Generates pulse train
PulseProcess: process(clk) is
begin
	if rising_edge(clk) then
		FSM: case state is
			--
			-- Wait-for-trigger state
			--
			when idle =>
				pulseCount <= (others => '0');
				status_o.done <= '0';
				if cntrl_i.start = '1' then
					if numpulses = 0 then
						state <= incrementing;
						pulse_o <= '0';
						status_o.running <= '0';
					else
						count <= to_unsigned(1,count'length);
						status_o.running <= '1';
						pulse_o <= '1';
						state <= pulsing;
					end if;
				else
					pulse_o <= '0';
					status_o.running <= '0';
				end if;

			--
			-- Pulse creation state
			--
			when pulsing =>
				if count < width then
					count <= count + 1;
					pulse_o <= '1';
				elsif count < period - 1 then
					count <= count + 1;
					pulse_o <= '0';
				else
					count <= to_unsigned(1,count'length);
					pulseCount <= pulseCount + 1;
					state <= incrementing;
				end if;

			--
			-- Increment pulse counter
			--
			when incrementing =>
				if pulseCount < numPulses then
					state <= pulsing;
					pulse_o <= '1';
				else
					state <= idle;
					status_o <= (running => '0', done => '1');
				end if;
				
			when others => null;
		end case;
	end if;
end process;



end Behavioral;

