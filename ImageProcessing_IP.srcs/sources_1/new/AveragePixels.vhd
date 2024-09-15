library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.all;
use IEEE.math_real.all;

entity AveragePixels is
 generic(width    : natural := 8);
    Port(clk      : in std_logic;
         resetn   : in std_logic;
         s_tvalid : in std_logic;
         s_tdata  : in std_logic_vector(width - 1 downto 0);
         m_tdata  : out std_logic_vector(width - 1 downto 0));
end AveragePixels;

architecture Behavioral of AveragePixels is
signal update : std_logic := '0';
signal bg_pixel : unsigned(width - 1 downto 0) := (others => '0');
signal current_pixel : unsigned(width - 1 downto 0) := (others => '0'); 
begin

process(clk)
begin
  if rising_edge(clk) then
    if(resetn = '0') then
	  current_pixel <= (others=>'0');
	elsif(s_tvalid = '1') then
	  current_pixel <= unsigned(s_tdata);
	  update <= '1';
	else
	  update <= '0';
	end if;
  end if;
end process;

process(clk, update)
variable updated_pixel : unsigned(width - 1 downto 0) := (others => '0');
begin
  if rising_edge(clk) then
    if(resetn = '0') then
	  updated_pixel := (others=>'0');
	  m_tdata <= (others=>'0');
	elsif(s_tvalid = '1') then
	  if(update = '1') then
	    updated_pixel := shift_right((bg_pixel + current_pixel), 1);
		bg_pixel <= updated_pixel;
	    m_tdata <= std_logic_vector(updated_pixel);
      else
	    m_tdata <= (others=>'0');
	  end if;
	else
	  m_tdata <= (others=>'0');
	end if;
  end if;
end process;
end Behavioral;