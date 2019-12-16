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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

--=================================================================================================
--=================================================================================================
--=================================================================================================
package transaction_pkg is

  --===============================================================================================
  -- t_operation
  -- - Bitvis defined BFM operations
  --===============================================================================================
  type t_operation is (
    -- UVVM common
    NO_OPERATION,
    AWAIT_COMPLETION,
    AWAIT_ANY_COMPLETION,
    ENABLE_LOG_MSG,
    DISABLE_LOG_MSG,
    FLUSH_COMMAND_QUEUE,
    FETCH_RESULT,
    INSERT_DELAY,
    TERMINATE_CURRENT_COMMAND,
    -- VVC local
    MASTER_TRANSMIT_AND_RECEIVE, MASTER_TRANSMIT_AND_CHECK, MASTER_TRANSMIT_ONLY, MASTER_RECEIVE_ONLY, MASTER_CHECK_ONLY,
    SLAVE_TRANSMIT_AND_RECEIVE, SLAVE_TRANSMIT_AND_CHECK, SLAVE_TRANSMIT_ONLY, SLAVE_RECEIVE_ONLY, SLAVE_CHECK_ONLY);


  constant C_VVC_CMD_STRING_MAX_LENGTH : natural := 300;
  constant C_VVC_CMD_DATA_MAX_LENGTH   : natural := 32;
  constant C_VVC_CMD_MAX_WORDS         : natural := 8;



  --==========================================================================================
  --
  -- DTT - Direct Transaction Transfer types, constants and global signal
  --
  --==========================================================================================

  -- Transaction status
  type t_transaction_status is (INACTIVE, IN_PROGRESS, FAILED, SUCCEEDED);

  constant C_TRANSACTION_STATUS_DEFAULT : t_transaction_status := INACTIVE;

  -- VVC Meta
  type t_vvc_meta is record
    msg     : string(1 to C_VVC_CMD_STRING_MAX_LENGTH);
    cmd_idx : integer;
  end record;

  constant C_VVC_META_DEFAULT : t_vvc_meta := (
    msg     => (others => ' '),
    cmd_idx => -1
    );


  -- Transaction
  type t_transaction is record
    operation           : t_operation;
    data                : std_logic_vector(C_VVC_CMD_DATA_MAX_LENGTH-1 downto 0);
    vvc_meta            : t_vvc_meta;
    transaction_status  : t_transaction_status;
  end record;

  constant C_TRANSACTION_SET_DEFAULT : t_transaction := (
    operation           => NO_OPERATION,
    data                => (others => '0'),
    vvc_meta            => C_VVC_META_DEFAULT,
    transaction_status  => C_TRANSACTION_STATUS_DEFAULT
    );

  -- Transaction group
  type t_transaction_group is record
    bt : t_transaction;
  end record;

  constant C_TRANSACTION_GROUP_DEFAULT : t_transaction_group := (
    bt => C_TRANSACTION_SET_DEFAULT
    );

  -- Transaction groups array
  type t_spi_transaction_group_array is array (natural range <>) of t_transaction_group;


  -- Global DTT signals
  signal global_spi_vvc_transaction : t_spi_transaction_group_array(0 to C_MAX_VVC_INSTANCE_NUM) :=
    (others => C_TRANSACTION_GROUP_DEFAULT);


end package transaction_pkg;