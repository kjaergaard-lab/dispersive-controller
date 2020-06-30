library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.Serial.all;
use work.CustomTypes.all; 

entity topmod is
port (	clk100x			:	in	std_logic;
		ledvec			:	out	std_logic_vector(7 downto 0);
--		SW				:	in	std_logic_vector(3 downto 0);
		TxD				:	out	std_logic;
		RxD				:	in	std_logic;
			
		dispShutterOut	:	out	std_logic;
		dispShutterIn	:	in	std_logic;
		dispAOMIn		:	in	std_logic;
--		dispAOMKIn		:	in	std_logic;
		dispRbOut		:	out	std_logic;
		dispKOut		:	out	std_logic;
		dispTrigIn		:	in	std_logic;
		digitizerOut	:	out	std_logic
		);	
end topmod;

architecture Behavioral of topmod is

-------------------------------------------------------
-----------------  Clock Components  ------------------
-------------------------------------------------------
component DCM1
port
 (-- Clock in ports
  CLK_IN1           : in     std_logic;
  -- Clock out ports
  CLK_OUT1          : out    std_logic;
  CLK_OUT2          : out    std_logic;
  CLK_OUT3          : out    std_logic
 );
end component;

-------------------------------------------------------
----------  Serial Communication Components  ----------
-------------------------------------------------------

component SerialCommunication is
generic(
	BAUD_PERIOD	:	integer
);									--Baud period appropriate for clk					
port(	
	clk 			: 	in  std_logic;							--Clock signal
	RxD				:	in	std_logic;							--Input RxD from a UART signal
	TxD				:	out std_logic;							--Serial transmit pin

	bus_in			:	in	t_serial_bus_slave;					--Input bus from slave
	bus_out			:	out	t_serial_bus_master					--Output bus from master
);
end component;

-------------------------------------------------------
----------------  Dispersive Components  --------------
-------------------------------------------------------

component Dispersive_Control
port(
	clk		:	in	std_logic;
	trig_i	:	in	std_logic;

	params_i:	in 	t_param_disp_array(MAX_DISP-1 downto 0);
	disp_o	:	out	t_disp
);
end component;

signal clk100, clk50, clk10, clk	:	std_logic;

------------------------------------------------------------------------------------
----------------------Serial interface signals--------------------------------------
------------------------------------------------------------------------------------
signal ser_bus		:	t_serial_bus	:=	INIT_SERIAL_BUS;
signal autoFlag		:	std_logic		:=	'1';

signal leds		:	std_logic_vector(7 downto 0)	:=	(others => '0');	--Vector to wire to bank of LEDs


------------------------------------------------------------------------------------
--------------------------Dispersive signals----------------------------------------
------------------------------------------------------------------------------------
signal dispPulseRbMan, dispPulseKMan	:	std_logic	:=	'0';
signal dispTrig, dispTrigMan			:	std_logic	:=	'0';

signal dispParamRb, dispParamK	:	t_param_disp_array(MAX_DISP-1 downto 0)	:=	(others => INIT_DISP);
signal dispRb, dispK			:	t_disp	:=	(others => '0');

------------------------------------------------------------------------------------
----------------------     Other signals      --------------------------------------
------------------------------------------------------------------------------------
signal digitizerSelect	:	std_logic	:=	'0';	--0 for Rb, 1 for K
signal index			:	integer range 0 to 255	:=	0;

begin


-------------------------------------------------------
-----------------  Clock Components  ------------------
-------------------------------------------------------
Inst_dcm1: DCM1 port map (
	CLK_IN1 => clk100x,
	CLK_OUT1 => clk100,
	CLK_OUT2 => clk50,
	CLK_OUT3 => clk10);
	
clk <= clk100;
-------------------------------------------------------
----------  Serial Communication Components  ----------
-------------------------------------------------------
SerialCom: SerialCommunication
generic map(
	BAUD_PERIOD => BAUD_PERIOD
)
port map(
	clk			=>	clk,
	RxD			=>	RxD,
	TxD			=>	TxD,

	bus_in		=>	ser_bus.s,
	bus_out		=>	ser_bus.m
);
	
-------------------------------------------------------
----------------  Dispersive Components  --------------
-------------------------------------------------------
RbDispersiveControl: Dispersive_Control 
port map(
	clk		=>	clk,
	trig_i	=>	dispTrig,
	params_i=>	dispParamRb,
	disp_o	=>	dispRb
);

KDispersiveControl: Dispersive_Control 
port map(
	clk		=>	clk,
	trig_i	=>	dispTrig,
	params_i=>	dispParamK,
	disp_o	=>	dispK
);
	
-------------------------------------------------------
---------------  Dispersive Logic  --------------------
-------------------------------------------------------
digitizerOut <= dispRb.trig when digitizerSelect = '0' else dispK.trig;

dispTrig <= (dispTrigIn or dispTrigMan) and autoFlag;
dispRbOut <= (dispAOMIn or dispRb.pulse) when autoFlag = '1' else dispPulseRbMan;
dispKOut <= (dispAOMIn or dispK.pulse) when autoFlag = '1' else dispPulseKMan;

dispShutterOut <= dispShutterIn;


-------------------------------------------------------
------------  Serial command parsing  -----------------
-------------------------------------------------------
index <= to_integer(unsigned(ser_bus.m.cmd(7 downto 0)));
ReadProcess: process(clk) is
begin
	if rising_edge(clk) then
		if ser_bus.m.ready = '1' then
			if ser_bus.m.cmd(31 downto 24) = X"01" then
				autoFlag <= '0';
				ManualCase: case ser_bus.m.cmd(15 downto 8) is
					when X"00" => rw(ser_bus.m,ser_bus.s,dispPulseRbMan);
					when X"01" => rw(ser_bus.m,ser_bus.s,dispPulseKMan);
					when others => null;
				end case;
			elsif ser_bus.m.cmd(31 downto 24) = X"00" then
				autoFlag <= '1';
				dispPulseRbMan <= '0';
				dispPulseKMan <= '0';
				
				AutoCase: case ser_bus.m.cmd(15 downto 8) is
					when X"00" => rw(ser_bus.m,ser_bus.s,digitizerSelect);
					when X"01" => rw(ser_bus.m,ser_bus.s,dispParamRb(index).period);
					when X"02" => rw(ser_bus.m,ser_bus.s,dispParamRb(index).width);
					when X"03" => rw(ser_bus.m,ser_bus.s,dispParamRb(index).numpulses);
					when X"04" => rw(ser_bus.m,ser_bus.s,dispParamRb(index).delay);
					when X"05" => rw(ser_bus.m,ser_bus.s,dispParamK(index).period);
					when X"06" => rw(ser_bus.m,ser_bus.s,dispParamK(index).width);
					when X"07" => rw(ser_bus.m,ser_bus.s,dispParamK(index).numpulses);
					when X"08" => rw(ser_bus.m,ser_bus.s,dispParamK(index).delay);
					when others => null;
				end case;
			end if;
		end if;
	end if;
end process;
	



end Behavioral;

