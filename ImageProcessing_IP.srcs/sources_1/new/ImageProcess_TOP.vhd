library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.all;
use IEEE.math_real.all;

entity ImageProcess_TOP is
 generic(width 		    : natural := 8);
    Port(aclk           : in std_logic;
         aresetn        : in std_logic;
         s_axis_tvalid  : in std_logic;
         s_axis_tdata   : in std_logic_vector(width - 1 downto 0);
         s_axis_tlast   : in std_logic;
         s_axis_tready  : out std_logic;
         m_axis_tvalid  : out std_logic;
         m_axis_tdata   : out std_logic_vector(width*4 - 1 downto 0);
         m_axis_tlast   : out std_logic;
         m_axis_tready  : in std_logic;
         threshold      : in std_logic_vector(width - 1 downto 0));
end ImageProcess_TOP;

architecture Behavioral of ImageProcess_TOP is
component FIFO is
  generic(width : natural := 8;
          depth : natural := 4098);
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
end component;
component AveragePixels is
 generic(width    : natural := 8);
    Port(clk      : in std_logic;
         resetn   : in std_logic;
         s_tvalid : in std_logic;
         s_tdata  : in std_logic_vector(width - 1 downto 0);
         m_tdata  : out std_logic_vector(width - 1 downto 0));
end component;
component ForegroundDetector is
 generic(width     : natural := 8);
    Port(clk       : in std_logic;
         resetn    : in std_logic;
         s_tvalid  : in std_logic;
         s_tdata   : in std_logic_vector(width - 1 downto 0);
         bg_tdata  : in std_logic_vector(width - 1 downto 0);
         threshold : in std_logic_vector(width - 1 downto 0);
         m_tdata   : out std_logic_vector(width*4 - 1 downto 0));
end component;

signal FIFO_tvalid : std_logic;
signal FIFO_tdata  : std_logic_vector(width - 1 downto 0);
signal bg_tdata  : std_logic_vector(width - 1 downto 0);
begin

m_axis_tvalid <= FIFO_tvalid;

FIFO_0: FIFO generic map(width=>8, depth=>4098)
                    port map(clk=>aclk,
                             resetn=>aresetn,
                             s_tdata=>s_axis_tdata,
                             s_tvalid=>s_axis_tvalid,
                             s_tlast=>s_axis_tlast,
                             m_tlast=>m_axis_tlast,
                             m_tvalid=>FIFO_tvalid,
                             s_tready=>s_axis_tready,
                             m_tready=>m_axis_tready,
                             m_tdata=>FIFO_tdata);

Average_Pixels: AveragePixels generic map(width=>8)
                                 port map(clk=>aclk,
									      resetn=>aresetn,
									      s_tvalid=>FIFO_tvalid,
									      s_tdata=>FIFO_tdata,
									      m_tdata=>bg_tdata);

Foreground_Detector: ForegroundDetector generic map(width=>8)
                                           port map(clk=>aclk,
												    resetn=>aresetn,
												    s_tvalid=>FIFO_tvalid,
												    s_tdata=>FIFO_tdata,
												    bg_tdata=>bg_tdata,
												    m_tdata=>m_axis_tdata,
												    threshold=>threshold);

end Behavioral;