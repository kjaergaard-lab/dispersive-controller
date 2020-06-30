library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.Constants.all; 


entity TimingController is
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
			dOut	:	out digital_output_bank;
			dIn		:	in	digital_input_bank);
end TimingController;

architecture Behavioral of TimingController is

component BlockMemoryController is
	port(	clk	:	in	std_logic;
			--Write signals
			memWriteTrig	:	in	std_logic;
			memWriteAddr	:	in	mem_addr;
			dataIn			:	in	mem_data;
			
			--Read signals
			memReadTrig		:	in	std_logic;
			memReadAddr		:	in	mem_addr;
			memDataValid	:	out	std_logic;
			dataOut			:	out	mem_data);
end component;

------------------------------------------
----------   Memory Signals   ------------
------------------------------------------
signal maxMemAddr					:	mem_addr	:=	(others => '0');
signal memWriteTrig, memReadTrig	:	std_logic	:=	'0';
signal memWriteAddr, memReadAddr	:	mem_addr	:=	(others => '0');
signal memWriteData, memReadData	:	mem_data	:= 	(others => '0');
signal memDataValid					:	std_logic	:=	'0';

------------------------------------------------------------------------------------
--------------     Sample generator signals      -----------------------------------
------------------------------------------------------------------------------------
constant sampleTime	:	integer range 0 to 4	:=	4;
signal sampleCount	:	integer range 0 to 4	:=	0;
signal sampleTick		:	std_logic	:=	'0';


signal seqEnabled, seqRunning, seqDone	:	std_logic	:=	'0';
signal seqStart, seqStop	:	std_logic	:=	'0';

-----------------------------------------------------
----------   Parse Instruction Signals   ------------
-----------------------------------------------------
constant INSTR_WAIT	:	std_logic_vector(7 downto 0)	:=	X"00";
constant INSTR_OUT	:	std_logic_vector(7 downto 0)	:=	X"01";
constant INSTR_IN	:	std_logic_vector(7 downto 0)	:=	X"02";

signal parseState	:	integer range 0 to 7	:=	0;


----------------------------------------------
--------  Delay Generator Signals   ----------
----------------------------------------------
signal waitTime		:	integer	:=	10;
signal delayCount	:	integer	:=	0;

----------------------------------------------
----------  Digital Out Signals   ------------
----------------------------------------------
signal dOutSig		:	digital_output_bank	:=	(others => '0');
signal dOutManual	:	digital_output_bank	:=	(others => '0');

----------------------------------------------
----------  Digital In Signals   -------------
----------------------------------------------
constant trigRisingEdge		:	std_logic_vector(1 downto 0)	:=	"01";
constant trigFallingEdge	:	std_logic_vector(1 downto 0)	:=	"10";

signal trigBit	:	integer range 0 to 7	:=	0;
signal trigType	:	integer range 0 to 3	:=	0;

signal trigSync	:	digital_input_bank_array(1 downto 0)	:=	(others => (others => '0'));

begin

TimingMemory: BlockMemoryController PORT MAP(
	clk 			=> clk,
	memWriteTrig 	=> memWriteTrig,
	memWriteAddr 	=> memWriteAddr,
	dataIn 			=> memWriteData,
	memReadTrig 	=> memReadTrig,
	memReadAddr 	=> memReadAddr,
	memDataValid 	=> memDataValid,
	dataOut 		=> memReadData
);

dOut <= dOutSig when seqRunning = '1' else dOutManual;

-- auxOut(0) <= masterEnable;
-- auxOut(1) <= sampleTick;
-- auxOut(2) <= waitEnable;
-- auxOut(3) <= seqStart;
-- auxOut(5 downto 4) <= dataFlag;
-- auxOut(7 downto 6) <= (others => '0');

--
-- Generates sample clock
--
SampleGenerator: process(clk) is
begin
	if rising_edge(clk) then
		if sampleCount = 0 then
			if seqRunning = '1' or (trigIn = '1' and seqEnabled = '1') then
				sampleCount <= 1;
				sampleTick <= '1';
			else
				sampleTick <= '0';
			end if;
		elsif sampleCount < (sampleTime-1) then
			sampleTick <= '0';
			sampleCount <= sampleCount + 1;
		else
			sampleTick <= '0';
			sampleCount <= 0;
		end if;
	end if;
end process;

TrigSyncProcess: process(clk) is
begin
	if rising_edge(clk) then
		if seqRunning = '1' then
			trigSync(1) <= trigSync(0);
			trigSync(0) <= dIn;
		end if;
	end if;
end process;


MainProcess: process(clk) is
begin
	if rising_edge(clk) then
		if seqStop = '1' then
			parseState <= 0;
		else
			MainFSM: case parseState is
				--
				-- Wait for start signal
				--
				when 0 =>
					if seqStart = '1' then
						parseState <= 1;
						memReadTrig <= '1';
						seqEnabled <= '1';
					else
						memReadAddr <= (others => '0');
						seqEnabled <= '0';
						memReadTrig <= '0';
						seqDone <= '0';
						seqRunning <= '0';
					end if;

				--
				-- Parse instruction
				--
				when 1 =>
					if sampleTick = '1' and seqDone = '1' then
						memReadTrig <= '1';
						seqDone <= '0';
						parseState <= 1;
						seqRunning <= '0';
					elsif sampleTick = '1' then
						if memReadAddr < maxMemAddr then
							memReadTrig <= '1';
							memReadAddr <= memReadAddr + X"1";
							seqRunning <= '1';
						else
							memReadAddr <= (others => '0');
							seqDone <= '1';
						end if;

						InstrOptions: case memReadData(8*NUM_MEM_BYTES-1 downto 8*(NUM_MEM_BYTES-1)) is
							when INSTR_WAIT =>
								waitTime <= to_integer(unsigned(memReadData(31 downto 0)));	
								delayCount <= 0;
								parseState <= 2;					
								
							when INSTR_OUT =>
								dOutSig <= memReadData(NUM_OUTPUTS-1 downto 0);
								parseState <= 1;
								
							when INSTR_IN =>
								trigBit <= to_integer(unsigned(memReadData(3 downto 0)));
								trigType <= to_integer(unsigned(memReadData(9 downto 8)));
								parseState <= 3;

							when others => parseState <= 1;
						end case;
					else
						memReadTrig <= '0';
					end if;

				--
				-- Delay state
				--
				when 2 =>
					memReadTrig <= '0';
					if sampleTick = '1' and delayCount < (waitTime - 2) then
						delayCount <= delayCount + 1;
					elsif delayCount = (waitTime - 2) then
						parseState <= 1;
					end if;
						
				--
				-- Wait-for-trigger state
				--
				when 3 =>
					memReadTrig <= '0';
					TrigInCase: case(trigType) is
						--
						-- Falling edge
						--
						when 0 =>
							if trigSync(1)(trigBit) = trigFallingEdge(1) and trigSync(0)(trigBit) = trigFallingEdge(0) then
								parseState <= 1;
							end if;
						
						--
						-- Either edge
						--
						when 1 =>
							if (trigSync(1)(trigBit) = trigFallingEdge(1) and trigSync(0)(trigBit) = trigFallingEdge(0)) or (trigSync(1)(trigBit) = trigRisingEdge(1) and trigSync(0)(trigBit) = trigRisingEdge(0)) then
								parseState <= 1;
							end if;

						--
						-- Rising edge
						--
						when 2 =>
							if trigSync(1)(trigBit) = trigRisingEdge(1) and trigSync(0)(trigBit) = trigRisingEdge(0) then
								parseState <= 1;
							end if;
						when others => parseState <= 1;
					end case;

				when others => null;
			end case;
		end if;
	end if;
end process;


SerialInstructions: process(clk) is
begin
	if rising_edge(clk) then
		if dataReady = '1' and cmdData(31 downto 24) = ID then
			SerialOptions: case cmdData(23 downto 16) is
				--Software triggers
				when X"00" =>
					SoftTrigs: case cmdData(7 downto 0) is
						when X"00" => seqStart <= '1';
						when X"01" => seqStop <= '1';
						when X"02" =>
							transmitTrig <= '1';
							dataToSend(31 downto 30) <= (seqEnabled & seqRunning);
							dataToSend(MEM_ADDR_WIDTH-1 downto 0) <= std_logic_vector(memReadAddr);
						when X"03" =>
							transmitTrig <= '1';
							dataToSend <= dOutManual;
						when others => null;
					end case;	--end SoftTrigs
				
				--Manual digital outputs
				when X"01" => getParam(dataFlag(0),numData,dOutManual);
				
				--Memory uploading
				when X"02" =>
					if dataFlag(1) = '0' then
						maxMemAddr <= unsigned(cmdData(MEM_ADDR_WIDTH-1 downto 0));
						memWriteAddr <= (others => '0');
						dataFlag(1) <= '1';
					elsif dataFlag(1) = '1' and memWriteAddr < maxMemAddr then
						memWriteData <= memData;
						memWriteTrig <= '1';
					elsif dataFlag(1) = '1' and memWriteAddr >= maxMemAddr then
						memWriteData <= memData;
						memWriteTrig <= '1';
						dataFlag(1) <= '0';
					end if;
						
					
				when others => null;
			end case;	--end SerialOptions
			
		else
			if memWriteTrig = '1' then
				memWriteTrig <= '0';
				memWriteAddr <= memWriteAddr + X"1";
			end if;
			seqStart <= '0';
			seqStop <= '0';
			transmitTrig <= '0';
		end if;	--end dataReady
	end if;	--end rising_edge(clk)
end process;


end Behavioral;

