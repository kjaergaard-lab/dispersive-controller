library IEEE;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.ALL;
use ieee.std_logic_unsigned.all; 

package CustomTypes is

type t_int_array is array (integer range <>) of integer;

constant MAX_DISP	:	integer	:=	4;	--Maximum number of different dispersive settings

type t_param_disp is record
    period      :   unsigned(31 downto 0);
    width       :   unsigned(31 downto 0);
    numpulses   :   unsigned(15 downto 0);
    delay       :   unsigned(31 downto 0);
end record t_param_disp;

type t_disp is record
    pulse   :   std_logic;
    trig    :   std_logic;
end record t_disp;

constant INIT_DISP  :   t_param_disp    :=  (period     =>  to_unsigned(2500,32),
                                             width      =>  to_unsigned(50,32),
                                             numpulses  =>  to_unsigned(50,16),
                                             delay      =>  to_unsigned(0,32));

type t_param_disp_array is array (natural range <>) of t_param_disp;


type t_control is record
    enable  :   std_logic;
    start   :   std_logic;
    stop    :   std_logic;
end record t_control;

constant INIT_CONTROL_DISABLED      :   t_control       :=  (enable =>  '0',
                                                             start  =>  '0',
                                                             stop   =>  '0');

constant INIT_CONTROL_ENABLED       :   t_control       :=  (enable =>  '1',
                                                             start  =>  '0',
                                                             stop   =>  '0');

type t_module_status is record
    running :   std_logic;
    done    :   std_logic;
end record t_module_status;
	
constant INIT_MODULE_STATUS     :   t_module_status :=  (running    =>  '0',
                                                         done       =>  '0');

end CustomTypes;

package body CustomTypes is

 
end CustomTypes;
