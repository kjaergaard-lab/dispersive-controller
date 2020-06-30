library IEEE;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.ALL;
use ieee.std_logic_unsigned.all; 
use work.Serial.all;

--
--This entity handles serial communication using the UART protocol.  Data
--is received on the RxD pin and transmitted on the TxD pin.  Data transmission
--starts on receipt of a high transmitTrig signal, and a transmitBusy signal is
--asserted while data is transmitted.
--
--Received data is pushed onto the cmdDataOut signal or the numDataOut signal depending
--on the value of dataFlag.  If '0', then cmdDataOut is used, and if '1' then numDataOut
--is used.
--
entity SerialCommunication is
	generic (BAUD_PERIOD	:	integer);								--Baud period appropriate for clk					
	port(	clk 			: 	in  std_logic;							--Clock signal
			RxD				:	in	std_logic;							--Input RxD from a UART signal
			TxD				:	out std_logic;							--Serial transmit pin

			bus_in			:	in	t_serial_bus_slave;					--Input bus from slave
			bus_out			:	out	t_serial_bus_master);				--Output bus from master
end SerialCommunication;

architecture Behavioral of SerialCommunication is

component UART_Receiver
	generic(BAUD_PERIOD	:	integer);							--Baud period in clock cycles
	
	port(	clk 		: 	in  std_logic;						--Clock signal
			dataOut		:	out	std_logic_vector(7 downto 0);	--Output data
			byteReady	:	out	std_logic;						--Signal to register the complete read of a byte
			RxD			:	in	std_logic;						--Input RxD from a UART signal
			baudTickOut	:	out std_logic);						--Output baud tick, used for debugging
end component;

component UART_Transmitter
	generic(BAUD_PERIOD	:	integer);								--Baud period
	
	port(	clk 		: 	in 	std_logic;						--Clock signal
			dataIn		:	in	std_logic_vector(31 downto 0);	--32-bit word to be sent
			trigIn		:	in	std_logic;						--Trigger to send data
			TxD			:	out	std_logic;						--Serial transmit port
			baudTickOut	:	out	std_logic;						--Output for baud ticks for testing
			busy		:	out	std_logic);						--Busy signal is high when transmitting
end component;

component ReadData
	generic(BAUD_PERIOD	:	integer);								--Baud period in clock cycles
				
	port(	clk 		:	in std_logic;							--Clock
			dataIn		:	in	std_logic_vector(7 downto 0);		--1 byte of data from UART_receiver
			byteReady	:	in	std_logic;							--Signal to tell if byte is valid
			cmdDataOut	:	out std_logic_vector(31 downto 0);		--32 bit command word
			numDataOut	:	out std_logic_vector(31 downto 0);		--Numerical parameter
			dataFlag	:	in	std_logic;							--Indicates type of data cmd/num
			dataReady	:	out std_logic);							--Indicates data is ready
end component;


signal 	serialData			: std_logic_vector(7 downto 0)	:= (others => '0');	--data from UART_Receiver
signal	serialDataReady	:	std_logic	:= '0';	--byte ready signal from UART_Receiver

begin

uart_receive: UART_Receiver 
generic map( BAUD_PERIOD => BAUD_PERIOD)
port map(
	clk => clk,
	dataOut => serialData,
	byteReady => serialDataReady,
	RxD => RxD,
	baudTickOut => open);

uart_transmit: UART_Transmitter 
generic map(BAUD_PERIOD => BAUD_PERIOD)
port map(
	clk => clk,
	dataIn => bus_in.data,
	trigIn => bus_in.trig,
	TxD => TxD,
	baudTickOut => open,
	busy => bus_out.busy);
	
assemble_data: ReadData 
generic map(BAUD_PERIOD => BAUD_PERIOD)
port map(
	clk => clk,
	dataIn => serialData,
	byteReady => serialDataReady,
	cmdDataOut => bus_out.cmd,
	numDataOut => bus_out.num,
	dataFlag => bus_in.flag,
	dataReady => bus_out.ready);





end Behavioral;

