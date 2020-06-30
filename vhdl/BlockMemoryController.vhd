library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.Constants.all; 

entity BlockMemoryController is
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
end BlockMemoryController;

architecture Behavioral of BlockMemoryController is

COMPONENT BlockMem
  PORT (
    clka : IN STD_LOGIC;
    ena : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(39 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(39 DOWNTO 0)
  );
END COMPONENT;


signal memEnable				:	std_logic	:=	'0';
signal memWriteEnable			:	std_logic_vector(0 downto 0)	:=	"0";
signal memAddrIn				:	std_logic_vector(MEM_ADDR_WIDTH-1 downto 0)	:=	(others => '0');
signal memDataOut, memDataIn	:	mem_data;

signal memState					:	integer range 0 to 4	:=	0;

begin

BlockMemory : BlockMem
  PORT MAP (
    clka => clk,
    ena => memEnable,
    wea => memWriteEnable,
    addra => memAddrIn,
    dina => memDataIn,
    douta => memDataOut
  );
  
 
BlockMemRW: process(clk) is
	begin
		if rising_edge(clk) then
			MemoryFSM: case memState is
				when 0 =>
					memDataValid <= '0';
					if memWriteTrig = '1' then
						memAddrIn <= std_logic_vector(memWriteAddr);
						memEnable <= '1';
						memState <= 1;
						memDataIn <= dataIn;
					elsif memReadTrig = '1' then
						memAddrIn <= std_logic_vector(memReadAddr);
						memEnable <= '1';
						memState <= 3;
						memWriteEnable <= "0";
					else
						memEnable <= '0';
					end if;
					
				--Write states are memState 1 and 2
				when 1 =>
					memEnable <= '1';
					memWriteEnable <= "1";
					memState <= 2;
				when 2 =>
					memEnable <= '0';
					memWriteEnable <= "0";
					memState <= 0;	--return to start
					
				--Read states are 3 and 4
				when 3 =>
					memEnable <= '1';
					memState <= 4;
				when 4 =>
					dataOut <= memDataOut;
					memDataValid <= '1';
--					memEnable <= '0';
					memState <= 0;
					
				when others => null;
			end case;	--end MemoryFSM
		end if;	--end rising_edge(clk)
end process;



end Behavioral;

