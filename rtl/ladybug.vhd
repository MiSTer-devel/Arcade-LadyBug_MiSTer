-------------------------------------------------------------------------------
--
-- FPGA Lady Bug
--
-- Toplevel port for Papilio Plus board.
--
-------------------------------------------------------------------------------
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- Please report bugs to the author, but before you do so, please
-- make sure that this is not a derivative work and that
-- you have the latest version of this file.
--
-------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;

library ieee;
	use ieee.numeric_std.all;

use work.ladybug_dip_pack.all;

entity ladybug is
port (
	-- Global Interface -------------------------------------------------------
	CLK_IN       : in  std_logic; -- 20MHz
	I_RESET      : in  std_logic;

	dn_addr      : in  std_logic_vector(15 downto 0);
	dn_data      : in  std_logic_vector(7 downto 0);
	dn_wr        : in  std_logic;

	-- VGA Interface ----------------------------------------------------------
	O_VIDEO_R    : out std_logic_vector( 1 downto 0);
	O_VIDEO_G    : out std_logic_vector( 1 downto 0);
	O_VIDEO_B    : out std_logic_vector( 1 downto 0);
	O_VSYNC      : out std_logic;
	O_HSYNC      : out std_logic;
	O_VBLANK     : out std_logic;
	O_HBLANK     : out std_logic;
	O_PIXCE      : out std_logic;

	-- Audio Interface --------------------------------------------------------
	O_AUDIO      : out signed(7 downto 0);
	
	but_coin_s   : in  std_logic_vector( 1 downto 0);
	but_fire_s   : in  std_logic_vector( 1 downto 0);
	but_bomb_s   : in  std_logic_vector( 1 downto 0);
	but_tilt_s   : in  std_logic_vector( 1 downto 0);
	but_select_s : in  std_logic_vector( 1 downto 0);
	but_up_s     : in  std_logic_vector( 1 downto 0);
	but_down_s   : in  std_logic_vector( 1 downto 0);
	but_left_s   : in  std_logic_vector( 1 downto 0);
	but_right_s  : in  std_logic_vector( 1 downto 0);
	dip_block_1_s: in  std_logic_vector( 7 downto 0)

);
end ladybug;

architecture struct of ladybug is

	signal
		ps2_codeready,
		clk_20mhz_s,
		clk_en_5mhz_s,
		ext_res_n_s,
		ext_res_s,
		audio_s,
		vid_hsync,
		vid_vsync,
		vga_hsync,
		vid_comp_sync_n,
		vga_vsync           : std_logic;

	signal rom_cpu_a_s     : std_logic_vector(14 downto 0);
	signal rom_cpu_d_s     : std_logic_vector( 7 downto 0);
	signal rom_cpu_d1      : std_logic_vector( 7 downto 0);
	signal rom_cpu_d2      : std_logic_vector( 7 downto 0);
	signal rom_cpu_d3      : std_logic_vector( 7 downto 0);
	signal rom_cpu_d4      : std_logic_vector( 7 downto 0);
	signal rom_cpu_d5      : std_logic_vector( 7 downto 0);
	signal rom_cpu_d6      : std_logic_vector( 7 downto 0);

	signal rom_char_a_s    : std_logic_vector(11 downto 0);
	signal rom_char_d_s    : std_logic_vector(15 downto 0);

	signal rom_sprite_a_s  : std_logic_vector(11 downto 0);
	signal rom_sprite_d_s  : std_logic_vector(15 downto 0);

	signal
		dac_audio_s,
		--dip_block_1_s,
		dip_block_2_s       : std_logic_vector( 7 downto 0) := (others => '0');

	signal ps2_scancode    : std_logic_vector( 9 downto 0) := (others => '0');

	signal
		vid_rgb,
		vga_rgb             : std_logic_vector(15 downto 0) := (others => '0');

	signal but_chute_s     : std_logic_vector( 1 downto 0) := (others=>'0');

	signal rom_cpu1_cs, rom_cpu2_cs, rom_cpu3_cs, rom_sprite_l_cs, rom_sprite_u_cs, rom_char_l_cs, rom_char_u_cs : std_logic;
begin

	O_PIXCE <= clk_en_5mhz_s;

	but_chute_s <= not but_coin_s(1) & not but_coin_s(0);

	-----------------------------------------------------------------------------
	-- inputs assignments
	-----------------------------------------------------------------------------
	ext_res_s <= I_RESET;
	ext_res_n_s <= not ext_res_s;
	clk_20mhz_s <= CLK_IN;
	
	-----------------------------------------------------------------------------
	-- Ladybug Machine
	-----------------------------------------------------------------------------
	machine_b : entity work.ladybug_machine
	port map (
		ext_res_n_i       => ext_res_n_s,
		clk_20mhz_i       => clk_20mhz_s,
		clk_en_5mhz_o     => clk_en_5mhz_s,
		tilt_n_i          => but_tilt_s(0),
		player_select_n_i => but_select_s,
		player_fire_n_i   => but_fire_s,
		player_up_n_i     => but_up_s,
		player_right_n_i  => but_right_s,
		player_down_n_i   => but_down_s,
		player_left_n_i   => but_left_s,
		player_bomb_n_i   => but_bomb_s,
		right_chute_i     => but_chute_s(0),
		left_chute_i      => but_chute_s(1),
		dip_block_1_i     => dip_block_1_s,
		dip_block_2_i     => dip_block_2_s,
		rgb_r_o           => O_VIDEO_R,
		rgb_g_o           => O_VIDEO_G,
		rgb_b_o           => O_VIDEO_B,
		hsync_n_o         => O_HSYNC,
		vsync_n_o         => O_VSYNC,
	   vblank_o          => O_VBLANK,
	   hblank_o          => O_HBLANK,
		audio_o           => O_AUDIO,
		rom_cpu_a_o       => rom_cpu_a_s,
		rom_cpu_d_i       => rom_cpu_d_s,
		rom_char_a_o      => rom_char_a_s,
		rom_char_d_i      => rom_char_d_s,
		rom_sprite_a_o    => rom_sprite_a_s,
		rom_sprite_d_i    => rom_sprite_d_s
	);

	-----------------------------------------------------------------------------
	-- Building the DIP Switches - see file ladybug_dip_pack.vhd
	-----------------------------------------------------------------------------
--	dip_block_1_s <= lb_dip_block_1_c; -- Lady Bug
--	dip_block_1_s <= do_dip_block_1_c; -- Dorodon
--	dip_block_1_s <= ca_dip_block_1_c; -- Cosmic Avenger
	dip_block_2_s <= price_dip_block_2_c; -- Common for all games (coins per game pricing)

	-----------------------------------------------------------------------------
	-- Game ROMs
	-----------------------------------------------------------------------------
	
	rom_cpu1_cs     <= '1' when dn_addr(15 downto 13)="000" else '0';
	rom_cpu2_cs     <= '1' when dn_addr(15 downto 13)="001" else '0';
	rom_cpu3_cs     <= '1' when dn_addr(15 downto 13)="010" else '0';
	rom_sprite_l_cs <= '1' when dn_addr(15 downto 12)=X"6"  else '0';
	rom_sprite_u_cs <= '1' when dn_addr(15 downto 12)=X"7"  else '0';
	rom_char_l_cs   <= '1' when dn_addr(15 downto 12)=X"8"  else '0';
	rom_char_u_cs   <= '1' when dn_addr(15 downto 12)=X"9"  else '0';

	inst_rom_spritel : work.dpram generic map (12,8)
	port map
	(
		clock_a   => clk_20mhz_s,
		wren_a    => dn_wr and rom_sprite_l_cs,
		address_a => dn_addr(11 downto 0),
		data_a    => dn_data,

		clock_b   => clk_20mhz_s,
		address_b => rom_sprite_a_s,
		q_b       => rom_sprite_d_s( 7 downto 0)
	);

	inst_rom_spriteu : work.dpram generic map (12,8)
	port map
	(
		clock_a   => clk_20mhz_s,
		wren_a    => dn_wr and rom_sprite_u_cs,
		address_a => dn_addr(11 downto 0),
		data_a    => dn_data,

		clock_b   => clk_20mhz_s,
		address_b => rom_sprite_a_s,
		q_b       => rom_sprite_d_s( 15 downto 8)
	);

	inst_rom_charl : work.dpram generic map (12,8)
	port map
	(
		clock_a   => clk_20mhz_s,
		wren_a    => dn_wr and rom_char_l_cs,
		address_a => dn_addr(11 downto 0),
		data_a    => dn_data,

		clock_b   => clk_20mhz_s,
		address_b => rom_char_a_s,
		q_b       => rom_char_d_s( 7 downto 0)
	);

	inst_rom_charu : work.dpram generic map (12,8)
	port map
	(
		clock_a   => clk_20mhz_s,
		wren_a    => dn_wr and rom_char_u_cs,
		address_a => dn_addr(11 downto 0),
		data_a    => dn_data,

		clock_b   => clk_20mhz_s,
		address_b => rom_char_a_s,
		q_b       => rom_char_d_s(15 downto 8)
	);

	inst_rom_cpu1 : work.dpram generic map (13,8)
	port map
	(
		clock_a   => clk_20mhz_s,
		wren_a    => dn_wr and rom_cpu1_cs,
		address_a => dn_addr(12 downto 0),
		data_a    => dn_data,

		clock_b   => clk_20mhz_s,
		address_b => rom_cpu_a_s(12 downto 0),
		q_b       => rom_cpu_d1
	);
	
	inst_rom_cpu2 : work.dpram generic map (13,8)
	port map
	(
		clock_a   => clk_20mhz_s,
		wren_a    => dn_wr and rom_cpu2_cs,
		address_a => dn_addr(12 downto 0),
		data_a    => dn_data,

		clock_b   => clk_20mhz_s,
		address_b => rom_cpu_a_s(12 downto 0),
		q_b       => rom_cpu_d2
	);

	inst_rom_cpu3 : work.dpram generic map (13,8)
	port map
	(
		clock_a   => clk_20mhz_s,
		wren_a    => dn_wr and rom_cpu3_cs,
		address_a => dn_addr(12 downto 0),
		data_a    => dn_data,

		clock_b   => clk_20mhz_s,
		address_b => rom_cpu_a_s(12 downto 0),
		q_b       => rom_cpu_d3
	);

	-----------------------------------------------------------------------------
	-- Program ROMs data mux
	-----------------------------------------------------------------------------
	rom_cpu_d_s <=
		rom_cpu_d1 when rom_cpu_a_s(14 downto 13) = "00" else
		rom_cpu_d2 when rom_cpu_a_s(14 downto 13) = "01" else
		rom_cpu_d3 when rom_cpu_a_s(14 downto 13) = "10" else
		(others=>'0');

end struct;
