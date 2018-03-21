--------------------------------------------------------------------------------
-- HEIG-VD
-- Haute Ecole d'Ingenerie et de Gestion du Canton de Vaud
-- School of Business and Engineering in Canton de Vaud
--------------------------------------------------------------------------------
-- REDS Institute
-- Reconfigurable Embedded Digital Systems
--------------------------------------------------------------------------------
--
-- File     : alu_tb.vhd
-- Author   : TbGenerator
-- Date     : 08.03.2018
--
-- Context  :
--
--------------------------------------------------------------------------------
-- Description : This module is a simple VHDL testbench.
--               It instanciates the DUV and proposes a TESTCASE generic to
--               select which test to start.
--
--------------------------------------------------------------------------------
-- Dependencies : -
--
--------------------------------------------------------------------------------
-- Modifications :
-- Ver   Date        Person     Comments
-- 0.1   08.03.2018  TbGen      Initial version
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity alu_tb is
    generic (
        TESTCASE : integer := 0;
        SIZE     : integer := 8;
        ERRNO    : integer := 0
    );

end alu_tb;

architecture testbench of alu_tb is

    signal a_sti    : std_logic_vector(SIZE-1 downto 0);
    signal b_sti    : std_logic_vector(SIZE-1 downto 0);
    signal s_obs    : std_logic_vector(SIZE-1 downto 0);
    signal c_obs    : std_logic;
    signal mode_sti : std_logic_vector(2 downto 0);

    signal sim_end_s : boolean := false;
    signal verify_sync_s : boolean := false;

    component alu is
    generic (
        SIZE  : integer := 8;
        ERRNO : integer := 0
    );
    port (
        a_i    : in std_logic_vector(SIZE-1 downto 0);
        b_i    : in std_logic_vector(SIZE-1 downto 0);
        s_o    : out std_logic_vector(SIZE-1 downto 0);
        c_o    : out std_logic;
        mode_i : in std_logic_vector(2 downto 0)
    );
    end component;


begin
    duv : alu
    generic map (
        SIZE  => SIZE,
        ERRNO => ERRNO
    )
    port map (
        a_i    => a_sti,
        b_i    => b_sti,
        s_o    => s_obs,
        c_o    => c_obs,
        mode_i => mode_sti
    );

    --------------------------------------------------
    -- stimulus_proc                        ----------
    --------------------------------------------------
    stimulus_proc: process is

    ------ procedure de stimulation --------
        procedure sti_func(a,b: std_logic_vector(SIZE-1 downto 0);
                                mode: std_logic_vector(2 downto 0)) is
        begin
            a_sti <= a;
            b_sti <= b;
            mode_sti <= mode;
        end sti_func;

    -- Génération alléatoire
        -- 2 seeds pour la génération aléatoire
        variable seed1, seed2: positive;
        -- valeur aléatoire entre 0 et 1.0
        variable rand: real;
        -- valeur aléatoire entre 0 et 2^SIZE pour stimulation
        variable int_rand_sti: integer;
        -- valeur aléatoire entre 0 et 8 pour mode
        variable int_rand_mode: integer;
        -- stimulus aléatoire sur SIZE bits
        variable a_var    : std_logic_vector(SIZE-1 downto 0);
        variable b_var    : std_logic_vector(SIZE-1 downto 0);
        -- stimulus aléatoire sur 3 bits
        variable mode_var : std_logic_vector(2 downto 0);
        -- constant pour le changement d'échelle
        variable real_size : real;
        variable int_size : integer;
    begin
        -- initialisation des seeds
        seed1 := 1;
        seed2 := 7;
        real_size := 2.0**SIZE;
        int_size := 2**SIZE;
        case TESTCASE is
            when 0      => for i in 0 to 1000 loop
                                -- Génération des nombre aléatoires
                                UNIFORM(seed1, seed2, rand);
                                int_rand_sti := integer(trunc(rand*real_size));
                                a_var := std_logic_vector(to_unsigned(int_rand_sti, SIZE));
                                UNIFORM(seed1, seed2, rand);
                                int_rand_sti := integer(trunc(rand*real_size));
                                b_var := std_logic_vector(to_unsigned(int_rand_sti, SIZE));
                                UNIFORM(seed1, seed2, rand);
                                int_rand_mode := integer(trunc(rand*8.0));
                                mode_var := std_logic_vector(to_unsigned(int_rand_mode, mode_var'length));

                                -- Appelle de la procédure de stimulis
                                sti_func(a_var, b_var, mode_var);

                                -- Vérification des valeurs en sortie
                                --verify(("0" & a_sti), ("0" & b_sti), mode_sti);

                                -- Maintient de l'état et synchro
                                wait for 25 ns;
                                verify_sync_s <= true, false after 1 ns;
                                wait for 24 ns;
                            end loop;
            when 1      => for i in 0 to 7 loop
                                mode_var := std_logic_vector(to_unsigned(i, mode_var'length));
                                for j in 0 to (int_size-1) loop
                                    a_var := std_logic_vector(to_unsigned(j, a_var'length));
                                    for k in 0 to (int_size-1) loop
                                        b_var := std_logic_vector(to_unsigned(k, b_var'length));
                                        sti_func(a_var, b_var, mode_var);

                                        -- Maintient de l'état et synchro
                                        wait for 25 ns;
                                        verify_sync_s <= true, false after 1 ns;
                                        wait for 24 ns;
                                    end loop;
                                end loop;
                            end loop;

            when others => report "Unsupported testcase : "
                                  & integer'image(TESTCASE)
                                  severity error;
        end case;

        -- end of simulation
        sim_end_s <= true;

        -- stop the process
        wait;

    end process; -- stimulus_proc

    --------------------------------------------------
    -- verify_proc                          ----------
    --------------------------------------------------
    verify_proc : process

        ------- procedure de vérification ----------
        procedure verify(a,b: std_logic_vector(SIZE downto 0);
                                mode: std_logic_vector(2 downto 0)) is
          variable s_var : std_logic_vector(SIZE downto 0);
          variable c_var : std_logic;

        begin
            case mode is
                when "000" =>   s_var := std_logic_vector(unsigned(a)+unsigned(b));
                                c_var := s_var(SIZE);
                                if c_var /= c_obs then
                                    report "Bad output value for c" severity error;
                                end if;
                when "001" =>   s_var := std_logic_vector(unsigned(a)-unsigned(b));
                                c_var := s_var(SIZE);
                                if c_var /= c_obs then
                                    report "Bad output value for c" severity error;
                                end if;
                when "010" =>   s_var := a or b;
                when "011" =>   s_var := a and b;
                when "100" =>   s_var := a;
                when "101" =>   s_var := b;
                when "110" =>   if a = b then
                                    s_var(0) := '1';
                                else
                                    s_var(0) := '0';
                                end if;
                when "111" => s_var := (others=>'0');

                when others =>  s_var := (others=>'0');
                                report "Unknow mode : "
                                      severity error;
            end case;
            --- Test de cout ----
            if mode /= "110" then
                if s_var(SIZE-1 downto 0) /= s_obs then
                    report "Bad output value for s" severity error;
                end if;
            else
                if s_var(0) /= s_obs(0) then
                    report "Bad output value for s(0)" severity error;
                end if;
            end if;

        end verify;

    begin
        while not sim_end_s loop
            wait until rising_edge(verify_sync_s) or sim_end_s;
            -- Procedure de verification
            verify(("0" & a_sti), ("0" & b_sti), mode_sti);

        end loop;
        -- stop the process
        wait;

    end process; --verify_proc
end testbench;
