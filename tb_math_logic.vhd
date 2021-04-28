library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

use std.textio.all;


library work;
use work.common_package.all;

entity tb_math_logic is
end entity;

architecture bhv of tb_math_logic is
	
	component math_logic is
		generic(
			data_width 		: natural := 32;
			symbol_width 	: natural := 8;
			address_width	: natural := 9
		);
		port(
			lane_clock : in std_logic := '0';
			core_clock : in std_logic := '0';
	
			adc_fco 	: in std_logic := '0';
			alt_adc_fco : in std_logic := '0';
	
			adc_data_in_a 		: in std_logic_vector(11 downto 0) := (others => '0');
			adc_data_in_b 		: in std_logic_vector(11 downto 0) := (others => '0');
			
			alt_adc_data_in_a 	: in std_logic_vector(11 downto 0) := (others => '0');
			alt_adc_data_in_b 	: in std_logic_vector(11 downto 0) := (others => '0');
	
			adc_valid_in		: in std_logic := '0'; -- acquire_strob from ctr

			sdi_ready : in std_logic := '0';
			update_strb : in std_logic := '0';
	
			acq_data_count_in : in std_logic_vector(15 downto 0) := (others => '0');
	
			m_data_completed 	: out std_logic := '0';
			m_data_is_empty		: out std_logic := '0';
			m_data_is_over		: out std_logic := '0';
			m_data_ready		: out std_logic := '0';
			m_data_sdi_valid	: out std_logic := '0';
	
			acq_data_count_out	: out std_logic_vector(15 downto 0) := (others => '0');
			m_data_count		: out std_logic_vector(15 downto 0) := (others => '0');
			m_data_sdi			: out std_logic_vector(31 downto 0) := (others => '0');
	
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
	end component math_logic;

	component sdi_logic is
		generic(
			data_width 		: natural := 32;
			symbol_width 	: natural := 8;
			address_width	: natural := 3
		);
		port(
			core_clk : in std_logic := '0';
			reset	 : in std_logic := '0';
	
			sdi_clk		: in  std_logic := '0';
			sdi_ena		: out std_logic := '0';
			sdi_rate	: out std_logic := '0';
			sdi_serial	: out std_logic := '0';
	
			strob_update : in std_logic := '0';
	
			m_data_wren 		: in  std_logic := '0';
			m_data				: in  std_logic_vector(31 downto 0) := (others => '0');
			m_sdi_ready 		: out std_logic := '0';
			m_data_ready		: in  std_logic := '0';							
			m_data_completed	: in  std_logic := '0';							
			m_data_is_over		: in  std_logic := '0';							
			m_data_is_empty		: in  std_logic := '0';
	
			imp_count		: in std_logic_vector(15 downto 0) := (others => '0');	
			acq_data_count	: in std_logic_vector(15 downto 0) := (others => '0');		
			math_data_count	: in std_logic_vector(15 downto 0) := (others => '0');
	
			system_timer : in  std_logic_vector(31 downto 0) := (others => '0');
	
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
	end component;


	signal t_m_sh_i_out:  std_logic_vector(15 downto 0) ;
	signal t_m_sh_q_out:  std_logic_vector(15 downto 0) ;
	-----------------------------------------------------------------------------------



	signal lane_clock : std_logic := '0';
	signal core_clock : std_logic := '0';
	
	signal adc_fco 		:  std_logic := '0';
	signal alt_adc_fco 	:  std_logic := '0';

	signal adc_data_in_a 		:  std_logic_vector(11 downto 0) := "011111111111";
	signal adc_data_in_b 		:  std_logic_vector(11 downto 0) := "011111111111";
	
	signal alt_adc_data_in_a 	:  std_logic_vector(11 downto 0) := "011111111111";
	signal alt_adc_data_in_b 	:  std_logic_vector(11 downto 0) := "011111111111";
	
	signal adc_valid_in		:  std_logic := '0';

	signal sdi_ready :  std_logic := '0';
	signal update_strb :  std_logic := '0';

	signal acq_data_count_in :  std_logic_vector(15 downto 0) := (others => '0');

	signal m_data_completed 	:  std_logic := '0';
	signal m_data_is_empty		:  std_logic := '0';
	signal m_data_is_over		:  std_logic := '0';
	signal m_data_ready			:  std_logic := '0';
	signal m_data_sdi_valid		:  std_logic := '0';

	signal acq_data_count_out	:  std_logic_vector(15 downto 0) := (others => '0');
	signal m_data_count			:  std_logic_vector(15 downto 0) := (others => '0');
	signal m_data_sdi			:  std_logic_vector(31 downto 0) := (others => '0');

	--========= avalon slave ===========
	signal avs_waitrequest  	:  std_logic := '0';
	signal avs_readdata			:  std_logic_vector(32 - 1 downto 0);
	signal avs_readdatavalid 	:  std_logic := '0';
	signal avs_burstcount    	:  std_logic := '0';
	signal avs_writedata		:  std_logic_vector(32 - 1 downto 0);
	signal avs_address			:  std_logic_vector(3 - 1 downto 0);
	signal avs_write			:  std_logic := '0';
	signal avs_read				:  std_logic := '0';
	signal avs_byteenable    	:  std_logic_vector((32 / 8) - 1 downto 0);
	signal avs_debugaccess   	:  std_logic := '0';


	signal test : integer := 0;



	signal sdi_sdi_clk		:  std_logic := '0';
	signal sdi_sdi_ena		:  std_logic := '0';
	signal sdi_sdi_rate		:  std_logic := '0';
	signal sdi_sdi_serial	:  std_logic := '0';

	

	signal sdi_m_data_wren 		:   std_logic := '0';
	signal sdi_m_data			:   std_logic_vector(31 downto 0) := (others => '0');
	signal sdi_m_sdi_ready 		:  std_logic := '0';
	signal sdi_m_data_ready		:   std_logic := '0';							
	signal sdi_m_data_completed	:   std_logic := '0';							
	signal sdi_m_data_is_over	:   std_logic := '0';							
	signal sdi_m_data_is_empty	:   std_logic := '0';

	signal sdi_imp_count		:  std_logic_vector(15 downto 0) := (others => '0');	
	signal sdi_acq_data_count	:  std_logic_vector(15 downto 0) := (others => '0');		
	signal sdi_math_data_count	:  std_logic_vector(15 downto 0) := (others => '0');

	signal sdi_system_timer :   std_logic_vector(31 downto 0) := (others => '0');

	--========= avalon slave ===========
	signal sdi_avs_waitrequest  	:  std_logic := '0';
	signal sdi_avs_readdata			:  std_logic_vector(32 - 1 downto 0);
	signal sdi_avs_readdatavalid 	:  std_logic := '0';
	signal sdi_avs_burstcount    	:   std_logic := '0';
	signal sdi_avs_writedata		:   std_logic_vector(32 - 1 downto 0);
	signal sdi_avs_address			:   std_logic_vector(3 - 1 downto 0);
	signal sdi_avs_write			:   std_logic := '0';
	signal sdi_avs_read				:   std_logic := '0';
	signal sdi_avs_byteenable    	:   std_logic_vector((32 / 8) - 1 downto 0);
	signal sdi_avs_debugaccess   	:   std_logic := '0';


	procedure avm_write(
		signal 	clock 		: in std_logic;
		 		address		: in std_logic_vector(2 downto 0);
		 		data		: in std_logic_vector(31 downto 0);
		signal 	avs_address		: out std_logic_vector(2 downto 0);
		signal 	avs_writedata	: out std_logic_vector(31 downto 0);
		signal 	avs_write		: out std_logic
	) is begin
		wait until rising_edge(clock);
		avs_address <= address;
		avs_writedata <= data;
		avs_write <= '1';
		wait until rising_edge(clock);
		avs_write <= '0';
		wait until rising_edge(clock);
	end procedure avm_write;


begin

	GEN_LANE_CLK : process begin
		lane_clock <= '0';
		wait for 10 ps;
		lane_clock <= '1';
		wait for 10 ps;
	end process GEN_LANE_CLK;

	GEN_CORE_CLK : process begin
		core_clock <= '0';
		sdi_sdi_clk	   <= '0';
		wait for 10 ps;
		core_clock <= '1';
		sdi_sdi_clk	   <= '1';
		wait for 10 ps;
	end process GEN_CORE_CLK;

	GEN_FCO_CLK : process begin
		adc_fco <= '0';
		--alt_adc_fco <= '0';
		wait for 30 ps;
		adc_fco <= '1';
		--alt_adc_fco <= '1';
		wait for 30 ps;
	end process GEN_FCO_CLK;

	
	IQ_CONV_READ_FILE : process (adc_fco) is
		file F : TEXT open READ_MODE is "Z:/230_sch_sector/FIRMWARE/cu_75/cu75_warprj_03/vhdl/math/sin_500kHz.txt";
		variable f_line : line;
		variable bool : boolean;
		variable var : integer;
		variable data_cnt : integer := 0;
	begin
		if rising_edge(adc_fco) then
			-- ПОДАДИМ НА ВХОД ПРЕОБРАЗОВАТЕЛЯ МАССИВ ШУМОВЫХ ОТСЧЕТОВ			
			if adc_valid_in = '1' then
				if endfile(F) then
					report "end of file";
					FILE_CLOSE(F);
				else
					READLINE(F, f_line);
					READ(f_line, var);
	
					adc_data_in_a <= std_logic_vector(resize(to_signed(var, 12), 12));
					adc_data_in_b <= adc_data_in_a; --std_logic_vector(resize(to_signed(var, 12), 12));
	
					alt_adc_data_in_a <= (others => '0');--std_logic_vector(resize(to_signed(var, 12), 12));
					alt_adc_data_in_b <= (others => '0');--std_logic_vector(resize(to_signed(var, 12), 12));

					data_cnt := data_cnt + 1;
				end if;
			end if;
			-- ПРОВЕРКА СООТВЕТСТВИЯ КОЛИЧЕСТВА ЗАПИСАННЫХ И СЧИТАННЫХ ДАННЫХ
				-- надо реализовать
		end if;
	end process IQ_CONV_READ_FILE;




	IQ_CONV_WRITE_FILE : process (core_clock) is
		file F_I : TEXT open WRITE_MODE is "Z:/230_sch_sector/FIRMWARE/cu_75/cu75_warprj_03/vhdl/math/i_out.txt";
		file F_Q : TEXT open WRITE_MODE is "Z:/230_sch_sector/FIRMWARE/cu_75/cu75_warprj_03/vhdl/math/q_out.txt";
		variable fi_line : line;
		variable fq_line : line;

	begin
		if rising_edge(core_clock) then
			--ЗАПИШЕМ В ФАЙЛ ДАННЫЕ, КОТОРЫЕ ИДУТ НА SDI
			if m_data_sdi_valid = '1' then
				write(fi_line, sint(m_data_sdi(31 downto 16)));
				write(fq_line, sint(m_data_sdi(15 downto 0)));

				writeline(F_I, fi_line);
				writeline(F_Q, fq_line);

			end if;
		end if;
	end process IQ_CONV_WRITE_FILE;


	MAIN : process begin
		wait for 100 ps;
		avm_write(lane_clock, "000", x"00008003", avs_address, avs_writedata, avs_write);
		avm_write(lane_clock, "011", x"80000000", avs_address, avs_writedata, avs_write);
		avm_write(core_clock, "000", x"00000002", sdi_avs_address, sdi_avs_writedata, sdi_avs_write);

		wait for 3000 ps;
		wait until rising_edge(adc_fco);
		update_strb <= '1';
		wait until rising_edge(adc_fco);
		update_strb <= '0';

		wait for 1000 ps;

		wait until rising_edge(adc_fco);
		adc_valid_in <= '1';
		wait for 5000 ps;
		wait for 5000 ps;
		wait for 10000 ps;
		adc_valid_in <= '0';

		wait;
	end process MAIN;

	math_unit : math_logic
	generic map(
		data_width 		=> 32,
		symbol_width 	=> 8,
		address_width	=> 3
	)
	port map(
		lane_clock => lane_clock,
		core_clock => core_clock,

		adc_fco 	=> adc_fco,
		alt_adc_fco => alt_adc_fco,

		adc_data_in_a 		=> adc_data_in_a,
		adc_data_in_b 		=> adc_data_in_b,
		
		alt_adc_data_in_a 	=> alt_adc_data_in_a,
		alt_adc_data_in_b 	=> alt_adc_data_in_b,

		adc_valid_in		=> adc_valid_in,

		sdi_ready => sdi_ready,
		update_strb => update_strb,

		acq_data_count_in => acq_data_count_in,

		m_data_completed 	=> m_data_completed,
		m_data_is_empty		=> m_data_is_empty,
		m_data_is_over		=> m_data_is_over,
		m_data_ready		=> m_data_ready,
		m_data_sdi_valid	=> m_data_sdi_valid,

		acq_data_count_out	=> acq_data_count_out,
		m_data_count		=> m_data_count,
		m_data_sdi			=> m_data_sdi,

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

	sdi_unit : sdi_logic
			generic map(
				data_width 		=> 32,
				symbol_width 	=> 8,
				address_width	=> 3
			)
			port map(
				core_clk => core_clock,
				reset	 => '0',
		
				sdi_clk		=> sdi_sdi_clk,
				sdi_ena		=> open,
				sdi_rate	=> open,
				sdi_serial	=> sdi_sdi_serial,
		
				strob_update => update_strb,
		
				m_data_wren 		=> m_data_sdi_valid,
				m_data				=> m_data_sdi,
				m_sdi_ready 		=> sdi_ready,
				m_data_ready		=> m_data_ready,
				m_data_completed	=> m_data_completed,
				m_data_is_over		=> m_data_is_over,
				m_data_is_empty		=> m_data_is_empty,
		
				imp_count		=> (others => '0'),
				acq_data_count	=> acq_data_count_out,
				math_data_count	=> m_data_count,
		
				system_timer => (others => '0'),
		
				--========= avalon slave ===========
				avs_waitrequest  	=> sdi_avs_waitrequest,
				avs_readdata		=> sdi_avs_readdata,
				avs_readdatavalid 	=> sdi_avs_readdatavalid,
				avs_burstcount    	=> sdi_avs_burstcount,
				avs_writedata		=> sdi_avs_writedata,
				avs_address			=> sdi_avs_address,
				avs_write			=> sdi_avs_write,
				avs_read			=> sdi_avs_read,
				avs_byteenable    	=> sdi_avs_byteenable,
				avs_debugaccess   	=> sdi_avs_debugaccess
			);
end architecture bhv;