library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.all;
use IEEE.math_real.all;

entity RGB2GRAY is
 generic(width    : natural := 32);
    Port(clk      : in std_logic;
         resetn   : in std_logic;
         s_tvalid : in std_logic;
         s_tdata  : in std_logic_vector(width - 1 downto 0);
         m_tdata  : out unsigned(width/4 - 1 downto 0));
end RGB2GRAY;

architecture Behavioral of RGB2GRAY is
function rgb_to_gray(r, g, b : unsigned(7 downto 0)) return unsigned is
  variable gray : unsigned(7 downto 0);
  variable r_int, g_int, b_int : integer;
begin
  r_int := to_integer(r);
  g_int := to_integer(g);
  b_int := to_integer(b);
  gray := unsigned(to_unsigned((r_int * 77 + g_int * 150 + b_int * 29) / 256, 8));
  return gray;
end function;

begin
process(clk)
variable R_DATA, G_DATA, B_DATA : unsigned(7 downto 0);
variable LUMA : unsigned(7 downto 0);
begin
  if rising_edge(clk) then
    if(resetn = '0') then
      R_DATA := (others => '0');
      G_DATA := (others => '0');
      B_DATA := (others => '0');
      m_tdata <= (others => '0');
    elsif(s_tvalid = '1') then
      R_DATA := unsigned(s_tdata(23 downto 16));  
      G_DATA := unsigned(s_tdata(15 downto 8));   
      B_DATA := unsigned(s_tdata(7 downto 0));   
      LUMA := rgb_to_gray(R_DATA, G_DATA, B_DATA);
      m_tdata <= LUMA(7 downto 0) + ("0000000" & LUMA(7));
    else
	  m_tdata <= (others=>'0');
    end if;
  end if;
end process;
end Behavioral;