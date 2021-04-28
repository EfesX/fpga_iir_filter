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
			w_s4	: natural := 8
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


	signal iq_conv_data_valid, iq_conv_data_valid_1, iq_conv_data_valid_2 	: std_logic := '0';
	signal iq_conv_rdreq		: std_logic := '0';

	signal fifo_out_wrreq : std_logic := '0';
	signal fifo_out_data  : std_logic_vector(127 downto 0) := (others => '0');

	signal fifo_out_rdusedw : std_logic_vector(11 downto 0);

	signal fifo_out_rdreq	: std_logic := '0';
	signal fifo_out_q		: std_logic_vector(31 downto 0);
	signal fifo_out_rdempty	: std_logic := '0';


	signal work_mode : std_logic_vector(2 downto 0);
	signal setup_apply : std_logic;


	signal adc_valid_z : std_logic_vector(1 downto 0) := "00";

	signal step : integer range 0 to 15 := 0;

	signal ram_num_data : std_logic_vector(31 downto 0) ;
	signal lock : std_logic := '0';

	signal fifo_out_aclr : std_logic := '0';

begin

	ram_num_data <= std_logic_vector(resize(unsigned(fifo_out_rdusedw & "00" ), 32));


	iq_conv_data_valid_1 <= not (		i_fifo_rdempty_chA  and --ожидаем готовности буфферов в каждом IQ конвертере. поскольку считывание ведется на частоте в несколько раз большей
	q_fifo_rdempty_chA  and -- чем частота записи, переполнения буфферов не должно быть
	i_fifo_rdempty_chB  and
	q_fifo_rdempty_chB
);
iq_conv_data_valid_2 <= not (		i_fifo_rdempty_chC  and --ожидаем готовности буфферов в каждом IQ конвертере. поскольку считывание ведется на частоте в несколько раз большей
	q_fifo_rdempty_chC  and -- чем частота записи, переполнения буфферов не должно быть
	i_fifo_rdempty_chD  and
	q_fifo_rdempty_chD
);


	

	FIFO_OUT_WRITE : process (core_clock) begin
		if rising_edge(core_clock) then


			iq_conv_data_valid <= iq_conv_data_valid_1 or iq_conv_data_valid_2;

			if lock = '0' then -- lock нужен чтобы не производить запись дважды (костыль?)
				if iq_conv_data_valid = '1' then
					fifo_out_data <= 	i_fifo_q_chA & q_fifo_q_chA &			-- формируем слово для записи в выходной буффер
										i_fifo_q_chB & q_fifo_q_chB &
										i_fifo_q_chC & q_fifo_q_chC &
										i_fifo_q_chD & q_fifo_q_chD;
					lock <= '1';
					fifo_out_wrreq <= '1';
					iq_conv_rdreq  <= '1';
				end if;
			else
				fifo_out_wrreq <= '0';
				if iq_conv_data_valid = '0' then
					lock <= '0';
					iq_conv_rdreq  <= '0';
				end if;
			end if;

			if setup_apply = '1' then -- для смены настроек фильтров
				m_reset <= '1';
			else
				m_reset <= '0';
			end if;

		end if;
	end process FIFO_OUT_WRITE;


	FIFO_OUT_READ : process (core_clock) is
		variable cnt : integer range 0 to 7 := 7;	 -- для задержки сигнала sdi_ready, потому, что fifo почему-то запаздывает
	begin
		if rising_edge(core_clock) then
			adc_valid_z(0) <= adc_valid_in;
			adc_valid_z(1) <= adc_valid_z(0);

			m_data_count <= std_logic_vector(resize(unsigned(fifo_out_rdusedw & "00" ), 16));

			case (step) is
				when 0 =>
					if adc_valid_z = "10" then 																-- отлавливаем окончание сбора данных
						--m_data_count <= std_logic_vector(resize(unsigned(fifo_out_rdusedw & "00" ), 16));		-- к-во данных для SDI = кол-во данных в выходном буффере
						step <= 1;
					end if;
					

				when 1 =>
					
					if cnt = 0 then
						if sdi_ready = '1' then
							step <= 2;
							cnt := 7;
						end if;

						if fifo_out_rdempty = '1' then
							m_data_is_empty <= '0';
							step <= 0;
						else
							m_data_ready <= '1';
						end if;
					else
						cnt := cnt - 1;
					end if;

					

				when 2 =>
					if fifo_out_rdempty = '1' then
						m_data_completed 	<= '1';
						m_data_sdi_valid 	<= '0';
						fifo_out_rdreq 		<= '0';
						step 				<=   3;
						m_data_ready		<= '0';
					else
						m_data_sdi_valid <= '1';
						m_data_sdi		 <= fifo_out_q;
						fifo_out_rdreq   <= '1';
					end if;

				when 3 =>
					if sdi_ready = '0' then
						step <= 0;
						m_data_completed <= '0';
					end if;
					
				
			
				when others => null;
			end case ;

		end if;
	end process FIFO_OUT_READ;



	fifo_out_unit : fifo128x1024
		port map(
			aclr		=> fifo_out_aclr,
			wrreq		=> fifo_out_wrreq,
			wrclk		=> core_clock,
			data		=> fifo_out_data,
			
			rdclk		=> core_clock,
			rdreq		=> fifo_out_rdreq,
			q			=> fifo_out_q,

			rdempty		=> fifo_out_rdempty,
			rdusedw		=> fifo_out_rdusedw
		);


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
			w_s4	=> 10 + 15
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
			i_fifo_rdreq		=> iq_conv_rdreq,
			i_fifo_q			=> i_fifo_q_chA,
			i_fifo_rdempty		=> i_fifo_rdempty_chA,
	
			q_fifo_rdclk		=> core_clock,
			q_fifo_rdreq		=> iq_conv_rdreq,
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
			w_s4	=> 10 + 15
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
			i_fifo_rdreq		=> iq_conv_rdreq,
			i_fifo_q			=> i_fifo_q_chB,
			i_fifo_rdempty		=> i_fifo_rdempty_chB,
	
			q_fifo_rdclk		=> core_clock,
			q_fifo_rdreq		=> iq_conv_rdreq,
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
			w_s4	=> 10 + 15
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
			i_fifo_rdreq		=> iq_conv_rdreq,
			i_fifo_q			=> i_fifo_q_chC,
			i_fifo_rdempty		=> i_fifo_rdempty_chC,
	
			q_fifo_rdclk		=> core_clock,
			q_fifo_rdreq		=> iq_conv_rdreq,
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
			w_s4	=> 10 + 15
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
			i_fifo_rdreq		=> iq_conv_rdreq,
			i_fifo_q			=> i_fifo_q_chD,
			i_fifo_rdempty		=> i_fifo_rdempty_chD,
	
			q_fifo_rdclk		=> core_clock,
			q_fifo_rdreq		=> iq_conv_rdreq,
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
			fifo_clear => fifo_out_aclr,
	
			fc_lowpass  => fc_lowpass,
			k_decim		=> m_k_decim,
	
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