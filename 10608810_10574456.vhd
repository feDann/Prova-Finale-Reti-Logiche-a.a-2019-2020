--##########################################
--Prova finale di Reti Logiche
--Ferrazzo Daniele - matr. 892478
--Figini Andrea - matr. 890831
--Anno accademico 2019/2020
--##########################################
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;

package COSTANTI is
  constant NUM_WZ : natural := 8;
  constant DIM_WZ : natural := 4;
  constant ADDRESS :  std_logic_vector := "0000000000000000" ;
  constant ADDR_INPUT : std_logic_vector := "0000000000001000" ;
  constant ADDR_OUTPUT : std_logic_vector := "0000000000001001";
  constant NUM_BIT_ADDR : natural := 8;
  constant NUM_BIT_RAM : natural := 16;
  constant NUM_BIT_ONEHOT : natural := 4;
  constant VETTORE_OR : std_logic_vector :="1000";
  constant NUM_BIT_WZ : natural := 4;
end package COSTANTI;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use WORK.COSTANTI.ALL;

entity project_reti_logiche is

port (
    i_clk : in std_logic;
    i_start : in std_logic;
    i_rst : in std_logic;
    i_data : in std_logic_vector (NUM_BIT_ADDR-1 downto 0);
    o_address : out std_logic_vector (NUM_BIT_RAM-1 downto 0);
    o_done : out std_logic;
    o_en : out std_logic;
    o_we : out std_logic;
    o_data : out std_logic_vector (NUM_BIT_ADDR-1 downto 0)
);
end project_reti_logiche;

architecture progettoRetiLogiche of project_reti_logiche is

    --##stati della macchina##
    type state_type is (

    S_IDLE,
    S_START,
    S_RECEIVE_ADDR,
    S_REQUEST_WZ,
    S_RECEIVE_WZ,
    S_OFFSET,
    S_CHECK,
    S_ENCODE,
    S_SEND,
    S_DONE

    );

    --##registri##
    signal current_state : state_type;
    signal next_state : state_type;

    -- segnali per i dati in ingresso
    signal input_addr_reg : std_logic_vector(NUM_BIT_ADDR-1 downto 0);
    signal input_addr_signal : std_logic_vector(NUM_BIT_ADDR-1 downto 0);

    signal input_wz_reg : std_logic_vector (NUM_BIT_ADDR-1 downto 0);
    signal input_wz_signal : std_logic_vector (NUM_BIT_ADDR-1 downto 0);

    -- addr che viene restituito
    signal out_encode_reg : std_logic_vector (NUM_BIT_ADDR-1 downto 0);
    signal out_encode_signal : std_logic_vector (NUM_BIT_ADDR-1 downto 0);

    --segnali interni
    signal num_of_wz_reg : std_logic_vector (NUM_BIT_WZ-1 downto 0);
    signal num_of_wz_signal : std_logic_vector (NUM_BIT_WZ-1 downto 0);

    -- differenza fra addr e wz per vedere se appartiene
    signal offset_reg : std_logic_vector (NUM_BIT_ADDR-1 downto 0);
    signal offset_signal : std_logic_vector (NUM_BIT_ADDR-1 downto 0);

    --one hot dell offset della wz
    signal onehot : std_logic_vector (NUM_BIT_ONEHOT-1 downto 0);

begin

    --creo e inizializzo i registri
    Registri:process(i_clk, i_rst, next_state, input_addr_signal,input_wz_signal, num_of_wz_signal,offset_signal,out_encode_signal)
    begin
        if(i_clk'event and i_clk = '1') then
            if(i_rst = '1') then
                current_state <= S_IDLE;
                input_addr_reg <= (others => '0');
                input_wz_reg <= (others => '0');
                out_encode_reg <= (others => '0');
                num_of_wz_reg <= (others => '0');
                offset_reg <= (others => '0');
            else
                current_state <= next_state;
                input_addr_reg <= input_addr_signal;
                input_wz_reg <= input_wz_signal;
                out_encode_reg <= out_encode_signal;
                num_of_wz_reg <= num_of_wz_signal;
                offset_reg <= offset_signal;
            end if;
        end if;
    end process;

Selezione_stati:process(current_state, i_start, input_wz_reg, input_addr_reg, num_of_wz_reg, offset_reg)
    begin
        case current_state is
            when S_IDLE =>
                offset_signal <= offset_reg;
                if(i_start = '1') then
                    next_state <= S_START;
                else
                    next_state <= S_IDLE;
                end if;

            when S_START =>
                offset_signal <= offset_reg;
                next_state <= S_RECEIVE_ADDR;

            when S_RECEIVE_ADDR =>
                offset_signal <= offset_reg;
                next_state <= S_REQUEST_WZ;

            when S_REQUEST_WZ =>
                offset_signal <= offset_reg;
                if(unsigned(num_of_wz_reg) = NUM_WZ) then
                    next_state <= S_SEND;
                else
                    next_state <= S_RECEIVE_WZ;
                end if;

            when S_RECEIVE_WZ =>
                offset_signal <= offset_reg;
                next_state <= S_OFFSET;

            when S_OFFSET =>
                if(unsigned(input_wz_reg) <= unsigned(input_addr_reg)) then
                  offset_signal <= std_logic_vector((unsigned(input_addr_reg)) - (unsigned(input_wz_reg)));
                  next_state <= S_CHECK;
                else
                  offset_signal <= (others => '-');
                  next_state <= S_REQUEST_WZ;
                end if;

            when S_CHECK =>
                 offset_signal <= offset_reg;
                 if(unsigned(offset_reg) < DIM_WZ ) then
                    next_state <= S_ENCODE;
                 else
                     next_state <= S_REQUEST_WZ;
                 end if;
    
            when S_ENCODE =>
                offset_signal <= offset_reg;
                next_state <= S_SEND;

            when S_SEND =>
                offset_signal <= offset_reg;
                next_state <= S_DONE;

            when S_DONE =>
                offset_signal <= offset_reg;
                if (i_start = '1') then
                    next_state <= S_DONE;
                else
                    next_state <= S_IDLE;
                end if;
            end case;
        end process;

    --#####INPUT######
    input_addr_signal <= i_data when (current_state = S_RECEIVE_ADDR) else input_addr_reg;
    input_wz_signal <= i_data when (current_state = S_RECEIVE_WZ) else input_wz_reg;

    --##LOGICA##
  Codifica:process(current_state,next_state,offset_reg,num_of_wz_reg,onehot,input_addr_reg,out_encode_reg)
    begin
        if(next_state = S_SEND and current_state = S_ENCODE) then
            onehot <= (others => '0');
            onehot(to_integer(unsigned(offset_reg))) <= '1';
            --costruisco l'indirizzo finale
            out_encode_signal <= (num_of_wz_reg or VETTORE_OR) & onehot;
        elsif (next_state = S_SEND and current_state = S_REQUEST_WZ) then
            onehot <= (others => '0');
            out_encode_signal <= input_addr_reg;
        else
            onehot <= (others => '0');
            out_encode_signal <= out_encode_reg;   
        end if;
        
    end process;

   GestioneWZReg:process(current_state, next_state, num_of_wz_reg)
    begin
      if(next_state = S_REQUEST_WZ and current_state /= S_RECEIVE_ADDR) then
        num_of_wz_signal <= std_logic_vector(unsigned(num_of_wz_reg) +1);
      elsif (current_state = S_START) then
        num_of_wz_signal <= (others => '0');
      else
        num_of_wz_signal <= num_of_wz_reg;
      end if;
    end process;

   --#####OUTPUT#####
    with current_state select o_address <=
        (others => '-') when S_IDLE|S_CHECK|S_ENCODE|S_OFFSET|S_RECEIVE_ADDR|S_DONE|S_RECEIVE_WZ,
        ADDR_INPUT when S_START,
        std_logic_vector(unsigned(ADDRESS) + unsigned(num_of_wz_reg)) when S_REQUEST_WZ,
        ADDR_OUTPUT when S_SEND;


    o_en <= '1'when (current_state /= S_IDLE and current_state /= S_DONE and current_state /= S_CHECK and current_state /= S_ENCODE and current_state /= S_OFFSET) else '0';
    o_we <= '1'when (next_state = S_DONE and current_state /= S_DONE) else '0';

    o_data <= out_encode_reg when( next_state = S_DONE and current_state /= S_DONE) else (others => '-');

    o_done <= '1' when (next_state = S_DONE) else '0';

end progettoRetiLogiche;
