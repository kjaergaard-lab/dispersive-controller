library IEEE;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.ALL;
use ieee.std_logic_unsigned.all; 

--
-- This package contains both constants and functions used for
-- servo control.
--
package Serial is

--
-- This is the baud period for the UART protocol.
--
constant BAUD_PERIOD		:	natural	:= 868;	--With a 100 MHz clock, corresponds to 115200 Hz
--
-- This is the bit in the addr/cmd line that tells the parser to transmit data back
--
constant TRANSMIT_BIT       :   natural :=  23;
--
-- Width of serial address section in cmd data
--
constant ADDR_WIDTH			:	natural	:=	8;

--
-- Defines serial data
--
subtype t_serial_data is std_logic_vector(31 downto 0);
--
-- Defines a data bus controlled by the master
--
type t_serial_bus_master is record
    cmd     :   t_serial_data;
    num     :   t_serial_data;
    ready   :   std_logic;
    busy    :   std_logic;
    reset   :   std_logic;
end record t_serial_bus_master;

--
-- Defines a data bus controlled by the slave
type t_serial_bus_slave is record
    data    :   t_serial_data;
    flag    :   std_logic;
    trig    :   std_logic;
end record t_serial_bus_slave;

--
-- Defines a total data bus of master and slave parts
--
type t_serial_bus is record
    m       :   t_serial_bus_master;
    s       :   t_serial_bus_slave;
end record t_serial_bus;

--
-- Defines an array of serial slaves
--
type t_serial_bus_slave_array is array(natural range <>) of t_serial_bus_slave;


--
-- Define initial values
--
constant INIT_SERIAL_BUS_MASTER :   t_serial_bus_master :=  (cmd    =>  (others => '0'),
                                                             num    =>  (others => '0'),
                                                             ready  =>  '0',
                                                             busy   =>  '0',
                                                             reset  =>  '0');
constant INIT_SERIAL_BUS_SLAVE  :   t_serial_bus_slave  :=  (data   =>  (others => '0'),
                                                             flag   =>  '0',
                                                             trig   =>  '0');
constant INIT_SERIAL_BUS        :   t_serial_bus        :=  (m      =>  INIT_SERIAL_BUS_MASTER,
                                                             s      =>  INIT_SERIAL_BUS_SLAVE);

function unary_or_flag(slaves : in t_serial_bus_slave_array) return std_logic;
function unary_or_trig(slaves : in t_serial_bus_slave_array) return std_logic;
function concatenate_trig(slaves : in t_serial_bus_slave_array) return std_logic_vector;

--
-- std_logic parameter parsing
--
procedure rw(
    signal bus_in	:	in   t_serial_bus_master;
    signal bus_out  :   inout   t_serial_bus_slave;
	signal param	:	inout   std_logic);

--
-- std_logic_vector parameter parsing
--
procedure rw(
    signal bus_in	:	in   t_serial_bus_master;
    signal bus_out  :   inout   t_serial_bus_slave;
    signal param	:	inout   std_logic_vector);
    
--
-- unsigned parameter parsing
--
procedure rw(
    signal bus_in	:	in   t_serial_bus_master;
    signal bus_out  :   inout   t_serial_bus_slave;
    signal param	:	inout   unsigned);
    
--
-- signed parameter parsing
--
procedure rw(
    signal bus_in	:	in   t_serial_bus_master;
    signal bus_out  :   inout   t_serial_bus_slave;
	signal param	:	inout   signed);
	
--
-- unsigned to integer parameter parsing
--
procedure rwui(
    signal bus_in	:	in   t_serial_bus_master;
    signal bus_out  :   inout   t_serial_bus_slave;
    signal param	:	inout   integer);
	 
--
-- signed to integer parameter parsing
--
procedure rwsi(
    signal bus_in	:	in   t_serial_bus_master;
    signal bus_out  :   inout   t_serial_bus_slave;
    signal param	:	inout   integer);
	
end Serial;

--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
package body Serial is

--
-- std_logic parameter parsing
--
procedure rw(
    signal bus_in	:	in   t_serial_bus_master;
    signal bus_out  :   inout   t_serial_bus_slave;
	signal param	:	inout   std_logic) is
begin
	if bus_in.cmd(TRANSMIT_BIT) = '0' then
		if bus_out.flag = '0' then
			bus_out.flag <= '1';
		else
			bus_out.flag <= '0';
			param <= bus_in.num(0);
		end if;
	else
		bus_out.data <= (0 => param, others => '0');
		bus_out.trig <= '1';
	end if;
end rw;

--
-- std_logic_vector parameter parsing
--
procedure rw(
    signal bus_in	:	in   t_serial_bus_master;
    signal bus_out  :   inout   t_serial_bus_slave;
	signal param	:	inout   std_logic_vector) is
begin
	if bus_in.cmd(TRANSMIT_BIT) = '0' then
		if bus_out.flag = '0' then
			bus_out.flag <= '1';
		else
			bus_out.flag <= '0';
			param <= bus_in.num(param'length-1 downto 0);
		end if;
	else
		bus_out.data <= (t_serial_data'length-1 downto param'length => '0') & param;
		bus_out.trig <= '1';
	end if;
end rw;

--
-- unsigned parameter parsing
--
procedure rw(
    signal bus_in	:	in   t_serial_bus_master;
    signal bus_out  :   inout   t_serial_bus_slave;
    signal param	:	inout   unsigned) is
begin
    if bus_in.cmd(TRANSMIT_BIT) = '0' then
        if bus_out.flag = '0' then
            bus_out.flag <= '1';
        else
            bus_out.flag <= '0';
            param <= unsigned(bus_in.num(param'length-1 downto 0));
        end if;
    else
        bus_out.data <= (t_serial_data'length-1 downto param'length => '0') & std_logic_vector(param);
        bus_out.trig <= '1';
    end if;
end rw;
    
--
-- signed parameter parsing
--
procedure rw(
    signal bus_in	:	in   t_serial_bus_master;
    signal bus_out  :   inout   t_serial_bus_slave;
    signal param	:	inout   signed) is
begin
    if bus_in.cmd(TRANSMIT_BIT) = '0' then
        if bus_out.flag = '0' then
            bus_out.flag <= '1';
        else
            bus_out.flag <= '0';
            param <= signed(bus_in.num(param'length-1 downto 0));
        end if;
    else
        bus_out.data <= (t_serial_data'length-1 downto param'length => '0') & std_logic_vector(param);
        bus_out.trig <= '1';
    end if;
end rw;

--
-- unsigned to integer parameter parsing
--
procedure rwui(
    signal bus_in	:	in   t_serial_bus_master;
    signal bus_out  :   inout   t_serial_bus_slave;
    signal param	:	inout   integer) is
begin
    if bus_in.cmd(TRANSMIT_BIT) = '0' then
        if bus_out.flag = '0' then
            bus_out.flag <= '1';
        else
            bus_out.flag <= '0';
            param <= to_integer(unsigned(bus_in.num));
        end if;
    else
        bus_out.data <= std_logic_vector(to_unsigned(param,t_serial_data'length));
        bus_out.trig <= '1';
    end if;
end rwui;
    
--
-- signed to integer parameter parsing
--
procedure rwsi(
    signal bus_in	:	in   t_serial_bus_master;
    signal bus_out  :   inout   t_serial_bus_slave;
    signal param	:	inout   integer) is
begin
    if bus_in.cmd(TRANSMIT_BIT) = '0' then
        if bus_out.flag = '0' then
            bus_out.flag <= '1';
        else
            bus_out.flag <= '0';
            param <= to_integer(signed(bus_in.num));
        end if;
    else
        bus_out.data <= std_logic_vector(to_signed(param,t_serial_data'length));
        bus_out.trig <= '1';
    end if;
end rwsi;


function unary_or_flag(slaves : in t_serial_bus_slave_array) return std_logic is
	variable res_v : std_logic;  -- Null slv vector will also return '1'
  begin
	  res_v := '0';
	for i in slaves'range loop
	  res_v := res_v or slaves(i).flag;
	end loop;
	return res_v;
  end function;

function unary_or_trig(slaves : in t_serial_bus_slave_array) return std_logic is
	variable res_v : std_logic;  -- Null slv vector will also return '1'
begin
	res_v := '0';
	for i in slaves'range loop
		res_v := res_v or slaves(i).trig;
	end loop;
	return res_v;
end function;

function concatenate_trig(slaves : in t_serial_bus_slave_array) return std_logic_vector is
	variable res_v : std_logic_vector(slaves'length-1 downto 0);
begin
	res_v := (others => '0');
	for i in slaves'range loop
		res_v(i) := slaves(i).trig;
	end loop;
	return res_v;
end function;

end Serial;
