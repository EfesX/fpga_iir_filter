library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

use std.textio.all;


library work;
use work.common_package.all;

entity tb_iir_filter is
	generic(
		fc : natural := 8  			-- 0 - 1 	MHz
									-- 1 - 1.5	MHz
									-- 2 - 2 	MHz
									-- 3 - 2.5	MHz
									-- 4 - 3	MHz
									-- 5 - 3.5	MHz
									-- 6 - 4	MHz
									-- 7 - 4.5	MHz
									-- 8 - 5	MHz
	);
end entity;


architecture tb_iir_filter_bvh of tb_iir_filter is

	component iir_filter is
		generic(
			w_s1  	: natural := 8;
			w_a0_1	: natural := 8;
			w_a1_1	: natural := 8;

			w_s2  	: natural := 8;
			w_a0_2	: natural := 8;
			w_a1_2	: natural := 8;

			w_s3  	: natural := 8;
			w_a0_3	: natural := 8;
			w_a1_3	: natural := 8;

			w_s4	: natural := 32
		);
		port(
			coeff_s_1  : in std_logic_vector(15 downto 0) := (others => '0');
			coeff_a0_1 : in std_logic_vector(15 downto 0) := (others => '0');
			coeff_a1_1 : in std_logic_vector(15 downto 0) := (others => '0');
	
			coeff_s_2  : in std_logic_vector(15 downto 0) := (others => '0');
			coeff_a0_2 : in std_logic_vector(15 downto 0) := (others => '0');
			coeff_a1_2 : in std_logic_vector(15 downto 0) := (others => '0');
	
			coeff_s_3  : in std_logic_vector(15 downto 0) := (others => '0');
			coeff_a0_3 : in std_logic_vector(15 downto 0) := (others => '0');
			coeff_a1_3 : in std_logic_vector(15 downto 0) := (others => '0');
	
			coeff_s_4  : in std_logic_vector(15 downto 0) := (others => '0');
	
			clk_fco : in std_logic := '0';
			reset   : in std_logic := '0';
	
			data_in  : in  std_logic_vector(15 downto 0) := (others => '0');
			data_out : out std_logic_vector(15 downto 0) := (others => '0')
		);
	end component iir_filter;

	signal coeff_s_1  :  std_logic_vector(15 downto 0) := (others => '0');
	signal coeff_a0_1 :  std_logic_vector(15 downto 0) := (others => '0');
	signal coeff_a1_1 :  std_logic_vector(15 downto 0) := (others => '0');

	signal coeff_s_2  :  std_logic_vector(15 downto 0) := (others => '0');
	signal coeff_a0_2 :  std_logic_vector(15 downto 0) := (others => '0');
	signal coeff_a1_2 :  std_logic_vector(15 downto 0) := (others => '0');

	signal coeff_s_3  :  std_logic_vector(15 downto 0) := (others => '0');
	signal coeff_a0_3 :  std_logic_vector(15 downto 0) := (others => '0');
	signal coeff_a1_3 :  std_logic_vector(15 downto 0) := (others => '0');

	signal coeff_s_4  :  std_logic_vector(15 downto 0) := (others => '0');

	signal clk_fco :  std_logic := '0';
	signal reset   :  std_logic := '0';

	signal data_in  :   std_logic_vector(15 downto 0) := (others => '0');
	signal data_out :  std_logic_vector(15 downto 0) := (others => '0');


	type storage_coeff_real is array (0 to 8) of real;
	type storage_windows    is array (0 to 8) of natural;
	
	constant s1 : storage_coeff_real :=(
		0.0046130,
		0.01027,
		0.01805,
		0.02786,
		0.03961,
		0.05318,
		0.06847,
		8.537e-2,
		0.1037
	);
	constant a1_0 : storage_coeff_real :=(
		-1.9492,
		-1.9110,
		-1.8648,
		-1.8109,
		-1.7500,
		-1.6823,
		-1.6085,
		-1.5289,
		-1.4441
	);
	constant a1_1 : storage_coeff_real :=(
		0.9677,
		0.9521,
		0.9370,
		0.9224,
		0.9084,
		0.8951,
		0.8824,
		0.8704,
		0.8591
	);
	constant s2 : storage_coeff_real :=(
		2.8594e-3,
		6.296e-3,
		1.095e-2,
		1.677e-2,
		2.366e-2,
		3.157e-2,
		4.044e-2,
		5.023e-2,
		6.088e-2
	);
	constant a2_0 : storage_coeff_real :=(
		-1.9025,
		-1.8486,
		-1.7918,
		-1.7323,
		-1.6704,
		-1.6061,
		-1.5398,
		-1.4715,
		-1.4015
	);
	constant a2_1 : storage_coeff_real :=(
		0.9139,
		0.8738,
		0.8357,
		0.7994,
		0.7650,
		0.7324,
		0.7016,
		0.6725,
		0.6451
	);
	constant s3 : storage_coeff_real :=(
		1.2071e-3,
		2.643e-3,
		4.582e-3,
		6.989e-3,
		9.84e-3,
		1.311e-2,
		1.678e-2,
		2.085e-2,
		2.53e-2
	);
	constant a3_0 : storage_coeff_real :=(
		-1.8792,
		-1.8204,
		-1.7624,
		-1.7053,
		-1.6488,
		-1.5930,
		-1.5376,
		-1.4827,
		-1.4281
	);
	constant a3_1 : storage_coeff_real :=(
		8.8403e-1,
		8.309e-1,
		7.807e-1,
		7.332e-1,
		6.882e-1,
		6.454e-1,
		6.048e-1,
		5.661e-1,
		5.293e-1
	);
	constant s4 : storage_coeff_real :=(
		0.65 * 1.6,
		0.8 * 1.6,
		0.65 * 1.6,
		0.65 * 1.6,
		0.65 * 1.6,
		0.65 * 1.6,
		0.65 * 1.6,
		0.65 * 1.6,
		0.65 * 1.6
	);


	constant w_s1 : storage_windows :=(
		10, 	10, 	10, 		10, 		10, 		10, 	10, 		10,		10
	);
	constant w_a0_1 : storage_windows :=(	
		10, 	10, 	10,			10, 		10, 		10, 	10, 		10,		10
	);
	constant w_a1_1 : storage_windows :=(
		10, 	10, 	10, 		10, 		10, 		10, 	10, 		10,		10
	);
	constant w_s2 : storage_windows :=(
		10, 	10, 	10, 		10,			10, 		10, 	10, 		10,		10
	);
	constant w_a0_2 : storage_windows :=(
		10, 	10, 	10, 		10, 		10, 		10, 	10, 		10,		10
	);
	constant w_a1_2 : storage_windows :=(
		10, 	10,		10, 		10, 		10, 		10, 	10, 		10,		10
	);
	constant w_s3 : storage_windows :=(
		10, 	10, 	10, 		10, 		10, 		10, 	10, 		10,		10
	);
	constant w_a0_3 : storage_windows :=(
		10, 	10, 	10, 		10,			10, 		10, 	10, 		10,		10
	);
	constant w_a1_3 : storage_windows :=(
		10, 	10, 	10, 		10, 		10, 		10, 	10, 		10,		10
	);
	constant w_s4 : storage_windows :=(
		10, 	10, 	10, 		10, 		10, 		10, 	10, 		10,		10
	);

begin

	GEN_CLOCK : process begin
		clk_fco <= '0';
		wait for 10 ps;
		clk_fco <= '1';
		wait for 10 ps;
	end process GEN_CLOCK;

	MAIN : process is
		variable f_line : line;
		file F : TEXT;	
		constant header : string := "IMPULSE RESPONCE";

		variable dout : integer;
	begin

		FILE_OPEN(F, "Z:/230_sch_sector/FIRMWARE/cu_75/cu75_warprj_03/vhdl/math/iir_impulse.txt", WRITE_MODE);

		wait for 5000 ps;
		reset <= '1';
		wait for 100 ps;
		reset <= '0';

		wait for 500 ps;
		wait until rising_edge(clk_fco);
		data_in <= std_logic_vector(to_signed(2047, 16));
		write(f_line, sint(data_out));
		writeline(F, f_line);
		wait until rising_edge(clk_fco);
		data_in <= std_logic_vector(to_signed(0, 16));
		write(f_line, sint(data_out));
		writeline(F, f_line);


		
		--write(f_line, header);
		--writeline(F, f_line);
		

		for i in 0 to 2045 loop
			wait until rising_edge(clk_fco);
			write(f_line, sint(data_out));
			writeline(F, f_line);
		end loop;

		FILE_CLOSE(F);
		
		wait;

	end process;


			

iir_filter_unit : iir_filter
	generic map(
		w_s1  	=> w_s1(fc) - 5,
		w_a0_1	=> w_a0_1(fc),
		w_a1_1	=> w_a1_1(fc),
		w_s2  	=> w_s1(fc) - 5,
		w_a0_2	=> w_a0_1(fc),
		w_a1_2	=> w_a1_1(fc),
		w_s3  	=> w_s1(fc) - 5,
		w_a0_3	=> w_a0_1(fc),
		w_a1_3	=> w_a1_1(fc),
		w_s4	=> w_s4(fc) + 15
	)
	port map(
		coeff_s_1  => std_logic_vector(to_signed(natural(s1(fc) * real(2**		w_s1(fc))), 16)),
		coeff_a0_1 => std_logic_vector(to_signed(natural(a1_0(fc) * real(2**	w_a0_1(fc))), 16)),
		coeff_a1_1 => std_logic_vector(to_signed(natural(a1_1(fc) * real(2**	w_a1_1(fc))), 16)),

		coeff_s_2  => std_logic_vector(to_signed(natural(s2(fc) * real(2**		w_s1(fc))), 16)),
		coeff_a0_2 => std_logic_vector(to_signed(natural(a2_0(fc) * real(2**	w_a0_1(fc))), 16)),
		coeff_a1_2 => std_logic_vector(to_signed(natural(a2_1(fc) * real(2**	w_a1_1(fc))), 16)),

		coeff_s_3  => std_logic_vector(to_signed(natural(s3(fc) * real(2**		w_s1(fc))), 16)),
		coeff_a0_3 => std_logic_vector(to_signed(natural(a3_0(fc) * real(2**	w_a0_1(fc))), 16)),
		coeff_a1_3 => std_logic_vector(to_signed(natural(a3_1(fc) * real(2**	w_a1_1(fc))), 16)),

		coeff_s_4  => std_logic_vector(to_signed(natural(s4(fc) * real(2**		w_s4(fc))), 16)),

		clk_fco => clk_fco,
		reset   => reset,

		data_in  => data_in,
		data_out => data_out
	);

end tb_iir_filter_bvh;