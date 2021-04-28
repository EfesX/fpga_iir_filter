library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.numeric_std.all;


entity math_logic is
	generic(
		data_width 		: natural := 32;
		symbol_width 	: natural := 8;
		address_width	: natural := 9
	);
	port(
		core_clock : in std_logic := '0';
		lane_clock : in std_logic := '0';

		adc_fco 	: in std_logic := '0'; 
		alt_adc_fco : in std_logic := '0'; 

		adc_data_in_a 		: in std_logic_vector(11 downto 0) := (others => '0');
		adc_data_in_b 		: in std_logic_vector(11 downto 0) := (others => '0');
		
		alt_adc_data_in_a 	: in std_logic_vector(11 downto 0) := (others => '0');
		alt_adc_data_in_b 	: in std_logic_vector(11 downto 0) := (others => '0');

		adc_valid_in		: in std_logic := '0'; -- acquire_strob from ctr

		sdi_ready : in std_logic := '0';
		update_strb : in std_logic := '0';

		acq_data_count_in : in std_logic_vector(15 downto 0) := (others => '0');   -- acquire_tau from ctr

		m_data_completed 	: out std_logic := '0'; -- данные из FIFO выгружены
		m_data_is_empty		: out std_logic := '0'; -- выдается пустой отсчет АЦП (т.е. за время сбора данных не было ни одного превышения порога или ни одного отсчета АЦП)
		m_data_is_over		: out std_logic := '0'; -- выдаются последние данные из FIFO математики
		m_data_ready		: out std_logic := '0'; -- готовность данных в FIFO математики
		m_data_sdi_valid	: out std_logic := '0'; -- ??????????????????????????????????

		acq_data_count_out	: out std_logic_vector(15 downto 0) := (others => '0'); -- ???????????????????????????????????
		m_data_count		: out std_logic_vector(15 downto 0) := (others => '0'); -- кол-во байт, выдаваемых в SDI
		m_data_sdi			: out std_logic_vector(31 downto 0) := (others => '0'); -- данные для SDI

		--========= avalon slave ===========
		avs_waitrequest  	: out std_logic := '0';
		avs_readdata		: out std_logic_vector(data_width - 1 downto 0);
		avs_readdatavalid 	: out std_logic := '0';
		avs_burstcount    	: in  std_logic := '0';
		avs_writedata		: in  std_logic_vector(data_width - 1 downto 0);
		avs_address			: in  std_logic_vector(address_width - 1 downto 0);
		avs_write			: in  std_logic := '0';
		avs_read			: in  std_logic := '0';
		avs_byteenable    	: in  std_logic_vector((data_width / symbol_width) - 1 downto 0);
		avs_debugaccess   	: in  std_logic := '0'	
	);
end entity math_logic;

architecture math_logic_bhv of math_logic is
	component iq_converter is
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
	
			fc_lowpass 	: in std_logic_vector(3 downto 0) := (others => '0');
			k_decim		: in std_logic_vector(3 downto 0) := (others => '0');
	
			data_in 	: in  std_logic_vector(11 downto 0) := (others => '0');

			work_mode : in std_logic_vector(2 downto 0) := "000";
		
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
	end component iq_converter;

	component math_ram is
		generic(
			data_width 		: natural := 32;
			symbol_width 	: natural := 8;
			address_width	: natural := 9
		);
		port(
			core_clock : in std_logic := '0';
	
			work_mode  : out std_logic_vector( 2 downto 0) := "000";
			num_data   :  in std_logic_vector(31 downto 0) := (others => '0');
			time_work  : out std_logic_vector(31 downto 0) := (others => '0');
			fifo_clear : out std_logic := '0';
	
			fc_lowpass  : out std_logic_vector(3 downto 0) := (others => '0');
			k_decim		: out std_logic_vector(3 downto 0) := (others => '0');
	
			both : out std_logic := '0';

			setup_apply : out std_logic := '0';
			--========= avalon slave ===========
			avs_waitrequest  	: out std_logic := '0';
			avs_readdata		: out std_logic_vector(data_width - 1 downto 0);
			avs_readdatavalid 	: out std_logic := '0';
			avs_burstcount    	: in  std_logic := '0';
			avs_writedata		: in  std_logic_vector(data_width - 1 downto 0);
			avs_address			: in  std_logic_vector(address_width - 1 downto 0);
			avs_write			: in  std_logic := '0';
			avs_read			: in  std_logic := '0';
			avs_byteenable    	: in  std_logic_vector((data_width / symbol_width) - 1 downto 0);
			avs_debugaccess   	: in  std_logic := '0'	
		);
	end component math_ram;

	component fifo128x1024 is
		port(
			aclr 		: in std_logic;
			wrreq		: in  std_logic;
			wrclk		: in  std_logic;
			data		: in  std_logic_vector (127 downto 0);
			
			rdclk		: in  std_logic;
			rdreq		: in  std_logic;
			q			: out std_logic_vector (31 downto 0);

			rdempty		: out std_logic;
			rdusedw		: out std_logic_vector(11 downto 0)
		);
	end component fifo128x1024;


	signal m_reset : std_logic := '0';
	signal fc_lowpass, m_k_decim : std_logic_vector(3 downto 0) := (others => '0');
	--signal s_m_data_sdi : std_logic_vector(31 downto 0) ;

	signal i_fifo_q_chA			:  std_logic_vector (15 downto 0);
	signal i_fifo_rdempty_chA	:  std_logic;

	signal q_fifo_q_chA			:  std_logic_vector (15 downto 0);
	signal q_fifo_rdempty_chA	:  std_logic;

	signal i_fifo_q_chB			:  std_logic_vector (15 downto 0);
	signal i_fifo_rdempty_chB	:  std_logic;

	signal q_fifo_q_chB			:  std_logic_vector (15 downto 0);
	signal q_fifo_rdempty_chB	:  std_logic;

	signal i_fifo_q_chC			:  std_logic_vector (15 downto 0);
	signal i_fifo_rdempty_chC	:  std_logic;

	signal q_fifo_q_chC			:  std_logic_vector (15 downto 0);
	signal q_fifo_rdempty_chC	:  std_logic;

	signal i_fifo_q_chD			:  std_logic_vector (15 downto 0);
	signal i_fifo_rdempty_chD	:  std_logic;

	signal q_fifo_q_chD			:  std_logic_vector (15 downto 0);
	signal q_fifo_rdempty_chD	:  std_logic;


	signal  iq_conv_data_valid, iq_conv_data_valid_1, iq_conv_data_valid_2 	: std_logic := '0';
	signal 	iq_rdreq_1, iq_rdreq_2, iq_rdreq_3, iq_rdreq_4 : std_logic := '0';



	signal work_mode : std_logic_vector(2 downto 0);
	signal setup_apply : std_logic;


	signal adc_valid_z : std_logic_vector(1 downto 0) := "00";

	signal step : integer range 0 to 15 := 0;

	signal ram_num_data : std_logic_vector(31 downto 0) ;

	signal iq_conv_cnt_data, iq_conv_cnt_data_1, iq_conv_cnt_data_2 : std_logic_vector(15 downto 0) ;

	signal both : std_logic := '0';

	signal fifo_clear : std_logic := '0';

begin

	process (update_strb, core_clock) begin
		if update_strb = '1' then
			step 	<= 0;
			m_reset <= '1';
			iq_rdreq_1 <= '0';
			iq_rdreq_2 <= '0';
			iq_rdreq_3 <= '0';
			iq_rdreq_4 <= '0';
			m_data_completed 	<= '0';
			m_data_is_empty		<= '0';
			m_data_is_over		<= '0';
			m_data_ready		<= '0';
			m_data_sdi_valid	<= '0';
			fifo_clear <= '1';

		elsif rising_edge(core_clock) then
			fifo_clear <= '0';

			if setup_apply = '1' then -- для смены настроек фильтров
				m_reset <= '1';
			else
				m_reset <= '0';
			end if;

			case (step) is
				when 0 => -- ожидаем начала сбора данных
					if adc_valid_in = '1' then
						step <= 1;
					end if;

				when 1 => -- ожидаем окончания сбора данных
					if adc_valid_in = '0' then
						if both = '0' then -- собирать данные с ЦСА тоже
							step <= 3;
							m_data_count <= std_logic_vector(resize(unsigned(iq_conv_cnt_data_2 & "00" ), 16));
							ram_num_data <= std_logic_vector(resize(unsigned(iq_conv_cnt_data_2), 32));
						else -- не собирать данные с ЦСА
							step <= 5; 
							m_data_count <= std_logic_vector(resize(unsigned(iq_conv_cnt_data_1 & "00" ), 16));
							ram_num_data <= std_logic_vector(resize(unsigned(iq_conv_cnt_data_1), 32));
						end if;
					end if;
				
				when 3 => 
					if sdi_ready = '1' then -- (2) принимаем сигнал готовности SDI
						if i_fifo_rdempty_chD = '1' then -- (4) если в этом FIFO пусто, значит и в других тоже пусто, ...
							step <= 7;
							iq_rdreq_1 <= '0';
							iq_rdreq_2 <= '0';
							iq_rdreq_3 <= '0';
							iq_rdreq_4 <= '0';
							m_data_sdi_valid <= '0'; -- (4) ... значит заканчиваем выгрузку данных
						else
							m_data_sdi		 <= i_fifo_q_chD & q_fifo_q_chD; -- (3) передача начинается с 4-го канала 
							step 			 <= 4;
							m_data_sdi_valid <= '1'; -- (3) сигнал записи в SDI
							iq_rdreq_1 <= '0'; -- (3) стробы чтения из FIFO ЦОС
							iq_rdreq_2 <= '0'; --
							iq_rdreq_3 <= '0'; --
							iq_rdreq_4 <= '1'; --
						end if;
					else
						m_data_ready <= '1'; -- (1) выдаем сигнал готовности данных в ЦОС
					end if;
				
				when 4 =>
					m_data_sdi		 <= i_fifo_q_chC & q_fifo_q_chC;
					step <= 5;
					iq_rdreq_1 <= '0';
					iq_rdreq_2 <= '0';
					iq_rdreq_3 <= '1';
					iq_rdreq_4 <= '0';

				when 5 =>
					if sdi_ready = '1' then -- (2) принимаем сигнал готовности SDI
						if i_fifo_rdempty_chB = '1' then -- (4) если в этом FIFO пусто, значит и в других тоже пусто, ...
							step <= 7;
							iq_rdreq_1 <= '0';
							iq_rdreq_2 <= '0';
							iq_rdreq_3 <= '0';
							iq_rdreq_4 <= '0';
							m_data_sdi_valid <= '0'; -- (4) ... значит заканчиваем выгрузку данных
						else
							m_data_sdi		 <= i_fifo_q_chB & q_fifo_q_chB; -- (3) передача начинается со 2-го канала 
							step 			 <= 6;
							m_data_sdi_valid <= '1'; -- (3) сигнал записи в SDI
							iq_rdreq_1 <= '0'; -- (3) стробы чтения из FIFO ЦОС
							iq_rdreq_2 <= '1'; --
							iq_rdreq_3 <= '0'; --
							iq_rdreq_4 <= '0'; --
						end if;
					else
						m_data_ready <= '1'; -- (1) выдаем сигнал готовности данных в ЦОС
					end if;

				when 6 =>
					m_data_sdi		 <= i_fifo_q_chA & q_fifo_q_chA;
					if both = '1' then
						step <= 5;
					else
						step <= 3;
					end if;
					iq_rdreq_1 <= '1';
					iq_rdreq_2 <= '0';
					iq_rdreq_3 <= '0';
					iq_rdreq_4 <= '0';

				when 7 =>
					m_data_completed 	<= '1';
					m_data_ready 		<= '0';
					step <= 8;

				when 8 =>
					if sdi_ready = '0' then -- дожидаемся пока SDI закончит передавать данные в последовательный порт
						step <= 0;
						m_data_completed <= '0';
					end if;	

				when others => step <= 0;


			end case;
		end if;
	end process;




	iq_conv_for_data_a : iq_converter
		generic map(
			w_s1  	=> 10 - 5,
			w_a1_0	=> 10,
			w_a1_1	=> 10,
			w_s2  	=> 10 - 5,
			w_a2_0	=> 10,
			w_a2_1	=> 10,
			w_s3  	=> 10 - 5,
			w_a3_0	=> 10,
			w_a3_1	=> 10,
			w_s4	=> 10 + 15,

			number => x"0"
		)
		port map(
			adc_fco 	=> adc_fco,
			reset 		=> m_reset,
			adc_valid	=> adc_valid_in,
	
			fc_lowpass 	=> fc_lowpass,
			k_decim		=> m_k_decim,
	
			data_in 	=> adc_data_in_a,
			work_mode   => work_mode,
			
			i_fifo_rdclk		=> core_clock,
			i_fifo_rdreq		=> iq_rdreq_1,
			i_fifo_q			=> i_fifo_q_chA,
			i_fifo_rdempty		=> i_fifo_rdempty_chA,

			iq_conv_cnt_data => iq_conv_cnt_data_1,
			fifo_clear => fifo_clear,
	
			q_fifo_rdclk		=> core_clock,
			q_fifo_rdreq		=> iq_rdreq_1,
			q_fifo_q			=> q_fifo_q_chA,
			q_fifo_rdempty		=> q_fifo_rdempty_chA
		);
	iq_conv_for_data_b : iq_converter
		generic map(
			w_s1  	=> 10 - 5,
			w_a1_0	=> 10,
			w_a1_1	=> 10,
			w_s2  	=> 10 - 5,
			w_a2_0	=> 10,
			w_a2_1	=> 10,
			w_s3  	=> 10 - 5,
			w_a3_0	=> 10,
			w_a3_1	=> 10,
			w_s4	=> 10 + 15,

			number => x"1"
		)
		port map(
			adc_fco => adc_fco,
			reset 	=> m_reset,
			adc_valid	=> adc_valid_in,
	
			fc_lowpass 	=> fc_lowpass,
			k_decim		=> m_k_decim,
	
			data_in 	=> adc_data_in_b,
			work_mode   => work_mode,
			
			i_fifo_rdclk		=> core_clock,
			i_fifo_rdreq		=> iq_rdreq_2,
			i_fifo_q			=> i_fifo_q_chB,
			i_fifo_rdempty		=> i_fifo_rdempty_chB,

			iq_conv_cnt_data => open,
			fifo_clear => fifo_clear,
	
			q_fifo_rdclk		=> core_clock,
			q_fifo_rdreq		=> iq_rdreq_2,
			q_fifo_q			=> q_fifo_q_chB,
			q_fifo_rdempty		=> q_fifo_rdempty_chB
		);
	iq_conv_for_alt_data_a : iq_converter
		generic map(
			w_s1  	=> 10 - 5,
			w_a1_0	=> 10,
			w_a1_1	=> 10,
			w_s2  	=> 10 - 5,
			w_a2_0	=> 10,
			w_a2_1	=> 10,
			w_s3  	=> 10 - 5,
			w_a3_0	=> 10,
			w_a3_1	=> 10,
			w_s4	=> 10 + 15,

			number => x"2"
		)
		port map(
			adc_fco => alt_adc_fco,
			reset 	=> m_reset,
			adc_valid	=> adc_valid_in,
	
			fc_lowpass 	=> fc_lowpass,
			k_decim		=> m_k_decim,
	
			data_in 	=> alt_adc_data_in_a,
			work_mode   => work_mode,
			
			i_fifo_rdclk		=> core_clock,
			i_fifo_rdreq		=> iq_rdreq_3,
			i_fifo_q			=> i_fifo_q_chC,
			i_fifo_rdempty		=> i_fifo_rdempty_chC,

			iq_conv_cnt_data => iq_conv_cnt_data_2,
			fifo_clear => fifo_clear,
	
			q_fifo_rdclk		=> core_clock,
			q_fifo_rdreq		=> iq_rdreq_3,
			q_fifo_q			=> q_fifo_q_chC,
			q_fifo_rdempty		=> q_fifo_rdempty_chC 
		);
	iq_conv_for_alt_data_b : iq_converter
		generic map(
			w_s1  	=> 10 - 5,
			w_a1_0	=> 10,
			w_a1_1	=> 10,
			w_s2  	=> 10 - 5,
			w_a2_0	=> 10,
			w_a2_1	=> 10,
			w_s3  	=> 10 - 5,
			w_a3_0	=> 10,
			w_a3_1	=> 10,
			w_s4	=> 10 + 15,

			number => x"3"
		)
		port map(
			adc_fco => alt_adc_fco,
			reset 	=> m_reset,
			adc_valid	=> adc_valid_in,
	
			fc_lowpass 	=> fc_lowpass,
			k_decim		=> m_k_decim,
	
			data_in 	=> alt_adc_data_in_b,
			work_mode   => work_mode,
			
			i_fifo_rdclk		=> core_clock,
			i_fifo_rdreq		=> iq_rdreq_4,
			i_fifo_q			=> i_fifo_q_chD,
			i_fifo_rdempty		=> i_fifo_rdempty_chD,

			iq_conv_cnt_data => open,
			fifo_clear => fifo_clear,
	
			q_fifo_rdclk		=> core_clock,
			q_fifo_rdreq		=> iq_rdreq_4,
			q_fifo_q			=> q_fifo_q_chD,
			q_fifo_rdempty		=> q_fifo_rdempty_chD
		);
 
	math_ram_unit : math_ram
		generic map(
			data_width 		=> data_width,
			symbol_width 	=> symbol_width,
			address_width	=> address_width
		)
		port map(
			core_clock => core_clock,
	
			work_mode  => work_mode,
			num_data   => ram_num_data,
			time_work  => open, 				-- использовалось в пассивном канале
			fifo_clear => open,
	
			fc_lowpass  => fc_lowpass,
			k_decim		=> m_k_decim,
	
			both => both,

			setup_apply => setup_apply,
			--========= avalon slave ===========
			avs_waitrequest  	=> avs_waitrequest,
			avs_readdata		=> avs_readdata,
			avs_readdatavalid 	=> avs_readdatavalid,
			avs_burstcount    	=> avs_burstcount,
			avs_writedata		=> avs_writedata,
			avs_address			=> avs_address,
			avs_write			=> avs_write,
			avs_read			=> avs_read,
			avs_byteenable    	=> avs_byteenable,
			avs_debugaccess   	=> avs_debugaccess
		);

end architecture math_logic_bhv;