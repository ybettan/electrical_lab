
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.std_logic_unsigned.all;
use ieee.numeric_std.all;
-- Alex Grinshpun March 24 2017 

entity vga_game is
port 	(
		--////////////////////	Clock Input	 	////////////////////	 
		CLOCK_27	: in std_logic; --						//	27 MHz
		RESETn	: in std_logic; --			//	50 MHz
		--EXT_CLOCK,						//	External Clock
		--////////////////////	VGA		////////////////////////////
		keepflag    : out std_logic;
		VGA_CLK 	: out std_logic; --	,   						//	VGA Clock
		VGA_HS 	: out std_logic; --	,							//	VGA H_SYNC
		VGA_VS	: out std_logic; --	,							//	VGA V_SYNC
		VGA_BLANK	: out std_logic; --	,						//	VGA BLANK
		VGA_SYNC	: out std_logic; --	,						//	VGA SYNC
		VGA_R	: out std_logic_vector(9 downto 0); --	,   						//	VGA Red[9:0]
		VGA_G	: out std_logic_vector(9 downto 0); --	,	 						//	VGA Green[9:0]
		VGA_B	: out std_logic_vector(9 downto 0) --	,  						//	VGA Blue[9:0]

	);
end vga_game;

architecture behav of vga_game is 
signal 		CLK : std_logic;

signal mVGA_R : std_logic_vector(9 downto 0);
signal	mVGA_G: std_logic_vector(9 downto 0);
signal	mVGA_B: std_logic_vector(9 downto 0);
signal	mVGA_ADDR: std_logic_vector(19 downto 0);


signal oCoord_X : integer;
signal oCoord_Y :  integer;

signal bVGA_R : std_logic_vector(9 downto 0);
signal bVGA_G : std_logic_vector(9 downto 0);
signal bVGA_B : std_logic_vector(9 downto 0);

signal iCoord_X : std_logic_vector(9 downto 0);
signal iCoord_Y : std_logic_vector(9 downto 0);

signal bCoord_X : std_logic_vector(9 downto 0);
signal bCoord_Y : std_logic_vector(9 downto 0);

signal out_shift : std_logic_vector(9 downto 0);
signal count : std_logic_vector(15 downto 0);

signal ImageSizeX: std_logic_vector(9 downto 0);
signal ImageSizeY: std_logic_vector(9 downto 0);

signal ImageStartX: std_logic_vector(9 downto 0);
signal ImageStartY: std_logic_vector(9 downto 0);
signal xerror : std_logic;
signal yerror : std_logic;

signal  oCoord_X_sim : integer;
signal oCoord_Y_sim : integer;

signal y_mVGA_RGB : std_logic_vector(7 downto 0);

signal b_mVGA_RGB : std_logic_vector(7 downto 0);


signal m_mVGA_R : std_logic_vector(9 downto 0);
signal m_mVGA_G: std_logic_vector(9 downto 0);
signal m_mVGA_B: std_logic_vector(9 downto 0);
signal VGA_CLK_t : std_logic;
signal b_drawing_request : std_logic;
signal y_drawing_request : std_logic;

component misc is
port 	(
		--////////////////////	Clock Input	 	////////////////////	 
		CLOCK_27	: in std_logic; --						//	27 MHz
		CLK 	: out std_logic --	,   						//	VGA Clock
	);
end component;

component objects_mux is
port 	(
		--////////////////////	Clock Input	 	////////////////////	 
		CLK	: in std_logic; -- //	27 MHz
		RESETn : in std_logic ;		
		b_drawing_request	: in std_logic;
		b_mVGA_RGB 	: in std_logic_vector(7 downto 0); --	,  
		y_drawing_request	: in std_logic;
		y_mVGA_RGB 	: in std_logic_vector(7 downto 0); --	,  
		m_mVGA_R 	: out std_logic_vector(9 downto 0); --	,  
		m_mVGA_G 	: out std_logic_vector(9 downto 0); --	, 
		m_mVGA_B 	: out std_logic_vector(9 downto 0) --	, 


	);
end component;
 

component	VGA_Controller
port (
		iCLK 	: in std_logic;
		iRST_N	: in std_logic;
		iRed: in std_logic_vector(9 downto 0);
		iGreen: in std_logic_vector(9 downto 0);
		iBlue: in std_logic_vector(9 downto 0);

		oAddress	: out std_logic_vector(19 downto 0);
		oCoord_X	: out integer;
		oCoord_Y	: out integer;

--	VGA Side
		oVGA_R: out std_logic_vector(9 downto 0);
		oVGA_G: out std_logic_vector(9 downto 0);
		oVGA_B: out std_logic_vector(9 downto 0);
		oVGA_H_SYNC: out std_logic;
		oVGA_V_SYNC: out std_logic;
		oVGA_SYNC: out std_logic;
		oVGA_BLANK: out std_logic;
		oVGA_CLOCK: out std_logic
);

end component;


component smaleyface_object
port 	(
		--////////////////////	Clock Input	 	////////////////////	
	   	CLK  		: in std_logic;
		RESETn		: in std_logic;
		oCoord_X	: in integer;
		oCoord_Y	: in integer;
		ObjectStartX	: in integer;
		ObjectStartY 	: in integer;
		drawing_request	: out std_logic ;
		mVGA_RGB 	: out std_logic_vector(7 downto 0) ;
		keepflag    : out std_logic
	);
end component;




component back_ground_draw
port 	(
		--////////////////////	Clock Input	 	////////////////////	
	   CLK  : in std_logic;
		RESETn	: in std_logic;
		oCoord_X	: in integer;
		oCoord_Y	: in integer;
		mVGA_RGB : out std_logic_vector(7 downto 0)

	);
end component;

component timer is
port 	(
		--////////////////////	Clock Input	 	////////////////////	 
		CLK			: in std_logic; --						//	27 MHz
		RESETn		: in std_logic; --			//	50 MHz
		VGA_VS		: in std_logic; --	,						//	VGA SYNC
		timer_done	: out std_logic
	);
end component;

component smileyFaceMove 
port 	(
		--////////////////////	Clock Input	 	////////////////////	 
		CLK				: in std_logic; --						//	27 MHz
		RESETn			: in std_logic; --			//	50 MHz
		timer_done		: in std_logic;
		ObjectStartX	: out integer ;
		ObjectStartY	: out integer
		
	);
end component;

signal ball_drawing : std_logic;
signal not_RESETn 	: std_logic;

signal VGA_VS_t 	: std_logic;
signal timer_done	: std_logic;
signal smileyFaceMove_objectX : integer;
signal smileyFaceMove_objectY : integer;

begin

 --algrin
misc_u :  misc 
port 	map (
		--////////////////////	Clock Input	 	////////////////////	 
		CLOCK_27	=> CLOCK_27, --						//	27 MHz
		CLK		=> CLK 	--				//	VGA Clock


	);
-------------Code Starts Here-------



--algrin . Use to debug logic without VGA controller

process ( RESETn,CLK)
begin
  if RESETn = '0' then
    oCoord_X_sim <= 0;
    oCoord_Y_sim <= 0;
elsif CLK'event  and CLK = '1' then
	if oCoord_X_sim = 32 then
		oCoord_X_sim <= 0;
		if oCoord_Y_sim = 20 then
			oCoord_Y_sim <= 0;
		else
			oCoord_Y_sim  <= oCoord_Y_sim + 1;
		end if;
	else
    oCoord_X_sim  <= oCoord_X_sim + 1;
	end if;
    
end if;
end process ;
 

objects_mux_u : objects_mux 
port 	map(
		--////////////////////	Clock Input	 	////////////////////	 
		CLK	=> CLK,
		b_drawing_request	=> b_drawing_request,
		y_drawing_request	=> '0',
		b_mVGA_RGB	=> b_mVGA_RGB,
		y_mVGA_RGB	=> y_mVGA_RGB,
		m_mVGA_R	=> mVGA_R,
		m_mVGA_G	=> mVGA_G,
		m_mVGA_B	=> mVGA_B,
		RESETn	=> RESETn

	);


timer_u : timer 
port map	(
		--////////////////////	Clock Input	 	////////////////////	 
		CLK			=> 	CLK,	--		//	27 MHz
		RESETn		=> 	RESETn,		-- //	
		VGA_VS		=>  VGA_VS_t,--	,						//	VGA SYNC, goes up before every frame start
		timer_done	=>  timer_done
	);
	
---

smileyFaceMove_u :  smileyFaceMove 
port map	(
		--////////////////////	Clock Input	 	////////////////////	 
		CLK				=> CLK, --						//	27 MHz
		RESETn			=> RESETn, --			//	50 MHz
		timer_done		=> timer_done,
		ObjectStartX	=> smileyFaceMove_objectX,	
		ObjectStartY	=> smileyFaceMove_objectY
		
	);

----
smileyface_object_u : smaleyface_object
port map	(
		--////////////////////	Clock Input	 	////////////////////	
	   CLK	=> CLK,
		RESETn => RESETn,
		oCoord_X	=> oCoord_X,
		oCoord_Y	=> oCoord_Y,
--		oCoord_X	=> oCoord_X_sim,
--		oCoord_Y	=> oCoord_Y_sim,
		ObjectStartX	=> smileyFaceMove_objectX,
		ObjectStartY	=> smileyFaceMove_objectY,
		drawing_request	=> b_drawing_request,
		mVGA_RGB	=> b_mVGA_RGB,
		keepflag	=> keepflag
	);

 

	u3 :  back_ground_draw 
port map	(
		--////////////////////	Clock Input	 	////////////////////	
	   CLK		=> CLK,
		RESETn     		=> RESETn,
		oCoord_X	=> oCoord_X,
		oCoord_Y => oCoord_Y,
		mVGA_RGB	=> y_mVGA_RGB 				
	
	);

--	
u1 : VGA_Controller		port map
(	--	Host Side
							iCLK       => CLK,
							iRST_N     => RESETn,
							oAddress => mVGA_ADDR,
							oCoord_X => oCoord_X,
							oCoord_Y => oCoord_Y,
							iRed     => mVGA_R,
							iGreen   => mVGA_G,
							iBlue    => mVGA_B,
							--	VGA Side
							oVGA_R => VGA_R,
							oVGA_G => VGA_G,
							oVGA_B => VGA_B,
							oVGA_H_SYNC => VGA_HS ,
							oVGA_V_SYNC => VGA_VS_t ,
							oVGA_SYNC   => VGA_SYNC,
							oVGA_BLANK  => VGA_BLANK,
							oVGA_CLOCK		=> VGA_CLK_t
							--	Control Signal
							
								);
VGA_VS <= VGA_VS_t;
VGA_CLK <= VGA_CLK_t;
							

end behav;