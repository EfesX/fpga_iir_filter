library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity storage_coefficients is
	generic(
		w_s1  	: natural := 10;
		w_a1_0	: natural := 10;
		w_a1_1	: natural := 10;
		w_s2  	: natural := 10;
		w_a2_0	: natural := 10;
		w_a2_1	: natural := 10;
		w_s3  	: natural := 10;
		w_a3_0	: natural := 10;
		w_a3_1	: natural := 10;
		w_s4	: natural := 10
	);
	port(
		fc : in std_logic_vector(3 downto 0) := (others => '0');

		coeff_s_1  : out std_logic_vector(15 downto 0) := (others => '0');
		coeff_a1_0 : out std_logic_vector(15 downto 0) := (others => '0');
		coeff_a1_1 : out std_logic_vector(15 downto 0) := (others => '0');

		coeff_s_2  : out std_logic_vector(15 downto 0) := (others => '0');
		coeff_a2_0 : out std_logic_vector(15 downto 0) := (others => '0');
		coeff_a2_1 : out std_logic_vector(15 downto 0) := (others => '0');

		coeff_s_3  : out std_logic_vector(15 downto 0) := (others => '0');
		coeff_a3_0 : out std_logic_vector(15 downto 0) := (others => '0');
		coeff_a3_1 : out std_logic_vector(15 downto 0) := (others => '0');

		coeff_s_4  : out std_logic_vector(15 downto 0) := (others => '0')
	);
end entity storage_coefficients;


architecture storage_coefficients_bhv of storage_coefficients is

	type storage_coeff_real is array (0 to 8) of real;
	type storage_windows    is array (0 to 8) of natural;
	type storage_coeff_std  is array (0 to 8) of std_logic_vector(15 downto 0);

	constant s1 : storage_coeff_real :=(
		0.0046130, 	--   1 MHz
		0.01027,	-- 1.5 MHz
		0.01805,	--   2 MHz
		0.02786,	-- 2.5 MHz
		0.03961,	--   3 MHz
		0.05318,	-- 3.5 MHz
		0.06847,	--   4 MHz
		8.537e-2,	-- 4.5 MHz
		0.1037		--   5 MHz
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
		0.65 * 1.6,
		0.65 * 1.6,
		0.65 * 1.6,
		0.65 * 1.6,
		0.65 * 1.6,
		0.65 * 1.6,
		0.65 * 1.6,
		0.65 * 1.6
	);

	constant s1_std : storage_coeff_std := (
		std_logic_vector(to_signed(natural(s1(0) * real(2**		w_s1)), 16)),
		std_logic_vector(to_signed(natural(s1(1) * real(2**		w_s1)), 16)),
		std_logic_vector(to_signed(natural(s1(2) * real(2**		w_s1)), 16)),
		std_logic_vector(to_signed(natural(s1(3) * real(2**		w_s1)), 16)),
		std_logic_vector(to_signed(natural(s1(4) * real(2**		w_s1)), 16)),
		std_logic_vector(to_signed(natural(s1(5) * real(2**		w_s1)), 16)),
		std_logic_vector(to_signed(natural(s1(6) * real(2**		w_s1)), 16)),
		std_logic_vector(to_signed(natural(s1(7) * real(2**		w_s1)), 16)),
		std_logic_vector(to_signed(natural(s1(8) * real(2**		w_s1)), 16))
	);
	constant s2_std : storage_coeff_std := (
		std_logic_vector(to_signed(natural(s2(0) * real(2**		w_s2)), 16)),
		std_logic_vector(to_signed(natural(s2(1) * real(2**		w_s2)), 16)),
		std_logic_vector(to_signed(natural(s2(2) * real(2**		w_s2)), 16)),
		std_logic_vector(to_signed(natural(s2(3) * real(2**		w_s2)), 16)),
		std_logic_vector(to_signed(natural(s2(4) * real(2**		w_s2)), 16)),
		std_logic_vector(to_signed(natural(s2(5) * real(2**		w_s2)), 16)),
		std_logic_vector(to_signed(natural(s2(6) * real(2**		w_s2)), 16)),
		std_logic_vector(to_signed(natural(s2(7) * real(2**		w_s2)), 16)),
		std_logic_vector(to_signed(natural(s2(8) * real(2**		w_s2)), 16))
	);
	constant s3_std : storage_coeff_std := (
		std_logic_vector(to_signed(natural(s3(0) * real(2**		w_s3)), 16)),
		std_logic_vector(to_signed(natural(s3(1) * real(2**		w_s3)), 16)),
		std_logic_vector(to_signed(natural(s3(2) * real(2**		w_s3)), 16)),
		std_logic_vector(to_signed(natural(s3(3) * real(2**		w_s3)), 16)),
		std_logic_vector(to_signed(natural(s3(4) * real(2**		w_s3)), 16)),
		std_logic_vector(to_signed(natural(s3(5) * real(2**		w_s3)), 16)),
		std_logic_vector(to_signed(natural(s3(6) * real(2**		w_s3)), 16)),
		std_logic_vector(to_signed(natural(s3(7) * real(2**		w_s3)), 16)),
		std_logic_vector(to_signed(natural(s3(8) * real(2**		w_s3)), 16))
	);
	constant s4_std : storage_coeff_std := (
		std_logic_vector(to_signed(natural(s4(0) * real(2**		w_s4)), 16)),
		std_logic_vector(to_signed(natural(s4(1) * real(2**		w_s4)), 16)),
		std_logic_vector(to_signed(natural(s4(2) * real(2**		w_s4)), 16)),
		std_logic_vector(to_signed(natural(s4(3) * real(2**		w_s4)), 16)),
		std_logic_vector(to_signed(natural(s4(4) * real(2**		w_s4)), 16)),
		std_logic_vector(to_signed(natural(s4(5) * real(2**		w_s4)), 16)),
		std_logic_vector(to_signed(natural(s4(6) * real(2**		w_s4)), 16)),
		std_logic_vector(to_signed(natural(s4(7) * real(2**		w_s4)), 16)),
		std_logic_vector(to_signed(natural(s4(8) * real(2**		w_s4)), 16))
	);
		constant a1_0_std : storage_coeff_std := (
			std_logic_vector(to_signed(natural(a1_0(0) * real(2**		w_a1_0)), 16)),
			std_logic_vector(to_signed(natural(a1_0(1) * real(2**		w_a1_0)), 16)),
			std_logic_vector(to_signed(natural(a1_0(2) * real(2**		w_a1_0)), 16)),
			std_logic_vector(to_signed(natural(a1_0(3) * real(2**		w_a1_0)), 16)),
			std_logic_vector(to_signed(natural(a1_0(4) * real(2**		w_a1_0)), 16)),
			std_logic_vector(to_signed(natural(a1_0(5) * real(2**		w_a1_0)), 16)),
			std_logic_vector(to_signed(natural(a1_0(6) * real(2**		w_a1_0)), 16)),
			std_logic_vector(to_signed(natural(a1_0(7) * real(2**		w_a1_0)), 16)),
			std_logic_vector(to_signed(natural(a1_0(8) * real(2**		w_a1_0)), 16))
		);
		constant a1_1_std : storage_coeff_std := (
			std_logic_vector(to_signed(natural(a1_1(0) * real(2**		w_a1_1)), 16)),
			std_logic_vector(to_signed(natural(a1_1(1) * real(2**		w_a1_1)), 16)),
			std_logic_vector(to_signed(natural(a1_1(2) * real(2**		w_a1_1)), 16)),
			std_logic_vector(to_signed(natural(a1_1(3) * real(2**		w_a1_1)), 16)),
			std_logic_vector(to_signed(natural(a1_1(4) * real(2**		w_a1_1)), 16)),
			std_logic_vector(to_signed(natural(a1_1(5) * real(2**		w_a1_1)), 16)),
			std_logic_vector(to_signed(natural(a1_1(6) * real(2**		w_a1_1)), 16)),
			std_logic_vector(to_signed(natural(a1_1(7) * real(2**		w_a1_1)), 16)),
			std_logic_vector(to_signed(natural(a1_1(8) * real(2**		w_a1_1)), 16))
		);
	constant a2_0_std : storage_coeff_std := (
		std_logic_vector(to_signed(natural(a2_0(0) * real(2**		w_a2_0)), 16)),
		std_logic_vector(to_signed(natural(a2_0(1) * real(2**		w_a2_0)), 16)),
		std_logic_vector(to_signed(natural(a2_0(2) * real(2**		w_a2_0)), 16)),
		std_logic_vector(to_signed(natural(a2_0(3) * real(2**		w_a2_0)), 16)),
		std_logic_vector(to_signed(natural(a2_0(4) * real(2**		w_a2_0)), 16)),
		std_logic_vector(to_signed(natural(a2_0(5) * real(2**		w_a2_0)), 16)),
		std_logic_vector(to_signed(natural(a2_0(6) * real(2**		w_a2_0)), 16)),
		std_logic_vector(to_signed(natural(a2_0(7) * real(2**		w_a2_0)), 16)),
		std_logic_vector(to_signed(natural(a2_0(8) * real(2**		w_a2_0)), 16))
	);
	constant a2_1_std : storage_coeff_std := (
		std_logic_vector(to_signed(natural(a2_1(0) * real(2**		w_a2_1)), 16)),
		std_logic_vector(to_signed(natural(a2_1(1) * real(2**		w_a2_1)), 16)),
		std_logic_vector(to_signed(natural(a2_1(2) * real(2**		w_a2_1)), 16)),
		std_logic_vector(to_signed(natural(a2_1(3) * real(2**		w_a2_1)), 16)),
		std_logic_vector(to_signed(natural(a2_1(4) * real(2**		w_a2_1)), 16)),
		std_logic_vector(to_signed(natural(a2_1(5) * real(2**		w_a2_1)), 16)),
		std_logic_vector(to_signed(natural(a2_1(6) * real(2**		w_a2_1)), 16)),
		std_logic_vector(to_signed(natural(a2_1(7) * real(2**		w_a2_1)), 16)),
		std_logic_vector(to_signed(natural(a2_1(8) * real(2**		w_a2_1)), 16))
	);
	constant a3_0_std : storage_coeff_std := (
		std_logic_vector(to_signed(natural(a3_0(0) * real(2**		w_a3_0)), 16)),
		std_logic_vector(to_signed(natural(a3_0(1) * real(2**		w_a3_0)), 16)),
		std_logic_vector(to_signed(natural(a3_0(2) * real(2**		w_a3_0)), 16)),
		std_logic_vector(to_signed(natural(a3_0(3) * real(2**		w_a3_0)), 16)),
		std_logic_vector(to_signed(natural(a3_0(4) * real(2**		w_a3_0)), 16)),
		std_logic_vector(to_signed(natural(a3_0(5) * real(2**		w_a3_0)), 16)),
		std_logic_vector(to_signed(natural(a3_0(6) * real(2**		w_a3_0)), 16)),
		std_logic_vector(to_signed(natural(a3_0(7) * real(2**		w_a3_0)), 16)),
		std_logic_vector(to_signed(natural(a3_0(8) * real(2**		w_a3_0)), 16))
	);
	constant a3_1_std : storage_coeff_std := (
		std_logic_vector(to_signed(natural(a3_1(0) * real(2**		w_a3_1)), 16)),
		std_logic_vector(to_signed(natural(a3_1(1) * real(2**		w_a3_1)), 16)),
		std_logic_vector(to_signed(natural(a3_1(2) * real(2**		w_a3_1)), 16)),
		std_logic_vector(to_signed(natural(a3_1(3) * real(2**		w_a3_1)), 16)),
		std_logic_vector(to_signed(natural(a3_1(4) * real(2**		w_a3_1)), 16)),
		std_logic_vector(to_signed(natural(a3_1(5) * real(2**		w_a3_1)), 16)),
		std_logic_vector(to_signed(natural(a3_1(6) * real(2**		w_a3_1)), 16)),
		std_logic_vector(to_signed(natural(a3_1(7) * real(2**		w_a3_1)), 16)),
		std_logic_vector(to_signed(natural(a3_1(8) * real(2**		w_a3_1)), 16))
	);

begin
	coeff_s_1 	<= s1_std	(to_integer(unsigned(fc)));
	coeff_a1_0 	<= a1_0_std	(to_integer(unsigned(fc)));
	coeff_a1_1 	<= a1_1_std	(to_integer(unsigned(fc)));

	coeff_s_2 	<= s2_std	(to_integer(unsigned(fc)));
	coeff_a2_0 	<= a2_0_std	(to_integer(unsigned(fc)));
	coeff_a2_1 	<= a2_1_std	(to_integer(unsigned(fc)));

	coeff_s_3 	<= s3_std	(to_integer(unsigned(fc)));
	coeff_a3_0 	<= a3_0_std	(to_integer(unsigned(fc)));
	coeff_a3_1 	<= a3_1_std	(to_integer(unsigned(fc)));

	coeff_s_4 	<= s4_std	(to_integer(unsigned(fc)));
	
end architecture storage_coefficients_bhv;