library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.numeric_std.all;

library work;
use work.common_package.all;


entity iir_filter is
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
		w_s4	: natural := 8
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
end entity iir_filter;


architecture iir_filter_bhv of iir_filter is
	component iir_cascade is
		generic(
			w_s  : natural := 8;
			w_a0 : natural := 8;
			w_a1 : natural := 8
		);
		port(
			coeff_s  : in std_logic_vector(15 downto 0) := (others => '0');
			coeff_a0 : in std_logic_vector(15 downto 0) := (others => '0');
			coeff_a1 : in std_logic_vector(15 downto 0) := (others => '0');
	
			clk_fco : in std_logic := '0';
			reset   : in std_logic := '0';
	
			data_in  : in  std_logic_vector(31 downto 0) := (others => '0');
			data_out : out std_logic_vector(31 downto 0) := (others => '0')
		);
	end component iir_cascade;

	component iir_cascade_first is
		generic(
			w_s  : natural := 8;
			w_a0 : natural := 8;
			w_a1 : natural := 8
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
	end component iir_cascade_first;

	component mult16x32_48lat1 IS
		port(
			clock 		: in std_logic := '0'; 
			dataa		: in std_logic_vector (15 DOWNTO 0);
			datab		: in std_logic_vector (31 DOWNTO 0);
			result		: out std_logic_vector (47 DOWNTO 0)
		);
	end component;

	signal data_1to2, data_2to3, data_3tomult  : std_logic_vector(31 downto 0) := (others => '0');
	signal s_coeff_s_4 : std_logic_vector(15 downto 0) := (others => '0');
	signal multresult : std_logic_vector(47 downto 0) := (others => '0');
	signal s_data_in : std_logic_vector(15 downto 0);

begin
	
	s_data_in <= data_in;

	process (reset, clk_fco) begin
		if reset = '1' then
			s_coeff_s_4 <= coeff_s_4;
		elsif rising_edge(clk_fco) then
			data_out <=	std_logic_vector(resize(signed(multresult(47 downto w_s4)), 16));
			
		end if;
	end process;

	iir_casc_1 : iir_cascade_first
		generic map(
			w_s  => w_s1,
			w_a0 => w_a0_1,
			w_a1 => w_a1_1
		)
		port map(
			coeff_s  => coeff_s_1,
			coeff_a0 => coeff_a0_1,
			coeff_a1 => coeff_a1_1,

			clk_fco => clk_fco,
			reset   => reset,

			data_in  => s_data_in,
			data_out => data_1to2
		);

	iir_casc_2 : iir_cascade
		generic map(
			w_s  => w_s2,
			w_a0 => w_a0_2,
			w_a1 => w_a1_2
		)
		port map(
			coeff_s  => coeff_s_2,
			coeff_a0 => coeff_a0_2,
			coeff_a1 => coeff_a1_2,

			clk_fco => clk_fco,
			reset   => reset,

			data_in  => data_1to2,
			data_out => data_2to3
		);

	iir_casc_3 : iir_cascade
		generic map(
			w_s  => w_s3,
			w_a0 => w_a0_3,
			w_a1 => w_a1_3
		)
		port map(
			coeff_s  => coeff_s_3,
			coeff_a0 => coeff_a0_3,
			coeff_a1 => coeff_a1_3,

			clk_fco => clk_fco,
			reset   => reset,

			data_in  => data_2to3,
			data_out => data_3tomult
		);

	mult_out : mult16x32_48lat1
		port map(
			clock	=> clk_fco,
			dataa	=> s_coeff_s_4,
			datab	=> data_3tomult,
			result	=> multresult
		);

end architecture iir_filter_bhv;