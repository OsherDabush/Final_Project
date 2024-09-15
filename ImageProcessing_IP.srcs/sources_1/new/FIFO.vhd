library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.all;
use IEEE.math_real.all;

entity FIFO is
 generic(width    : natural := 32;
         depth    : natural := 4098);
    Port(clk      : in std_logic;
         resetn   : in std_logic;
         s_tready : out std_logic;      
         s_tvalid : in std_logic;       
         s_tlast  : in std_logic;       
         s_tdata  : in std_logic_vector(width - 1 downto 0);       
         m_tready : in std_logic;    
         m_tvalid : out std_logic;   
         m_tlast  : out std_logic;   
         m_tdata  : out std_logic_vector(width - 1 downto 0));      
end FIFO;

architecture Behavioral of FIFO is

-- The FIFO is full when the RAM contains ram_depth - 1 elements
type ram_type is array (0 to depth - 1) of std_logic_vector(s_tdata'range);    
signal ram : ram_type;
type tlast_type is array (0 to depth - 1) of std_logic;   
signal tlast : tlast_type;

-- Newest element at head, oldest element at tail
subtype index_type is natural range ram_type'range;
signal head : index_type;
signal tail : index_type;
signal count : index_type;
signal count_p1 : index_type;

-- Internal versions of entity signals with mode "out"
signal in_ready_i : std_logic;
signal out_valid_i : std_logic;

-- True the clock cycle after a simultaneous read and write  
signal read_while_write_p1 : std_logic;

function next_index(
 index : index_type;
 ready : std_logic;
 valid : std_logic) return index_type is
begin
  if((ready = '1') and (valid = '1')) then
    if(index = index_type'high) then
     return index_type'low;
    else
     return index + 1;
    end if;
  end if;
 return index;
end function;

procedure index_proc(
 signal clk : in std_logic;
 signal rst : in std_logic;
 signal index : inout index_type;
 signal ready : in std_logic;
 signal valid : in std_logic) is
begin
  if rising_edge(clk) then
    if(rst = '0') then
      index <= index_type'low;
    else
      index <= next_index(index, ready, valid);
    end if;
  end if;
end procedure;

begin

s_tready <= in_ready_i;
m_tvalid <= out_valid_i;

PROC_HEAD : index_proc(clk, resetn, head, in_ready_i, s_tvalid);    -- Update head index on write
PROC_TAIL : index_proc(clk, resetn, tail, m_tready, out_valid_i);    -- Update tail index on read

process(clk)    -- Synchronous Write Process for FIFO RAM
begin
  if rising_edge(clk) then
    ram(head) <= s_tdata;
    tlast(head) <= s_tlast;
  end if;
end process;

process(clk)    -- Synchronous Read Process for FIFO RAM
begin
  if rising_edge(clk) then
    m_tdata <= ram(next_index(tail, m_tready, out_valid_i));
    m_tlast <= tlast(next_index(tail, m_tready, out_valid_i));
  end if;
end process;

process(head, tail)    -- FIFO Count Calculation Process
begin
  if(head < tail) then
    count <= head - tail + depth;
  else
    count <= head - tail;
  end if;
end process;

process(clk)    -- FIFO Count Delay Process
begin
  if rising_edge(clk) then
    if(resetn = '0') then
      count_p1 <= 0;
    else
      count_p1 <= count;
    end if;
  end if;
end process;

process(count)    -- FIFO Input Ready Signal Generation Process
begin
  if(count < depth - 1) then
    in_ready_i <= '1';
  else
    in_ready_i <= '0';
  end if;
end process;

process(clk)    -- Simultaneous Read and Write Detection Process
begin
  if rising_edge(clk) then
    if(resetn = '0') then
      read_while_write_p1 <= '0';
    else
      read_while_write_p1 <= '0';
      if((in_ready_i = '1') and (s_tvalid = '1') and (m_tready = '1') and (out_valid_i = '1')) then
        read_while_write_p1 <= '1';
      end if;
    end if;
  end if;
end process;

process(count, count_p1, read_while_write_p1)   -- Output Valid Signal Generation Process
begin
out_valid_i <= '1';
  if(count = 0 or count_p1 = 0) then    -- If the RAM is empty or was empty in the prev cycle
    out_valid_i <= '0';
  end if;
  if(count = 1 and read_while_write_p1 = '1') then    -- If simultaneous read and write when almost empty
    out_valid_i <= '0';
  end if;
end process;
end Behavioral;