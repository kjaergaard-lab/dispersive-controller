library IEEE;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.ALL;
use ieee.std_logic_unsigned.all; 

--Reads one byte of data in from RxD based on global constant BaudPeriod (found in CustomTypes).
--Assumes that there are 8 data bits, 1 start bit, 1 stop bit, and no parity bits
entity SerialCommunication is
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
end SerialCommunication;

architecture Behavioral of SerialCommunication is

component UART_Receiver
	generic( baudPeriod	:	integer);
	
	port(	clk 			: in  std_logic;	--Assumed to be 50 MHz clock
			dataOut		:	out	std_logic_vector(7 downto 0);	--Output data
			byteReady	:	out	std_logic;	--Signal to register the complete read of a byte
			RxD			:	in	std_logic;	--Input RxD from a UART signal
			baudTickOut	:	out std_logic);	--Output baud tick, used for debugging
end component;

component UART_Transmitter
	generic(	baudPeriod	:	integer);
	
	port(	clk 			: 	in std_logic;	--
			dataIn		:	in	std_logic_vector(31 downto 0);	--32-bit word to be sent
			trigIn		:	in	std_logic;	--Trigger to send data
			TxD			:	out	std_logic;	--Serial transmit port
			baudTickOut	:	out	std_logic;	--Output for baud ticks for testing
			busy			:	out	std_logic);	--Busy signal is high when transmitting
end component;

component ReadData
	generic(	baudPeriod	:	integer;
				numMemBytes	:	integer);
				
	port(	clk 			:	in std_logic;								--Clock
			dataIn		:	in	std_logic_vector(7 downto 0);				--1 byte of data from UART_receiver
			byteReady	:	in	std_logic;									--Signal to tell if byte is valid
			cmdDataOut	:	out	std_logic_vector(31 downto 0);				--32 bit command word
			numDataOut	:	out std_logic_vector(31 downto 0);				--Numerical parameter
			memDataOut	:	out std_logic_vector(8*numMemBytes-1 downto 0);	--Data for memory
			dataFlag		:	in	std_logic_vector(1 downto 0);			--Indicates type of data (mem, num)
			dataReady	:	out std_logic);									--Indicates data is ready
end component;


signal 	serialData			: std_logic_vector(7 downto 0)	:= (others => '0');	--data from UART_Receiver
signal	serialDataReady	:	std_logic	:= '0';	--byte ready signal from UART_Receiver

begin

uart_receive: UART_Receiver 
generic map( 	baudPeriod => baudPeriod)
port map(
	clk => clk,
	dataOut => serialData,
	byteReady => serialDataReady,
	RxD => RxD,
	baudTickOut => open);
	
uart_transmit: UART_Transmitter 
generic map(	baudPeriod => baudPeriod)
port map(
	clk => clk,
	dataIn => dataIn,
	trigIn => transmitTrig,
	TxD => TxD,
	baudTickOut => open,
	busy => transmitBusy);
	
read_data: ReadData 
generic map(	baudPeriod => baudPeriod,
					numMemBytes => numMemBytes)
port map(
	clk => clk,
	dataIn => serialData,
	byteReady => serialDataReady,
	cmdDataOut => cmdDataOut,
	numDataOut => numDataOut,
	memDataOut => memDataOut,
	dataFlag => dataFlag,
	dataReady => dataReady);





end Behavioral;

