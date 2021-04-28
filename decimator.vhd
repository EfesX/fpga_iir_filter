library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_signed.all;

entity decimator is
	port(
		reset	: in std_logic := '0';
		adc_fco	: in std_logic := '0';
	
		k : in std_logic_vector(3 downto 0) := (others => '0');

		adc_data_in 		: in  std_logic_vector(15 downto 0) := (others => '0');
		adc_data_out 		: out std_logic_vector(15 downto 0) := (others => '0');
		adc_data_dec_valid	: out std_logic := '0'
	);
end entity decimator;

architecture decimator_bhv of decimator is
	signal s_k : std_logic_vector(3 downto 0) := "0001";
	signal dec_cnt : integer range 1 to 12 := 1;
	signal s_data_in : std_logic_vector(15 downto 0) := (others => '0');
begin

	process (reset, adc_fco) begin
		if reset = '1' then
			if k = "0000" then
				s_k <= "0001";
			else
				s_k <= k;
			end if;
			
			s_data_in      			<= (others => '0');
			adc_data_out			<= (others => '0');
			adc_data_dec_valid		<= '0';
			dec_cnt					<=  1;
		elsif rising_edge(adc_fco) then
			s_data_in 		<= adc_data_in;

			if dec_cnt = 1 then
				dec_cnt 		<= to_integer(unsigned(s_k));
				adc_data_out	<= s_data_in;
				adc_data_dec_valid <= '1';
			else
				adc_data_dec_valid <= '0';
				dec_cnt <= dec_cnt - 1;
			end if;
		end if;
	end process;

end architecture decimator_bhv;