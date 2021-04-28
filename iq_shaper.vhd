library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_signed.all;

entity iq_shaper is
	port(
		reset	: in std_logic := '0';
		
		adc_fco		: in std_logic := '0';
		adc_data 	: in std_logic_vector(11 downto 0) := (others => '0');
		
		i_out : out std_logic_vector(15 downto 0) := (others => '0');
		q_out : out std_logic_vector(15 downto 0) := (others => '0')
		
	);
end entity iq_shaper;

architecture iq_shaper_bhv of iq_shaper is
	signal s_data_in : std_logic_vector(11 downto 0) := (others => '0');
	--signal shift_mod : std_logic_vector(3 downto 0) := "1000";

	signal het_phase : integer range 0 to 4 := 4;



	component mult12x10_22 IS
		port(
			clock		: in std_logic;
			dataa		: in std_logic_vector (11 DOWNTO 0);
			datab		: in std_logic_vector (12 DOWNTO 0);
			result		: out std_logic_vector (24 DOWNTO 0)
		);
	end component;


	type koeff is array (0 to 4) of std_logic_vector(12 downto 0);

	signal cos_k : koeff := (
		"0111111111111", -- 1
		"0010011110010", -- 0.309
		"1001100001110", -- -0.809
		"1001100001110", -- -0.809
		"0010011110010" -- 0.309
	);
	signal sin_k : koeff := (
		"0000000000000", -- 0
		"0111100111000", -- 0.9511
		"0100101101000", -- 0.5878
		"1011010011000", -- -0.5878
		"1000011001000"  -- -0.9511
	);

	signal sin_result, cos_result : std_logic_vector(24 downto 0) ;
	signal s, c : std_logic_vector(12 downto 0) := (others => '0');
	

begin

	mult_unit_sin : mult12x10_22 -- построен на логике, т.к. закончились умножители
	port map(
		clock		=> adc_fco,
		dataa		=> s_data_in,
		datab		=> s,
		result		=> sin_result
	);

	mult_unit_cos : mult12x10_22 -- построен на логике, т.к. закончились умножители
	port map(
		clock		=> adc_fco,
		dataa		=> s_data_in,
		datab		=> c,
		result		=> cos_result
	);


	process (reset, adc_fco )begin
		if reset = '1' then
			s_data_in <= (others => '0');
			het_phase <= 0;
			i_out <= (others => '0');
			q_out <= (others => '0');

		elsif rising_edge(adc_fco) then
			s_data_in <= ((not adc_data(11)) & adc_data(10 downto 0)) + 1;

			i_out <= std_logic_vector(resize(signed(sin_result(24 downto 13)), 16));
			q_out <= std_logic_vector(resize(signed(cos_result(24 downto 13)), 16));
			s <= sin_k(het_phase);
			c <= cos_k(het_phase);

			if het_phase = 4 then
				het_phase <= 0;
			else
				het_phase <= het_phase + 1;
			end if;
				
		end if ;
	end process;

end architecture iq_shaper_bhv;