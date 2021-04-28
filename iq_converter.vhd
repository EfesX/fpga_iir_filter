library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;


library work;
use work.common_package.all;

entity iq_converter is
	generic(
		w_s1  	: natural := 8;
		w_a1_0	: natural := 8;
		w_a1_1	: natural := 8;
		w_s2  	: natural := 8;
		w_a2_0	: natural := 8;
		w_a2_1	: natural := 8;
		w_s3  	: natural := 8;
		w_a3_0	: natural := 8;
		w_a3_1	: natural := 8;
		w_s4	: natural := 8;

		number : std_logic_vector(3 downto 0) := x"0"
	);
	port(
		adc_fco 	: in std_logic := '0';
		reset 		: in std_logic := '0';
		adc_valid 	: in std_logic := '0';

		work_mode : in std_logic_vector(2 downto 0) := "000";

		fc_lowpass 	: in std_logic_vector(3 downto 0) := (others => '0');
		k_decim		: in std_logic_vector(3 downto 0) := (others => '0');

		data_in 	: in  std_logic_vector(11 downto 0) := (others => '0');
		
		i_fifo_rdclk		: in  std_logic;
		i_fifo_rdreq		: in  std_logic;
		i_fifo_q			: out std_logic_vector (15 downto 0);
		i_fifo_rdempty		: out std_logic;

		iq_conv_cnt_data : out std_logic_vector(15 downto 0);
		fifo_clear : in std_logic;

		q_fifo_rdclk		: in  std_logic;
		q_fifo_rdreq		: in  std_logic;
		q_fifo_q			: out std_logic_vector (15 downto 0);
		q_fifo_rdempty		: out std_logic
	);
end entity iq_converter;

architecture iq_converter_bhv of iq_converter is
	component iq_shaper is
		port(
			reset	: in std_logic := '0';
			
			adc_fco		: in std_logic := '0';
			adc_data	: in std_logic_vector(11 downto 0) := (others => '0');
			
			i_out : out std_logic_vector(15 downto 0) := (others => '0');
			q_out : out std_logic_vector(15 downto 0) := (others => '0')
		);
	end component iq_shaper;

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
	end component iir_filter;

	component decimator is
		port(
			reset	: in std_logic := '0';
			adc_fco	: in std_logic := '0';
		
			k : in std_logic_vector(3 downto 0) := (others => '0');
	
			adc_data_in 		: in  std_logic_vector(15 downto 0) := (others => '0');
			adc_data_out 		: out std_logic_vector(15 downto 0) := (others => '0');
			adc_data_dec_valid	: out std_logic := '0'
		);
	end component decimator;	

	component storage_coefficients is
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
	end component storage_coefficients;

	component fifo16x64 is
		port(
			wrreq		: in  std_logic;
			wrclk		: in  std_logic;
			data		: in  std_logic_vector (15 downto 0);
			
			rdclk		: in  std_logic;
			rdreq		: in  std_logic;
			q			: out std_logic_vector (15 downto 0);

			rdempty		: out std_logic;
			aclr		: in  std_logic
		);
	end component fifo16x64;

	signal i_sh, q_sh 					:  std_logic_vector(15 downto 0);
	signal i_filt_out, q_filt_out 		:  std_logic_vector(15 downto 0);
	signal s_i_filt_out, s_q_filt_out 	:  std_logic_vector(15 downto 0);

	signal coeff_s_1  :  std_logic_vector(15 downto 0);
	signal coeff_a1_0 :  std_logic_vector(15 downto 0);
	signal coeff_a1_1 :  std_logic_vector(15 downto 0);

	signal coeff_s_2  :  std_logic_vector(15 downto 0);
	signal coeff_a2_0 :  std_logic_vector(15 downto 0);
	signal coeff_a2_1 :  std_logic_vector(15 downto 0);

	signal coeff_s_3  :  std_logic_vector(15 downto 0);
	signal coeff_a3_0 :  std_logic_vector(15 downto 0);
	signal coeff_a3_1 :  std_logic_vector(15 downto 0);

	signal coeff_s_4  :  std_logic_vector(15 downto 0);

	signal fifo_wrreq_1		: std_logic;
	signal fifo_wrclk_1		: std_logic;
	signal fifo_data_1		: std_logic_vector (15 downto 0);
	signal fifo_rdclk_1		: std_logic;
	signal fifo_rdreq_1		: std_logic;
	signal fifo_q_1			: std_logic_vector (15 downto 0);
	signal fifo_rdempty_1	: std_logic; 

	signal fifo_wrreq_2		: std_logic;
	signal fifo_wrclk_2		: std_logic;
	signal fifo_data_2		: std_logic_vector (15 downto 0);
	signal fifo_rdclk_2		: std_logic;
	signal fifo_rdreq_2		: std_logic;
	signal fifo_q_2			: std_logic_vector (15 downto 0);
	signal fifo_rdempty_2	: std_logic; 

	signal s_adc_valid 					: std_logic := '1';
	signal decim_i_valid, decim_q_valid : std_logic := '0';
	signal decim_i_out, decim_q_out		: std_logic_vector(15 downto 0);

	signal data_cnt : integer range 0 to 8191 := 0;

	signal s_fifo_clear : std_logic := '0';

	signal cnt_lock : std_logic := '0';
begin
	s_fifo_clear <= fifo_clear;
	
	iq_conv_cnt_data <= stdu(data_cnt, 16);

	s_adc_valid <= not adc_valid; -- когда adc_valid = 0 данные не собираются, fifo переводится в состояние сброса.
								  -- тем не менее, квадратурный преобразователь продолжает работу
	fifo_wrclk_1 <= adc_fco;
	fifo_wrclk_2 <= adc_fco;

	fifo_rdclk_1 	<= i_fifo_rdclk;
	fifo_rdreq_1 	<= i_fifo_rdreq;
	i_fifo_q		<= fifo_q_1;
	i_fifo_rdempty	<= fifo_rdempty_1;

	fifo_rdclk_2 	<= q_fifo_rdclk;
	fifo_rdreq_2 	<= q_fifo_rdreq;
	q_fifo_q		<= fifo_q_2;
	q_fifo_rdempty	<= fifo_rdempty_2;

	process (s_adc_valid, adc_fco) begin
		if s_adc_valid = '1' then
			fifo_wrreq_1 <= '0';
			fifo_wrreq_2 <= '0';

			fifo_data_1 <= (others => '0');
			fifo_data_2 <= (others => '0');

			--data_cnt <= 0;
			cnt_lock <= '1';

		elsif rising_edge(adc_fco) then

			s_i_filt_out <= i_filt_out;
			s_q_filt_out <= q_filt_out;

			case work_mode is -- режим сбора данных
				when "000" => -- данные не собираются
					fifo_data_1 <= (others => '0');
					fifo_data_2 <= (others => '0');

					fifo_wrreq_1 <= '0';
					fifo_wrreq_2 <= '0';

				when  "001" => -- собирается сырой поток с АЦП
					fifo_data_1 <= number & data_in;
					fifo_data_2 <= x"0000";

					if s_adc_valid = '0' then
						fifo_wrreq_1 <= '1';
						fifo_wrreq_2 <= '1';
						if cnt_lock = '1' then
							data_cnt <= 0;
							cnt_lock <= '0';
						else
							data_cnt <= data_cnt + 1;
						end if;
					end if;

				when "010" => -- собираются данные с выхода гетеродина
					fifo_data_1 <= i_sh;
					fifo_data_2 <= q_sh; 

					if s_adc_valid = '0' then
						fifo_wrreq_1 <= '1';
						fifo_wrreq_2 <= '1';
						if cnt_lock = '1' then
							data_cnt <= 0;
							cnt_lock <= '0';
						else
							data_cnt <= data_cnt + 1;
						end if;
					end if;

				when "011" => -- собираются данные с выхода ФНЧ
					fifo_data_1 <= s_i_filt_out;
					fifo_data_2 <= s_q_filt_out;

					if s_adc_valid = '0' then
						fifo_wrreq_1 <= '1';
						fifo_wrreq_2 <= '1';
						if cnt_lock = '1' then
							data_cnt <= 0;
							cnt_lock <= '0';
						else
							data_cnt <= data_cnt + 1;
						end if;
					end if;

				when "100" => -- собираются данные с выхода дециматора (штатный режим работы)
					fifo_data_1 <= decim_i_out;
					fifo_data_2 <= decim_q_out;
		
					if s_adc_valid = '0' then
						fifo_wrreq_1 <= decim_i_valid;
						fifo_wrreq_2 <= decim_q_valid;
						if cnt_lock = '1' then
							data_cnt <= 0;
							cnt_lock <= '0';
						else
							data_cnt <= data_cnt + 1;
						end if;
					end if;

				when others => 
					fifo_wrreq_1 <= '0';
					fifo_wrreq_2 <= '0';
			end case;

		end if;
	end process;


	i_fifo_unit : fifo16x64
		port map(
			wrreq		=> fifo_wrreq_1,
			wrclk		=> fifo_wrclk_1,
			data		=> fifo_data_1,

			rdclk		=> fifo_rdclk_1,
			rdreq		=> fifo_rdreq_1,
			q			=> fifo_q_1,

			rdempty		=> fifo_rdempty_1,
			aclr		=> s_fifo_clear
		);

	q_fifo_unit : fifo16x64
		port map(
			wrreq		=> fifo_wrreq_2,
			wrclk		=> fifo_wrclk_2,
			data		=> fifo_data_2,
			rdclk		=> fifo_rdclk_2,
			rdreq		=> fifo_rdreq_2,
			q			=> fifo_q_2,
			rdempty		=> fifo_rdempty_2,
			aclr		=> s_fifo_clear
		);

	iq_shaper_unit : iq_shaper
		port map(
			reset		=> reset,
			adc_fco		=> adc_fco,
			adc_data 	=> data_in,
			i_out 		=> i_sh,
			q_out 		=> q_sh
		);

	i_iir_filter_unit : iir_filter
		generic map(
			w_s1  	=> w_s1,
			w_a0_1	=> w_a1_0,
			w_a1_1	=> w_a1_1,
			w_s2  	=> w_s2,
			w_a0_2	=> w_a2_0,
			w_a1_2	=> w_a2_1,
			w_s3  	=> w_s3,
			w_a0_3	=> w_a3_0,
			w_a1_3	=> w_a3_1,
			w_s4	=> w_s4
		)
		port map(
			coeff_s_1  => coeff_s_1,
			coeff_a0_1 => coeff_a1_0,
			coeff_a1_1 => coeff_a1_1,
	
			coeff_s_2  => coeff_s_2,
			coeff_a0_2 => coeff_a2_0,
			coeff_a1_2 => coeff_a2_1,
	
			coeff_s_3  => coeff_s_3,
			coeff_a0_3 => coeff_a3_0,
			coeff_a1_3 => coeff_a3_1,
	
			coeff_s_4  => coeff_s_4,
	
			clk_fco => adc_fco,
			reset   => reset,
	
			data_in  => i_sh,
			data_out => i_filt_out
		);
	
	q_iir_filter_unit : iir_filter
		generic map(
			w_s1  	=> w_s1,
			w_a0_1	=> w_a1_0,
			w_a1_1	=> w_a1_1,
			w_s2  	=> w_s2,
			w_a0_2	=> w_a2_0,
			w_a1_2	=> w_a2_1,
			w_s3  	=> w_s3,
			w_a0_3	=> w_a3_0,
			w_a1_3	=> w_a3_1,
			w_s4	=> w_s4
		)
		port map(
			coeff_s_1  => coeff_s_1,
			coeff_a0_1 => coeff_a1_0,
			coeff_a1_1 => coeff_a1_1,
	
			coeff_s_2  => coeff_s_2,
			coeff_a0_2 => coeff_a2_0,
			coeff_a1_2 => coeff_a2_1,
	
			coeff_s_3  => coeff_s_3,
			coeff_a0_3 => coeff_a3_0,
			coeff_a1_3 => coeff_a3_1,
	
			coeff_s_4  => coeff_s_4,
	
			clk_fco => adc_fco,
			reset   => reset,
	
			data_in  => q_sh,
			data_out => q_filt_out
		);
		
	i_decim_unit : decimator
		port map(
			reset	=> reset,
			adc_fco	=> adc_fco,
		
			k => k_decim,
	
			adc_data_in 		=> i_filt_out,
			adc_data_out 		=> decim_i_out,
			adc_data_dec_valid	=> decim_i_valid
		);

	q_decim_unit : decimator
		port map(
			reset	=> reset,
			adc_fco	=> adc_fco,
		
			k => k_decim,
	
			adc_data_in 		=> q_filt_out,
			adc_data_out 		=> decim_q_out,
			adc_data_dec_valid	=> decim_q_valid
		);

	stor_coeff_unit : storage_coefficients
		generic map(
			w_s1  	=> 10,
			w_a1_0	=> 10,
			w_a1_1	=> 10,
			w_s2  	=> 10,
			w_a2_0	=> 10,
			w_a2_1	=> 10,
			w_s3  	=> 10,
			w_a3_0	=> 10,
			w_a3_1	=> 10,
			w_s4	=> 10
		)
		port map(
			fc => fc_lowpass,

			coeff_s_1  => coeff_s_1,
			coeff_a1_0 => coeff_a1_0,
			coeff_a1_1 => coeff_a1_1,

			coeff_s_2  => coeff_s_2,
			coeff_a2_0 => coeff_a2_0,
			coeff_a2_1 => coeff_a2_1,

			coeff_s_3  => coeff_s_3,
			coeff_a3_0 => coeff_a3_0,
			coeff_a3_1 => coeff_a3_1,

			coeff_s_4  => coeff_s_4
		);

end architecture iq_converter_bhv;