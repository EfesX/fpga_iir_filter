library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.numeric_std.all;

library work;
use work.common_package.all;

entity iir_cascade_first is
	generic(
		w_s  : natural := 0;
		w_a0 : natural := 0;
		w_a1 : natural := 0
	);
	port(
		coeff_s  : in std_logic_vector(15 downto 0) := (others => '0');
		coeff_a0 : in std_logic_vector(15 downto 0) := (others => '0');
		coeff_a1 : in std_logic_vector(15 downto 0) := (others => '0');

		clk_fco : in std_logic := '0';
		reset   : in std_logic := '0';

		data_in  : in  std_logic_vector(15 downto 0) := (others => '0');
		data_out : out std_logic_vector(31 downto 0) := (others => '0')
	);
end entity iir_cascade_first;

architecture iir_cascade_first_bhv of iir_cascade_first is
	
	component mult16x32_48 IS
		port(
			--clock 		: in std_logic := '0'; 
			dataa		: in std_logic_vector (15 DOWNTO 0);
			datab		: in std_logic_vector (31 DOWNTO 0);
			result		: out std_logic_vector (47 DOWNTO 0)
		);
	end component;

	component mult16x16_32lat2 IS
		port(
			clock 		: in std_logic := '0'; 
			dataa		: in std_logic_vector (15 DOWNTO 0);
			datab		: in std_logic_vector (15 DOWNTO 0);
			result		: out std_logic_vector (31 DOWNTO 0)
		);
	end component;

	
	signal s_coeff_s  : std_logic_vector(15 downto 0) := (others => '0');
	signal s_coeff_a0 : std_logic_vector(15 downto 0) := (others => '0');
	signal s_coeff_a1 : std_logic_vector(15 downto 0) := (others => '0');

	type buf_x is array (0 to 5) of std_logic_vector(31 downto 0);
	type buf_y is array (0 to 2) of std_logic_vector(31 downto 0);
	signal x : buf_x := (x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000");
	signal y : buf_y := (x"00000000", x"00000000", x"00000000");

	signal inxs_32, bxx0_32, a0xy1_32, a1xy2_32 : std_logic_vector(31 downto 0) := (others => '0');
	signal inxs_48, a0xy1_48, a1xy2_48 : std_logic_vector(47 downto 0) := (others => '0');
	signal bxx0_34 : std_logic_vector(33 downto 0) := (others => '0');

	signal sum1, sum2 : std_logic_vector(31 downto 0) := (others => '0');
	signal s_data_in : std_logic_vector(15 downto 0) := (others => '0');

begin

	--inxs_32  <= std_logic_vector(resize(signed(inxs_64(63 downto w_s)), 32));
	--bxx0_32  <= std_logic_vector(resize(signed(bxx0_64), 32));
	a0xy1_32 <= std_logic_vector(resize(signed(a0xy1_48(47 downto w_a0)), 32));
	a1xy2_32 <= std_logic_vector(resize(signed(a1xy2_48(47 downto w_a1)), 32));

	process (reset, clk_fco) begin
		if reset = '1' then
			s_coeff_s	<= coeff_s;
			s_coeff_a0	<= coeff_a0;
			s_coeff_a1	<= coeff_a1;

			x(0) <= (others => '0');
			x(1) <= (others => '0');
			x(2) <= (others => '0');
			x(3) <= (others => '0');
			x(4) <= (others => '0');
			x(5) <= (others => '0');
			y(0) <= (others => '0');
			y(1) <= (others => '0');
			y(2) <= (others => '0');

			s_data_in	<= (others => '0');
			data_out 	<= (others => '0');

			--inxs_32 <= (others => '0');
			bxx0_32 <= (others => '0');
			bxx0_34 <= (others => '0');

			sum1 <= (others => '0');
			sum2 <= (others => '0');

		elsif rising_edge(clk_fco) then
			s_data_in <= data_in;

			--inxs_32  <= std_logic_vector(resize(signed(inxs_48(47 downto w_s)), 32));
			
			bxx0_34  <= std_logic_vector(resize(signed(x(1) & '0'), 34)); -- умножение на 2
			bxx0_32  <= std_logic_vector(resize(signed(bxx0_34), 32));

			x(0) <= std_logic_vector(resize(signed(inxs_32(31 downto w_s)), 32));
			x(1) <= x(0);
			x(2) <= x(1);
			x(3) <= x(2);
			x(4) <= x(3);
			x(5) <= x(4);

			sum1 <= x(2) + bxx0_32;
			sum2 <= sum1 + x(5);

			y(0) <= sum2 - (a0xy1_32 + a1xy2_32);
			--y(0) <= x(2) + bxx0_32 + x(4) - a0xy1_32 - a1xy2_32;
			y(1) <= y(0);
			y(2) <= y(1);

			data_out <= y(2);

			  
		end if;
	end process;
	

	mult_inxs : mult16x16_32lat2
		port map(
			clock	=> clk_fco,
			dataa	=> s_coeff_s,
			datab	=> s_data_in,
			result	=> inxs_32
		);


	mult_a0xy1 : mult16x32_48
		port map(
			--clock	=> clk_fco,
			dataa	=> s_coeff_a0,
			datab	=> y(0),
			result	=> a0xy1_48
		);

	mult_a1xy2 : mult16x32_48
		port map(
			--clock	=> clk_fco,
			dataa	=> s_coeff_a1,
			datab	=> y(1),
			result	=> a1xy2_48
		);

	
end architecture iir_cascade_first_bhv;