//============================================================================
//  Arcade: Lady Bug
//
//  Port to MiSTer
//  Copyright (C) 2017 Sorgelig
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================


module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [45:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	output [11:0] VIDEO_ARX,
	output [11:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler

	// Use framebuffer from DDRAM (USE_FB=1 in qsf)
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of 16 bytes.
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,    // 1 - signed audio samples, 0 - unsigned

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT
);

assign VGA_F1    = 0;
assign VGA_SCALER= 0;
assign USER_OUT  = '1;
assign LED_USER  = ioctl_download;
assign LED_DISK  = 0;
assign LED_POWER = 0;

assign {FB_PAL_CLK, FB_FORCE_BLANK, FB_PAL_ADDR, FB_PAL_DOUT, FB_PAL_WR} = '0;

wire [1:0] ar = status[20:19];

assign VIDEO_ARX = (!ar) ? ((status[2] ) ? 8'd4 : 8'd3) : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? ((status[2] ) ? 8'd3 : 8'd4) : 12'd0;


`include "build_id.v" 
localparam CONF_STR = {
	"A.LADYBG;;",
	"H0OJK,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"H0O2,Orientation,Vert,Horz;",
	"O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"-;",
	"O89,Difficulty,Easy,Medium,Hard,Hardest;",
	"OB,Lives,3,5;",
	"OC,Cabinet,Upright,Cocktail;",	
	"-;",
	"R0,Reset;",
	"J1,Start 1P,Start 2P,Coin;",
	"jn,Start,Select,R;",
	"V,v",`BUILD_DATE
};
/*
    -- Lives ------------------------------------------------------------------
    -- 0 = 5 Lives
    -- 1 = 3 Lives
    '0' &
    -- Free Play --------------------------------------------------------------
    -- 0 = Free Play
    -- 1 = No Free Play
    '1' &
    -- Cabinet ----------------------------------------------------------------
    -- 0 = Upright
    -- 1 = Cocktail
    '0' &
    -- Screen Freeze ----------------------------------------------------------
    -- 0 = Freeze
    -- 1 = No Freeze
    '1' &
    -- Rack Test (Cheat) ------------------------------------------------------
    -- 0 = On
    -- 1 = Off
    '1' &
    -- High Score Initials ----------------------------------------------------
    -- 0 = 3-Letter Initials
    -- 1 = 10-Letter Initials
    '1' &
    -- Difficulty -------------------------------------------------------------
    -- 11 = Easy
    -- 10 = Medium
    -- 01 = Hard
    -- 00 = Hardest
    "10";
*/
wire [7:0] m_dip = {~status[11],1'b1,status[12],1'b1,1'b1,1'b1,~status[9:8]};


////////////////////   CLOCKS   ///////////////////

wire clk_sys,clk_40;
wire pll_locked;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_40),
	.outclk_1(clk_sys), //20
	.locked(pll_locked)
);

///////////////////////////////////////////////////

wire [31:0] status;
wire  [1:0] buttons;
wire        forced_scandoubler;
wire        direct_video;

wire        ioctl_download;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

wire [15:0] joystick_0,joystick_1;
wire [15:0] joy1 = joystick_0;
wire [15:0] joy2 = joystick_1;

wire [21:0] gamma_bus;


hps_io #(.STRLEN($size(CONF_STR)>>3)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.conf_str(CONF_STR),

	.buttons(buttons),
	.status(status),
	.status_menumask(direct_video),
	.forced_scandoubler(forced_scandoubler),
	.gamma_bus(gamma_bus),
	.direct_video(direct_video),

	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),

	.joystick_0(joystick_0),
	.joystick_1(joystick_1)
);


wire no_rotate = status[2] | direct_video  ;

wire m_up,m_down,m_left,m_right;
joyonedir jod
(
        clk_sys,
        1'b0,
        {
                 joy1[3],
                 joy1[2],
                 joy1[1],
                 joy1[0]
        },
        {m_up,m_down,m_left,m_right}
);

wire m_up_2,m_down_2,m_left_2,m_right_2;
joyonedir jod_2
(
        clk_sys,
        1'b0,
        {
                 joy2[3],
                 joy2[2],
                 joy2[1],
                 joy2[0]
        },
        {m_up_2,m_down_2,m_left_2,m_right_2}
);


wire m_fire    = 1'b0;
wire m_fire_2  = 1'b0;

wire m_start1 = joy1[4] | joy2[4];
wire m_start2 = joy1[5] | joy2[5];
wire m_coin   = joy1[6] | joy2[6];

wire hblank, vblank;
wire hs, vs;
wire ce_vid;
wire [1:0] r,g;
wire [1:0] b;

reg ce_pix;
always @(posedge clk_40) begin
        reg [2:0] div;

        div <= div + 1'd1;
        ce_pix <= !div;
end

wire rotate_ccw = 1;
screen_rotate screen_rotate (.*);

arcade_video #(240,6) arcade_video
(
        .*,
        .clk_video(clk_40),

        .RGB_in({r,g,b}),
        .HBlank(hblank),
        .VBlank(vblank),
        .HSync(hs),
        .VSync(vs),

        .fx(status[5:3])
);

wire [7:0] audio;
assign AUDIO_L = {audio, 8'd0};
assign AUDIO_R = AUDIO_L;
assign AUDIO_S = 1;

ladybug ladybug
(
	.CLK_IN(clk_sys),
	.I_RESET(RESET | status[0] | ioctl_download | buttons[1]),
	.O_PIXCE(ce_vid),

	.O_VIDEO_R(r),
	.O_VIDEO_G(g),
	.O_VIDEO_B(b),
	.O_VSYNC(vs),
	.O_HSYNC(hs),
	.O_VBLANK(vblank),
	.O_HBLANK(hblank),

	.dn_addr(ioctl_addr[15:0]),
	.dn_data(ioctl_dout),
	.dn_wr(ioctl_wr),

	.O_AUDIO(audio),
	
	.but_coin_s(~{1'b0,m_coin}),
	.but_fire_s(~{m_fire_2,m_fire}),
	.but_bomb_s(~{1'b0,1'b0}),
	.but_tilt_s(~{1'b0,1'b0}),
	.but_select_s(~{m_start2,m_start1}),
	.but_up_s(~{m_up_2,m_up}),
	.but_down_s(~{m_down_2,m_down}),
	.but_left_s(~{m_left_2,m_left}),
	.but_right_s(~{m_right_2,m_right}),
	.dip_block_1_s(m_dip)
);

endmodule


module joyonedir
(
        input        clk,
        input        dis,
        input  [3:0] indir,
        output [3:0] outdir
);

reg  [3:0] mask = 0;
reg  [3:0] in1,in2;
wire [3:0] innew = in1 & ~in2;

assign outdir = in1 & mask;

always @(posedge clk) begin

        in1 <= indir;
        in2 <= in1;

        if(innew[0]) mask <= 1;
        if(innew[1]) mask <= 2;
        if(innew[2]) mask <= 4;
        if(innew[3]) mask <= 8;

        if(!(indir & mask) || dis) mask <= '1;
end


endmodule
