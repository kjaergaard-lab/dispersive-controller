LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use work.Constants.all;

ENTITY TimingController_tb IS
END TimingController_tb;

ARCHITECTURE behavior OF TimingController_tb IS 

component TimingController is
	generic(ID				:	std_logic_vector(7 downto 0));
	port(	clk				:	in	std_logic;
			
			--Serial data signals
			cmdData			:	in	std_logic_vector(31 downto 0);
			dataReady		:	in	std_logic;
			numData			:	in	std_logic_vector(31 downto 0);
			memData			:	in	mem_data;
			dataFlag		:	inout	std_logic_vector(1 downto 0) := "00";
			
			dataToSend		:	out std_logic_vector(31 downto 0);
			transmitTrig	:	out std_logic;
			
			auxOut	:	out std_logic_vector(7 downto 0);
			
			--Physical signals
			trigIn	:	in std_logic;
			dOut	:	out std_logic_vector(31 downto 0);
			dIn		:	in	std_logic_vector(7 downto 0));
end component;

constant clk_period : time := 10 ns;
signal reset    :   std_logic   :=  '0';

signal clk	:	std_logic;
signal cmdData, numData, dataToSend	:	std_logic_vector(31 downto 0)	:=	(others => '0');
signal memData  :   mem_data    :=  (others => '0');
signal transmitTrig, dataReady	:	std_logic	:=	'0';
signal dataFlag :   std_logic_vector(1 downto 0)    :=  "00";

signal trig	:	std_logic	:=	'0';
signal dOut	:	std_logic_vector(31 downto 0)	:=	(others =>	'0');
signal dIn	:	std_logic_vector(7 downto 0)	:=	(others => '0');


signal memReadAddr	:	mem_addr	:=	(others => '0');


signal seqRunning	:	std_logic	:=	'0';
          


constant MEM_DATA	:	mem_data_array(3 downto 0)	:=	(	0	=>	X"0100000000",  --Set all outputs to 0
																		1	=>	X"0000000002",  --Delay 3 cycles  
																		2	=>	X"0100000003",  --Set last two to 11
																		3	=>	X"0000000006"); --Delay four cycles


BEGIN


TC_tb: TimingController
generic map(
	ID => X"00"
)
port map(
	clk				=>	clk,
    cmdData			=>	cmdData,
    dataReady       =>  dataReady,
    numData			=>	numData,
    memData         =>  memData,
	dataFlag		=>	dataFlag,
	dataToSend	    =>	dataToSend,
	transmitTrig	=>	transmitTrig,
    auxOut          =>  open,
    trigIn          =>  trig,
    dOut            =>  dOut,
    dIn             =>  dIn
);


-- Clock process definitions
clk_process :process
begin
	clk <= '0';
	wait for clk_period/2;
	clk <= '1';
	wait for clk_period/2;
end process;


--  Test Bench Statements
tb : PROCESS
BEGIN
	reset <= '0';
--	dataFlag <= "00";
	wait for 100 ns; -- wait until global set/reset completes
	wait until clk'event and clk = '1';
	reset <= '1';
	wait until clk'event and clk = '1';
	reset <= '0';
    wait for clk_period*4;

    --
    -- Reset
    --
    wait until clk'event and clk = '1';
    cmdData <= X"00000004";
    dataReady <= '1';
    wait until clk'event and clk = '1';
    dataReady <= '0';
	 wait for clk_period*2;

    --
    -- Set manual outputs
    --
    wait until clk'event and clk = '1';
    cmdData <= X"00010000";
    dataReady <= '1';
    wait until clk'event and clk = '1';
    dataReady <= '0';
	 wait for clk_period*4;
    wait until clk'event and clk = '1';
    numData <= X"0A003051";
    dataReady <= '1';
    wait until clk'event and clk = '1';
    dataReady <= '0';
	 wait for clk_period*4;

    --
    -- Upload memory data
    --
    wait until clk'event and clk = '1';
    cmdData <= X"00020003";
    dataReady <= '1';
    wait until clk'event and clk = '1';
    dataReady <= '0';
	 wait for clk_period*4;
    wait until clk'event and clk = '1';
    memData <= MEM_DATA(0);
    dataReady <= '1';
    wait until clk'event and clk = '1';
    dataReady <= '0';
	 wait for clk_period*4;
    wait until clk'event and clk = '1';
    memData <= MEM_DATA(1);
    dataReady <= '1';
    wait until clk'event and clk = '1';
    dataReady <= '0';
	 wait for clk_period*4;
    wait until clk'event and clk = '1';
    memData <= MEM_DATA(2);
    dataReady <= '1';
    wait until clk'event and clk = '1';
    dataReady <= '0';
	 wait for clk_period*4;
    wait until clk'event and clk = '1';
    memData <= MEM_DATA(3);
    dataReady <= '1';
    wait until clk'event and clk = '1';
    dataReady <= '0';
	 wait for clk_period*4;

    --
    -- Start sequence
    --
    wait until clk'event and clk = '1';
    cmdData <= X"00000000";
    dataReady <= '1';
    wait until clk'event and clk = '1';
    dataReady <= '0';

	wait for clk_period*4;
	wait until clk'event and clk = '1';
	trig <= '1';
	wait until clk'event and clk = '1';
	trig <= '0';
	
	--
	-- Stop sequence
	--
	wait for clk_period*4*4;
	wait until clk'event and clk = '1';
   cmdData <= X"00000001";
   dataReady <= '1';
   wait until clk'event and clk = '1';
   dataReady <= '0';
	
	
	wait for clk_period*4*20;
	wait until clk'event and clk = '1';
	trig <= '1';
	wait until clk'event and clk = '1';
	trig <= '0';
	

	wait; -- will wait forever
END PROCESS tb;
--  End Test Bench 

END;
