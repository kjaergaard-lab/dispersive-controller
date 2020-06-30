library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.Constants.all; 

entity topmod is
port (		
	clk100x	:	in	std_logic;
	trig_i		:	in	std_logic;

	--
	-- Serial data signals
	--
	ledvec	:	out	std_logic_vector(7 downto 0);
	TxD		:	out	std_logic;
	RxD		:	in	std_logic;

	--
	-- Dispersive probing signals
	--
	disp_i		:	in 	std_logic;
	pulseRb_o	:	out	std_logic;
	pulseK_o	:	out	std_logic;
	shutter_i	:	in 	std_logic;
	shutter_o	:	out	std_logic;
	digitizer_o	:	out	std_logic
);	
end topmod;

architecture Behavioral of topmod is

-------------------------------------------------------
-----------------  Clock Components  ------------------
-------------------------------------------------------
component DCM1
PORT(
		CLKIN_IN : IN std_logic;          
		CLKIN_IBUFG_OUT : OUT std_logic;
		CLK0_OUT : OUT std_logic;
		CLK2X_OUT : OUT std_logic
		);
end component;

-------------------------------------------------------
----------  Serial Communication Components  ----------
-------------------------------------------------------
component SerialCommunication
	generic (baudPeriod	:	integer;				--Baud period appropriate for clk
	numMemBytes	:	integer);				--Number of bytes in mem data			
	port(	clk 				: 	in  std_logic;		--Clock signal

	--Signals for reading from serial port
	RxD				:	in	std_logic;									--Input RxD from a UART signal
	cmdDataOut		:	out std_logic_vector(31 downto 0);				--32 bit command word
	numDataOut		:	out std_logic_vector(31 downto 0);				--Numerical parameter
	memDataOut		:	out std_logic_vector(8*numMemBytes-1 downto 0);	--Data for memory
	dataFlag		:	in	std_logic_vector(1 downto 0);				--Indicates type of data (mem, num)
	dataReady		:	out 	std_logic;								--Flag to indicate that data is valid

	--Signals for transmitting on serial port
	TxD				:	out std_logic;									--Serial transmit pin
	dataIn			:	in  std_logic_vector(31 downto 0);				--Data to transmit
	transmitTrig	:	in  std_logic;									--Trigger to start transmitting data
	transmitBusy	:	out std_logic);									--Flag to indicate that a transmission is in progress
end component;

component TimingController is
	generic(	ID	:	std_logic_vector(7 downto 0));
	port(	clk			:	in	std_logic;
			
			--Serial data signals
			cmdData			:	in	std_logic_vector(31 downto 0);
			dataReady		:	in	std_logic;
			numData			:	in	std_logic_vector(31 downto 0);
			memData			:	in	mem_data;
			dataFlag		:	inout	std_logic_vector(1 downto 0);
			
			dataToSend		:	out std_logic_vector(31 downto 0);
			transmitTrig	:	out std_logic;
			
			auxOut	:	out std_logic_vector(7 downto 0);
			
			--Physical signals
			trigIn	:	in std_logic;
			dOut	:	out digital_output_bank;
			dIn		:	in	digital_input_bank);
end component;

signal clk50, clk100, clk	:	std_logic;

------------------------------------------------------------------------------------
----------------------Serial interface signals--------------------------------------
------------------------------------------------------------------------------------
signal dataReady		:	std_logic	:=	'0';	--signal from ReadData that says new 32-bit word is ready
signal cmdData, numData	:	std_logic_vector(31 downto 0)	:=	(others => '0');	--command word

signal dataToSend		:	std_logic_vector(31 downto 0)	:=	(others => '0');
signal transmitBusy		:	std_logic;
signal transmitTrig		:	std_logic	:=	'0';

signal memData			:	mem_data	:=	(others => '0');
signal dataFlag, dataFlag0, dataFlag1, dataFlagFF	:	std_logic_vector(1 downto 0)	:=	"00";



------------------------------------------------------------------------------------
----------------------     Other signals      --------------------------------------
------------------------------------------------------------------------------------
signal trigSync			:	std_logic_vector(1 downto 0)	:=	"00";
signal trig, startTrig	:	std_logic	:=	'0';
constant trigHoldOff	:	integer	:=	100000000;	--1 s at 100 MHz
signal trigCount		:	integer	:=	0;

signal dOut	:	std_logic_vector(31 downto 0)	:=	(others => '0');

begin


-------------------------------------------------------
-----------------  Clock Components  ------------------
-------------------------------------------------------
Inst_dcm1: DCM1 port map (
	CLKIN_IN => clk100x,
	CLKIN_IBUFG_OUT => open,
	CLK0_OUT => clk50,
	CLK2X_OUT => clk100);
	
clk <= clk100;
	
-------------------------------------------------------
----------  Serial Communication Components  ----------
-------------------------------------------------------

dataFlag <= dataFlag0 or dataFlag1 or dataFlagFF;

SerialCommunication_inst: SerialCommunication 
generic map(baudPeriod => BAUD_PERIOD,
			numMemBytes => NUM_MEM_BYTES)
port map(
	clk => clk,
	
	RxD => RxD,
	cmdDataOut => cmdData,
	numDataOut => numData,
	memDataOut => memData,
	dataFlag => dataFlag,
	dataReady => dataReady,
	
	TxD => TxD,
	dataIn => dataToSend,
	transmitTrig => transmitTrig,
	transmitBusy => transmitBusy);
	
ledvec <= cmdData(ledvec'length-1 downto 0);

--
-- Input trigger synchronization
--
InputTrigSync: process(clk) is
begin
	if rising_edge(clk) then
		trigSync <= (trigSync(0) & trig_i);
	end if;
end process;

SeqTrigTiming: process(clk) is
begin
	if rising_edge(clk) then
		if (trigSync = "01" or startTrig = '1') and trigCount = 0 then
			trig <= '1';
			trigCount <= trigCount + 1;
		elsif trigCount > 0 and trigCount < trigHoldOff then
			trig <= '0';
			trigCount <= trigCount + 1;
		else
			trig <= '0';
			trigCount <= 0;
		end if;
	end if;
end process;
	

--
-- Main digital timing controller
--
TimingControl: TimingController 
generic map(
	ID => X"00"
)
PORT MAP(
	clk 			=> 	clk,
	cmdData 		=> 	cmdData,
	dataReady 		=> 	dataReady,
	numData 		=> 	numData,
	memData 		=> 	memData,
	dataFlag 		=> 	dataFlag0,
	dataToSend 		=> 	dataToSend,
	transmitTrig	=>	transmitTrig,
	trigIn			=>	trig,
	auxOut 			=> 	open,
	dOut 			=> 	dOut,
	dIn 			=> 	(others => '0')
); 


pulseRb_o <= disp_i or dOut(0);
pulseK_o <= disp_i or dOut(1);
shutter_o <= shutter_i or dOut(2);
digitizer_o <= dOut(3);

-------------------------------------------------------
------------  Serial command parsing  -----------------
-------------------------------------------------------

TopLevelSerialParsing: process(clk) is
begin
	if rising_edge(clk) then
		if dataReady = '1' and cmdData(31 downto 24) = X"FF" then
			startTrig <= '1';
		else
			startTrig <= '0';
		end if;
	end if;
end process;
	



end Behavioral;

