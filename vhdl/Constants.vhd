--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.ALL;
use ieee.std_logic_unsigned.all; 

package Constants is

-- type <new_type> is
--  record
--    <type_name>        : std_logic_vector( 7 downto 0);
--    <type_name>        : std_logic;
-- end record;
--
-- Declare constants
--
-- constant <constant_name>		: time := <time_unit> ns;
constant BAUD_PERIOD		:	integer	:= 868;	--With a 100 MHz clock, corresponds to 115200 Hz

constant NUM_MEM_BYTES		:	integer	:=	5;
constant MEM_ADDR_WIDTH     :	integer	:=	11;

constant NUM_OUTPUTS		:	integer	:=	32;
constant NUM_INPUTS			:	integer	:=	8;
constant NUM_FLEX_TRIG		:	integer	:=	3;


type int_array is array (integer range <>) of integer;
subtype mem_data is std_logic_vector(8*NUM_MEM_BYTES-1 downto 0);
subtype mem_addr is unsigned(MEM_ADDR_WIDTH-1 downto 0);
subtype digital_output_bank is std_logic_vector(NUM_OUTPUTS-1 downto 0);
subtype digital_input_bank is std_logic_vector(NUM_INPUTS-1 downto 0);
type digital_input_bank_array is array(integer range <>) of digital_input_bank;

type mem_data_array is array (integer range <>) of mem_data;
-- type ser_data_array is array (integer range <>) of std_logic_vector(31 downto 0);

function slvToInt(
	signal vecIn	: std_logic_vector)
	return integer;
	
procedure getParamSigned(
	signal flagIn	:	inout	std_logic;
	signal dataIn	:	in	std_logic_vector;
	signal param	:	out integer);
	
procedure getParamSigned(
	signal flagIn	:	inout std_logic;
	signal dataIn	:	in std_logic_vector;
	signal paramArray	:	out int_array;
	signal idx		:	in std_logic_vector);

procedure getParam(
	signal flagIn	:	inout	std_logic;
	signal dataIn	:	in	std_logic_vector;
	signal param	:	out integer);
	
procedure getParam(
	signal flagIn	:	inout	std_logic;
	signal dataIn	:	in	std_logic_vector;
	signal param	:	out std_logic_vector);
	
procedure getParam(
	signal flagIn	:	inout	std_logic;
	signal dataIn	:	in	std_logic_vector;
	signal param	:	out unsigned);
	
procedure getParam(
	signal flagIn	:	inout	std_logic;
	signal dataIn	:	in	std_logic_vector;
	signal param	:	out std_logic);
	
procedure getParam(
	signal flagIn	:	inout std_logic;
	signal dataIn	:	in std_logic_vector;
	signal paramArray	:	out int_array;
	signal idx		:	in std_logic_vector);

end Constants;

package body Constants is

procedure getParamSigned(
	signal flagIn	:	inout	std_logic;
	signal dataIn	:	in	std_logic_vector;
	signal param	:	out integer) is
begin
	if flagIn = '0' then
		flagIn <= '1';
	else
		flagIn <= '0';
		param <= to_integer(signed(dataIn));
	end if;
end getParamSigned;

procedure getParamSigned(
	signal flagIn	:	inout std_logic;
	signal dataIn	:	in std_logic_vector;
	signal paramArray	:	out int_array;
	signal idx		:	in std_logic_vector) is
begin
	if flagIn = '0' then
		flagIn <= '1';
	else
		flagIn <= '0';
		paramArray(slvToInt(idx)) <= to_integer(signed(dataIn));
	end if;
end getParamSigned;

procedure getParam(
	signal flagIn	:	inout	std_logic;
	signal dataIn	:	in	std_logic_vector;
	signal param	:	out integer) is
begin
	if flagIn = '0' then
		flagIn <= '1';
	else
		flagIn <= '0';
		param <= to_integer(unsigned(dataIn));
	end if;
end getParam;

procedure getParam(
	signal flagIn	:	inout	std_logic;
	signal dataIn	:	in	std_logic_vector;
	signal param	:	out std_logic_vector) is
begin
	if flagIn = '0' then
		flagIn <= '1';
	else
		flagIn <= '0';
		param <= dataIn(param'length-1 downto 0);
	end if;
end getParam;

procedure getParam(
	signal flagIn	:	inout	std_logic;
	signal dataIn	:	in	std_logic_vector;
	signal param	:	out unsigned) is
begin
	if flagIn = '0' then
		flagIn <= '1';
	else
		flagIn <= '0';
		param <= unsigned(dataIn(param'length-1 downto 0));
	end if;
end getParam;

procedure getParam(
	signal flagIn	:	inout	std_logic;
	signal dataIn	:	in	std_logic_vector;
	signal param	:	out std_logic) is
begin
	if flagIn = '0' then
		flagIn <= '1';
	else
		flagIn <= '0';
		param <= dataIn(0);
	end if;
end getParam;

procedure getParam(
	signal flagIn	:	inout std_logic;
	signal dataIn	:	in std_logic_vector;
	signal paramArray	:	out int_array;
	signal idx		:	in std_logic_vector) is
begin
	if flagIn = '0' then
		flagIn <= '1';
	else
		flagIn <= '0';
		paramArray(slvToInt(idx)) <= to_integer(unsigned(dataIn));
	end if;
end getParam;

function slvToInt(
	signal vecIn	: std_logic_vector)
	return integer is
begin
	return to_integer(unsigned(vecIn));
end slvToInt;

 
end Constants;
