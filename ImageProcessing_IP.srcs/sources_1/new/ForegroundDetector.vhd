library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.all;
use IEEE.math_real.all;

entity ForegroundDetector is
 generic(width     : natural := 8);
    Port(clk       : in std_logic;
         resetn    : in std_logic;
         s_tvalid  : in std_logic;
         s_tdata   : in std_logic_vector(width - 1 downto 0);
         bg_tdata  : in std_logic_vector(width - 1 downto 0);
         threshold : in std_logic_vector(width - 1 downto 0);
         m_tdata   : out std_logic_vector(width*4 - 1 downto 0));
end ForegroundDetector;

architecture Behavioral of ForegroundDetector is
constant white_pixel : std_logic_vector(width - 1 downto 0) := x"ffffffff";
constant black_pixel : std_logic_vector(width - 1 downto 0) := x"00000000";
signal threshold_signed : signed(width downto 0) := (others=>'0');
signal diff : signed(width downto 0) := (others=>'0');
signal s_tvalid_reg1, s_tvalid_reg2 : std_logic := '0';
signal s_tdata_reg1, s_tdata_reg2 : std_logic_vector(width - 1 downto 0) := (others=>'0');
signal bg_tdata_reg1, bg_tdata_reg2 : std_logic_vector(width - 1 downto 0) := (others=>'0');
signal diff_reg : signed(width downto 0) := (others=>'0');
begin

process(clk)
begin
  if rising_edge(clk) then
    if(resetn = '0') then
      s_tvalid_reg1 <= '0';
      s_tdata_reg1 <= (others=>'0');
      bg_tdata_reg1 <= (others=>'0');
    elsif(s_tvalid = '1') then
      s_tvalid_reg1 <= s_tvalid;
      s_tdata_reg1 <= s_tdata;
      bg_tdata_reg1 <= bg_tdata;
    else
      s_tvalid_reg1 <= '0';
    end if;
  end if;
end process;

process(clk)
begin
  if rising_edge(clk) then
    if(resetn = '0') then
      s_tvalid_reg2 <= '0';
      diff <= (others=>'0');
      threshold_signed <= (others=>'0');
    elsif(s_tvalid_reg1 = '1') then
      s_tvalid_reg2 <= s_tvalid_reg1;
      s_tdata_reg2 <= s_tdata_reg1;
      bg_tdata_reg2 <= bg_tdata_reg1;
      diff <= resize(abs(signed('0' & s_tdata_reg1) - signed('0' & bg_tdata_reg1)), 9);
      threshold_signed <= resize(signed(threshold), 9);
    else
      s_tvalid_reg2 <= '0';
    end if;
  end if;
end process;

process(clk)
begin
  if rising_edge(clk) then
    if(resetn = '0') then
      m_tdata <= (others=>'0');
    elsif(s_tvalid_reg2 = '1') then
      if(diff > threshold_signed) then
        m_tdata <= white_pixel; 
      else
        m_tdata <= black_pixel; 
      end if;
    end if;
  end if;
end process;
end Behavioral;