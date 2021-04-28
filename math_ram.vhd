library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.numeric_std.all;

library work;
use work.common_package.all;

entity math_ram is
	generic(
		data_width 		: natural := 32;
		symbol_width 	: natural := 8;
		address_width	: natural := 9
	);
	port(
		core_clock : in std_logic := '0';

		work_mode : out std_logic_vector( 2 downto 0) := "000";
		num_data  :  in std_logic_vector(31 downto 0) := (others => '0');
		time_work : out std_logic_vector(31 downto 0) := (others => '0');

		fc_lowpass  : out std_logic_vector(3 downto 0) := (others => '0');
		k_decim		: out std_logic_vector(3 downto 0) := (others => '0');

		fifo_clear : out std_logic := '0';

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
end entity math_ram;

architecture math_ram_bhv of math_ram is
	signal reg_control : std_logic_vector(31 downto 0) := x"00000004"; 		--   [31] - fifo_clear. Очистка выходного буффера математики
																			-- [2..0] - work_mode.
																			--				"000" - математика не используется. данные для SDI не формируются
																			--				"001" - данные со входа преобразователя
																			--				"010" - данные с выхода гетеродина
																			--				"011" - данные с выхода ФНЧ
																			--				"100" - данные с выхода дециматора. штатный режим работы
																			--   [15] - собрать данные и с ЦСА тоже? 0 - собирать, 1 - не собирать

	signal reg_num_data   : std_logic_vector(31 downto 0) := (others => '0'); -- [31..0] - количество слов, в выходном буффере математики
	signal reg_time_work  : std_logic_vector(31 downto 0) := (others => '0'); -- [31..0] - зарезервировано
	
	signal reg_math_setup : std_logic_vector(31 downto 0) := x"80000008"; -- [3..0] - выбор частоты среза ФНЧ
																			  -- 				"0000" -   1 MHz
																			  --				"0001" - 1.5 MHz
																			  --				"0010" -   2 MHz
																			  --				"0011" - 2.5 MHz
																			  --				"0100" -   3 MHz
																			  --				"0101" - 3.5 MHz
																			  --				"0110" -   4 MHz
																			  --				"0111" - 4.5 MHz
																			  --				"1000" -   5 MHz
																			  -- [7..4] - коэффициент децимации
																			  --				при "0000" и "0001" коэффициент децимации равен 1
																			  --   [31] - применить настройки математики (очищается автоматически)


	signal m_mem_locked : std_logic := '0';

	signal avs_addr_int 	: integer range 0 to 15 := 0;
	signal avs_write_count 	: integer range 0 to 15 := 15;

	signal s_setup_apply : std_logic := '0';

	signal setup_cnt 	: integer range 0 to 15 := 15;
	
begin

	avs_addr_int 	<= to_integer(unsigned(avs_address(address_width - 1 downto 0)));
	avs_waitrequest <= '0';

	process (core_clock) begin
		if rising_edge(core_clock) then

			--reg_num_data <= (others => '0');
			reg_num_data <= std_logic_vector(resize(unsigned(num_data(31 downto 2)), 32));
			setup_apply <= s_setup_apply;

			case avs_addr_int is
				when 0 =>
					if avs_read = '1' and avs_write = '0' then
						avs_readdatavalid <= '1';
						avs_readdata <= reg_control;
					elsif avs_read = '0' and avs_write = '1' then
						reg_control <= avs_writedata;
					else
						avs_readdatavalid <= '0';
					end if;

				when 1 =>
					if avs_read = '1' and avs_write = '0' then
						avs_readdatavalid <= '1';
						avs_readdata <= reg_num_data;
					elsif avs_read = '0' and avs_write = '1' then
						null;
					else
						avs_readdatavalid <= '0';
					end if;

				when 2 =>
					if avs_read = '1' and avs_write = '0' then
						avs_readdatavalid <= '1';
						avs_readdata <= reg_time_work;
					elsif avs_read = '0' and avs_write = '1' then
						null;
					else
						avs_readdatavalid <= '0';
					end if;

				when 3 =>
					if avs_read = '1' and avs_write = '0' then
						avs_readdatavalid <= '1';
						avs_readdata <= reg_math_setup;
					elsif avs_read = '0' and avs_write = '1' then
						reg_math_setup <= avs_writedata;
					else
						avs_readdatavalid <= '0';
					end if;
				
				when others =>
					if avs_read = '1' and avs_write = '0' then
						avs_readdatavalid <= '1';
						avs_readdata <= x"DEADBABA";
					elsif avs_read = '0' and avs_write = '1' then
						null;
					else
						avs_readdatavalid <= '0';
					end if;
			end case;

			if avs_write = '1' then
				avs_write_count <= 15;
				m_mem_locked  <= '1';
			else
				if avs_write_count = 0 then
					if m_mem_locked = '1' then
						m_mem_locked <= '0';

						fifo_clear <= reg_control(31);
						both		  <= reg_control(15);
						work_mode <= reg_control(2 downto 0);

						time_work <= reg_time_work;

						fc_lowpass  <= reg_math_setup(3 downto 0);
						k_decim		<= reg_math_setup(7 downto 4);
						s_setup_apply <= reg_math_setup(31);
						
					else
						if s_setup_apply = '1' then
							if setup_cnt = 0 then
								s_setup_apply <= '0';
								setup_cnt <= 15;
								reg_math_setup(31) <= '0';
							else
								setup_cnt <= setup_cnt - 1;
							end if;
						end if;
					end if;
				else
					avs_write_count <= avs_write_count - 1;
				end if;
			end if;

			
		end if;
	end process;

end architecture math_ram_bhv;