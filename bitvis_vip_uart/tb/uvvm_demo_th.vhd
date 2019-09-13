--========================================================================================================================
-- Copyright (c) 2017 by Bitvis AS.  All rights reserved.
-- You should have received a copy of the license file containing the MIT License (see LICENSE.TXT), if not,
-- contact Bitvis AS <support@bitvis.no>.
--
-- UVVM AND ANY PART THEREOF ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
-- WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
-- OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
-- OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH UVVM OR THE USE OR OTHER DEALINGS IN UVVM.
--========================================================================================================================

------------------------------------------------------------------------------------------
-- Description   : See library quick reference (under 'doc') and README-file(s)
------------------------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library uvvm_vvc_framework;
use uvvm_vvc_framework.ti_vvc_framework_support_pkg.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;    -- t_channel (RX/TX)

library bitvis_vip_sbi;
use bitvis_vip_sbi.transaction_pkg.all;
use bitvis_vip_sbi.vvc_methods_pkg.all;
use bitvis_vip_sbi.td_vvc_framework_common_methods_pkg.all;

library bitvis_vip_uart;
use bitvis_vip_uart.transaction_pkg.all;
use bitvis_vip_uart.vvc_methods_pkg.all;
use bitvis_vip_uart.td_vvc_framework_common_methods_pkg.all;

library bitvis_uart;
library bitvis_vip_clock_generator;

library bitvis_vip_scoreboard;
use bitvis_vip_scoreboard.generic_sb_support_pkg.all;



-- Test harness entity
entity uvvm_demo_th is
end entity;

-- Test harness architecture
architecture struct of uvvm_demo_th is

  -- Clock and bit period settings
  constant C_CLK_PERIOD         : time := 10 ns;
  constant C_BIT_PERIOD         : time := 16 * C_CLK_PERIOD;


  constant C_DATA_WIDTH   : natural := 8;
  constant C_ADDR_WIDTH   : natural := 3;
  constant C_SBI_VVC      : natural := 1;
  constant C_UART_TX_VVC  : natural := 1;
  constant C_UART_RX_VVC  : natural := 1;

  constant C_ADDR_RX_DATA : unsigned(2 downto 0) := "000";


  -- DSP interface and general control signals
  signal clk            : std_logic  := '0';
  signal arst           : std_logic  := '0';

  -- SBI VVC signals
  signal cs             : std_logic;
  signal addr           : unsigned(2 downto 0);
  signal wr             : std_logic;
  signal rd             : std_logic;
  signal wdata          : std_logic_vector(7 downto 0);
  signal rdata          : std_logic_vector(7 downto 0);
  signal ready          : std_logic;

  -- UART VVC signals
  signal uart_vvc_rx    : std_logic := '1';
  signal uart_vvc_tx    : std_logic := '1';

  constant C_CLOCK_GEN  : natural := 1;



begin

  -----------------------------------------------------------------------------
  -- Instantiate the concurrent procedure that initializes UVVM
  -----------------------------------------------------------------------------
  i_ti_uvvm_engine : entity uvvm_vvc_framework.ti_uvvm_engine;

  -----------------------------------------------------------------------------
  -- Instantiate DUT
  -----------------------------------------------------------------------------
  i_uart: entity bitvis_uart.uart
    port map (
      -- DSP interface and general control signals
      clk             => clk,
      arst            => arst,
      -- CPU interface
      cs              => cs,
      addr            => addr,
      wr              => wr,
      rd              => rd,
      wdata           => wdata,
      rdata           => rdata,
      -- UART signals
      rx_a            => uart_vvc_tx,
      tx              => uart_vvc_rx
  );


  -----------------------------------------------------------------------------
  -- SBI VVC
  -----------------------------------------------------------------------------
  i1_sbi_vvc: entity bitvis_vip_sbi.sbi_vvc
  generic map(
    GC_ADDR_WIDTH     => C_ADDR_WIDTH,
    GC_DATA_WIDTH     => C_DATA_WIDTH,
    GC_INSTANCE_IDX   => 1
  )
  port map(
    clk                         => clk,
    sbi_vvc_master_if.cs        => cs,
    sbi_vvc_master_if.rena      => rd,
    sbi_vvc_master_if.wena      => wr,
    sbi_vvc_master_if.addr      => addr,
    sbi_vvc_master_if.wdata     => wdata,
    sbi_vvc_master_if.ready     => ready,
    sbi_vvc_master_if.rdata     => rdata
  );


  -----------------------------------------------------------------------------
  -- UART VVC
  -----------------------------------------------------------------------------
  i1_uart_vvc: entity bitvis_vip_uart.uart_vvc
  generic map(
    GC_DATA_WIDTH     => 8,
    GC_INSTANCE_IDX   => 1
  )
  port map(
    uart_vvc_rx         => uart_vvc_rx,
    uart_vvc_tx         => uart_vvc_tx
  );


  -- Static '1' ready signal for the SBI VVC
  ready <= '1';

  -- Toggle the reset after 5 clock periods
  p_arst: arst <= '1', '0' after 5 *C_CLK_PERIOD;


  -----------------------------------------------------------------------------
  -- Monitor - UART
  -----------------------------------------------------------------------------








  -----------------------------------------------------------------------------
  -- Model
  -----------------------------------------------------------------------------
  p_model: process
    -- SBI DTT
    alias sbi_dtt : bitvis_vip_sbi.transaction_pkg.t_transaction_info_group is
      global_sbi_transaction_info(C_SBI_VVC);
    -- UART DTT
    alias uart_rx_dtt : bitvis_vip_uart.transaction_pkg.t_transaction_info_group is
      global_uart_transaction_info(RX, C_UART_RX_VVC);
    alias uart_tx_dtt : bitvis_vip_uart.transaction_pkg.t_transaction_info_group is
      global_uart_transaction_info(TX, C_UART_TX_VVC);

  begin

    while true loop

      -- Wait for DTT trigger
      wait on sbi_dtt, uart_rx_dtt, uart_tx_dtt;


      -------------------------------
      -- SBI DTT
      -------------------------------
      if sbi_dtt.bt'event then

        case sbi_dtt.bt.operation is
          when WRITE =>
            if (sbi_dtt.bt.error_info.write_and_read_error = false) then
                -- add to UART scoreboard
                shared_uart_sb.add_expected(sbi_dtt.bt.data(C_DATA_WIDTH-1 downto 0));
            end if;

          when READ =>


          when others =>
            null;
        end case;
      end if;


      -------------------------------
      -- UART RX DTT
      -------------------------------
      if uart_rx_dtt.bt'event then
        -- Send to SB is handled by RX VVC.
        null;
      end if;


      -------------------------------
      -- UART TX DTT
      -------------------------------
      if uart_tx_dtt.bt'event then

        case uart_tx_dtt.bt.operation is
          when TRANSMIT =>
            if  (uart_tx_dtt.bt.error_info.parity_bit_error = false) and
                (uart_tx_dtt.bt.error_info.stop_bit_error = false) then

                -- Add to UART scoreboard
                shared_sbi_sb.add_expected(uart_tx_dtt.bt.data(C_DATA_WIDTH-1 downto 0));
                -- Wait for UART Transmit to finish
                insert_delay(SBI_VVCT, 1, 12*C_BIT_PERIOD, "Wait for UART TX to finish");
                -- Request SBI Read
                sbi_read(SBI_VVCT, 1, C_ADDR_RX_DATA, TO_SB, "SBI_READ");

            end if;

          when others =>
            null;

        end case;
      end if;

    end loop;
    wait;
  end process p_model;



  -----------------------------------------------------------------------------
  -- Clock Generator VVC
  -----------------------------------------------------------------------------
  i_clock_generator_vvc : entity bitvis_vip_clock_generator.clock_generator_vvc
    generic map(
      GC_INSTANCE_IDX    => C_CLOCK_GEN,
      GC_CLOCK_NAME      => "Clock",
      GC_CLOCK_PERIOD    => C_CLK_PERIOD,
      GC_CLOCK_HIGH_TIME => C_CLK_PERIOD / 2
      )
    port map(
      clk => clk
      );


end struct;
