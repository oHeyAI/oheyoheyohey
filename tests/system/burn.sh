#!/bin/bash

function burn_tests()
{
  local quantity=100.00000000
  local max_supply_quantity=1000000000.00000000
  local symbol=O
  local precision=8
  burn_success 
  burn_wrong_authority 
  burn_wrong_quantity_amount 
  burn_wrong_quantity_symbol 
  burn_no_balance 
  burn_when_locked 
}

function burn_no_locked_balance()
{
  local o_contract=$(setup_o_contract)
  if [[ $? -ne 0 ]]
  then
    test_fail "${FUNCNAME[0]}: Failed to set o contract: $o_contract"
    return 1
  fi
  local result=$( (cleos push action $o_contract create "[\"$o_contract\" \"$max_supply_quantity $symbol\"]" -p $o_contract) 2>&1)
  if [[ $? -ne 0 ]]
  then
    test_fail "Failed to create $symbol token: $result"
    return 1
  fi
  local account1=$(create_random_account)
  if [[ $? -ne 0 ]]
  then
    test_fail "${FUNCNAME[0]}: Failed to create account1: $account1"
    return 1
  fi
  result=$( (helper_send_token $account1 $quantity $symbol $chex_contract $chex_contract) 2>&1)
  if [[ $? -ne 0 ]]
  then
    test_fail "${FUNCNAME[0]}: Failed to generate tokens for test: $result"
    return 1
  fi

  local stats_table=$(cleos get table $o_contract $symbol stat)
  local supply=$(echo $stats_table | jq -r .rows[0].supply)
  local max_supply=$(echo $stats_table | jq -r .rows[0].max_supply)
  local issuer=$(echo $stats_table | jq -r .rows[0].issuer)

  if [[ $supply != "$quantity $symbol" ]]
  then
    test_fail "${FUNCNAME[0]}: Expected a supply of \"$quantity $symbol\" but observed \"$supply\""
    return 1
  fi

  if [[ $max_supply != "$max_supply_quantity $symbol" ]]
  then
    test_fail "${FUNCNAME[0]}: Expected a max supply of \"$max_supply_quantity $symbol\" but observed \"$max_supply\""
    return 1
  fi

  if [[ $issuer != $o_contract ]]
  then
    test_fail "${FUNCNAME[0]}: Expected issuer to be \"$o_contract\" but observed \"$issuer\""
    return 1
  fi

  local account1_balance_before_burn=$(cleos get table $o_contract $account1 accounts | jq -r .rows[0].balance)
  if [[ $account1_balance_before_burn != "$quantity $symbol" ]]
  then
    test_fail "${FUNCNAME[0]}: The balance of account1 is incorrect, expected \"$quantity $symbol\" but observed \"$account1_balance_before_burn\""
    return 1
  fi

  result=$( (cleos push action -f $o_contract burn "[$account1 \"$quantity $symbol\"]" -p $account1) 2>&1)
  if [[ $? -ne 0 ]]
  then
    test_fail "The burn failed although it should have succeeded: $result"
    return 1
  fi

  local account1_balance_after_burn=$(cleos get table $o_contract $account1 accounts | jq -r .rows[0].balance)
  if [[ $account1_balance_after_burn != "0.00000000 $symbol" ]]
  then
    test_fail "${FUNCNAME[0]}: The balance of account1 is incorrect, expected \"0.00000000 $symbol\" but observed \"$account1_balance_after_burn\""
    return 1
  fi

  local stats_table=$(cleos get table $chex_contract $symbol stat)
  local supply=$(echo $stats_table | jq -r .rows[0].supply)
  local max_supply=$(echo $stats_table | jq -r .rows[0].max_supply)
  local issuer=$(echo $stats_table | jq -r .rows[0].issuer)
  
  local expected_supply="0.00000000 $symbol"
  local expected_max_supply="$(echo "scale=8; ($max_supply_quantity - $quantity)/1.0" | bc) $symbol"

  if [[ $supply != $expected_supply ]]
  then
    test_fail "${FUNCNAME[0]}: Expected a supply of \"$expected_supply\" but observed \"$supply\""
    return 1
  fi

  if [[ $max_supply != "$expected_max_supply" ]]
  then
    test_fail "${FUNCNAME[0]}: Expected a max supply of \"$expected_max_supply\" but observed \"$max_supply\""
    return 1
  fi

  if [[ $issuer != $chex_contract ]]
  then
    test_fail "${FUNCNAME[0]}: Expected issuer to be \"$chex_contract\" but observed \"$issuer\""
    return 1
  fi

  test_pass "${FUNCNAME[0]}"
}

function burn_partially_locked_balance()
{
  local chex_contract=$(setup_o_contract)
  if [[ $? -ne 0 ]]
  then
    test_fail "${FUNCNAME[0]}: Failed to set chex contract: $o_contract"
    return 1
  fi
  local result=$( (cleos push action $chex_contract create "[\"$o_contract\" \"$max_supply_quantity $symbol\"]" -p $o_contract) 2>&1)
  if [[ $? -ne 0 ]]
  then
    test_fail "Failed to create $symbol token: $result"
    return 1
  fi
  local account1=$(create_random_account)
  if [[ $? -ne 0 ]]
  then
    test_fail "${FUNCNAME[0]}: Failed to create account1: $account1"
    return 1
  fi
  result=$( (helper_send_token $account1 $quantity $symbol $chex_contract $chex_contract) 2>&1)
  if [[ $? -ne 0 ]]
  then
    test_fail "${FUNCNAME[0]}: Failed to generate tokens for test: $result"
    return 1
  fi

  local locked_quantity=$(echo "scale=8; $quantity / 2.0" | bc)
  local unlocked_quantity=$(echo "scale=8; ($quantity - $locked_quantity)/1.0" | bc)

  local stats_table=$(cleos get table $chex_contract $symbol stat)
  local supply=$(echo $stats_table | jq -r .rows[0].supply)
  local max_supply=$(echo $stats_table | jq -r .rows[0].max_supply)
  local issuer=$(echo $stats_table | jq -r .rows[0].issuer)

  if [[ $supply != "$quantity $symbol" ]]
  then
    test_fail "${FUNCNAME[0]}: Expected a supply of \"$quantity $symbol\" but observed \"$supply\""
    return 1
  fi

  if [[ $max_supply != "$max_supply_quantity $symbol" ]]
  then
    test_fail "${FUNCNAME[0]}: Expected a max supply of \"$max_supply_quantity $symbol\" but observed \"$max_supply\""
    return 1
  fi

  if [[ $issuer != $chex_contract ]]
  then
    test_fail "${FUNCNAME[0]}: Expected issuer to be \"$chex_contract\" but observed \"$issuer\""
    return 1
  fi

  result=$( (cleos push action -f $chex_contract lock "[$account1 \"$locked_quantity $symbol\" 1]" -p $account1) 2>&1)
  if [[ $? -ne 0 ]]
  then
    test_fail "${FUNCNAME[0]}: Failed to lock tokens: $result"
    return 1
  fi

  local account1_balance_before_burn=$(cleos get table $chex_contract $account1 accounts | jq -r .rows[0].balance)
  if [[ $account1_balance_before_burn != "$quantity $symbol" ]]
  then
    test_fail "${FUNCNAME[0]}: The balance of account1 is incorrect, expected \"$quantity $symbol\" but observed \"$account1_balance_before_burn\""
    return 1
  fi

  local account1_locked_before_burn=$(cleos get table $chex_contract $account1 accounts | jq -r .rows[0].locked)
  if [[ $account1_locked_before_burn != "$locked_quantity $symbol" ]]
  then
    test_fail "${FUNCNAME[0]}: The locked of account1 is incorrect, expected \"$locked_quantity $symbol\" but observed \"$account1_locked_before_burn\""
    return 1
  fi

  result=$( (cleos push action -f $chex_contract burn "[$account1 \"$unlocked_quantity $symbol\"]" -p $account1) 2>&1)
  if [[ $? -ne 0 ]]
  then
    test_fail "The burn failed although it should have succeeded: $result"
    return 1
  fi

  local locked_quantity=$(echo "scale=8; $quantity / 2.0" | bc)
  local unlocked_quantity=$(echo "scale=8; ($quantity - $locked_quantity)/1.0" | bc)

  local stats_table=$(cleos get table $chex_contract $symbol stat)
  local supply=$(echo $stats_table | jq -r .rows[0].supply)
  local max_supply=$(echo $stats_table | jq -r .rows[0].max_supply)
  local issuer=$(echo $stats_table | jq -r .rows[0].issuer)
  
  local expected_supply="$locked_quantity $symbol"
  local expected_max_supply="$(echo "scale=8; ($max_supply_quantity - $unlocked_quantity)/1.0" | bc) $symbol"

  if [[ $supply != $expected_supply ]]
  then
    test_fail "${FUNCNAME[0]}: Expected a supply of \"$expected_supply\" but observed \"$supply\""
    return 1
  fi

  if [[ $max_supply != "$expected_max_supply" ]]
  then
    test_fail "${FUNCNAME[0]}: Expected a max supply of \"$expected_max_supply\" but observed \"$max_supply\""
    return 1
  fi

  if [[ $issuer != $chex_contract ]]
  then
    test_fail "${FUNCNAME[0]}: Expected issuer to be \"$chex_contract\" but observed \"$issuer\""
    return 1
  fi

  test_pass "${FUNCNAME[0]}"
}

function burn_success()
{
  burn_no_locked_balance
  burn_partially_locked_balance
}

function burn_wrong_authority()
{
  local chex_contract=$(setup_chex_contract)
  if [[ $? -ne 0 ]]
  then
    test_fail "${FUNCNAME[0]}: Failed to set chex contract: $chex_contract"
    return 1
  fi
  local result=$( (cleos push action $chex_contract create "[\"$chex_contract\" \"$max_supply_quantity $symbol\"]" -p $chex_contract) 2>&1)
  if [[ $? -ne 0 ]]
  then
    test_fail "Failed to create $symbol token: $result"
    return 1
  fi

  local account1=$(create_random_account)
  if [[ $? -ne 0 ]]
  then
    test_fail "${FUNCNAME[0]}: Failed to create account1: $account1"
    return 1
  fi

  local account2=$(create_random_account)
  if [[ $? -ne 0 ]]
  then
    test_fail "${FUNCNAME[0]}: Failed to create account1: $account1"
    return 1
  fi

  result=$( (helper_send_token $account1 $quantity $symbol $chex_contract $chex_contract) 2>&1)
  if [[ $? -ne 0 ]]
  then
    test_fail "${FUNCNAME[0]}: Failed to generate tokens for test: $result"
    return 1
  fi

  result=$( (cleos push action -f $chex_contract burn "[$account1 \"$quantity $symbol\"]" -p $account2) 2>&1)
  if [[ $? -eq 0 ]]
  then
    test_fail "The burn succeeded, despite the account not being the authorizer"
    return 1
  fi

  test_pass "${FUNCNAME[0]}"
}

function burn_wrong_quantity_amount()
{
  local chex_contract=$(setup_chex_contract)
  if [[ $? -ne 0 ]]
  then
    test_fail "${FUNCNAME[0]}: Failed to set chex contract: $chex_contract"
    return 1
  fi
  local result=$( (cleos push action $chex_contract create "[\"$chex_contract\" \"$max_supply_quantity $symbol\"]" -p $chex_contract) 2>&1)
  if [[ $? -ne 0 ]]
  then
    test_fail "Failed to create $symbol token: $result"
    return 1
  fi
  local account1=$(create_random_account)
  if [[ $? -ne 0 ]]
  then
    test_fail "${FUNCNAME[0]}: Failed to create account1: $account1"
    return 1
  fi
  result=$( (helper_send_token $account1 $quantity $symbol $chex_contract $chex_contract) 2>&1)
  if [[ $? -ne 0 ]]
  then
    test_fail "${FUNCNAME[0]}: Failed to generate tokens for test: $result"
    return 1
  fi

  result=$( (cleos push action -f $chex_contract burn "[$account1 \"0.00000000 $symbol\"]" -p $account1) 2>&1)
  if [[ $? -eq 0 ]]
  then
    test_fail "The burn succeeded, despite quantity being zero"
    return 1
  fi
  result=$( (cleos push action -f $chex_contract burn "[$account1 \"-1.00000000 $symbol\"]" -p $account1) 2>&1)
  if [[ $? -eq 0 ]]
  then
    test_fail "The burn succeeded, despite quantity being negative"
    return 1
  fi

  test_pass "${FUNCNAME[0]}"
}

function burn_wrong_quantity_symbol()
{
  local chex_contract=$(setup_chex_contract)
  if [[ $? -ne 0 ]]
  then
    test_fail "${FUNCNAME[0]}: Failed to set chex contract: $chex_contract"
    return 1
  fi
  local result=$( (cleos push action $chex_contract create "[\"$chex_contract\" \"$max_supply_quantity $symbol\"]" -p $chex_contract) 2>&1)
  if [[ $? -ne 0 ]]
  then
    test_fail "Failed to create $symbol token: $result"
    return 1
  fi
  local account1=$(create_random_account)
  if [[ $? -ne 0 ]]
  then
    test_fail "${FUNCNAME[0]}: Failed to create account1: $account1"
    return 1
  fi
  result=$( (helper_send_token $account1 $quantity $symbol $chex_contract $chex_contract) 2>&1)
  if [[ $? -ne 0 ]]
  then
    test_fail "${FUNCNAME[0]}: Failed to generate tokens for test: $result"
    return 1
  fi

  result=$( (cleos push action -f $chex_contract burn "[$account1 \"$quantity FAKE\"]" -p $account1) 2>&1)
  if [[ $? -eq 0 ]]
  then
    test_fail "The burn succeeded, despite symbol being incorrect"
    return 1
  fi

  test_pass "${FUNCNAME[0]}"
}

function burn_no_balance()
{
  local chex_contract=$(setup_chex_contract)
  if [[ $? -ne 0 ]]
  then
    test_fail "${FUNCNAME[0]}: Failed to set chex contract: $chex_contract"
    return 1
  fi
  local result=$( (cleos push action $chex_contract create "[\"$chex_contract\" \"$max_supply_quantity $symbol\"]" -p $chex_contract) 2>&1)
  if [[ $? -ne 0 ]]
  then
    test_fail "Failed to create $symbol token: $result"
    return 1
  fi
  local account1=$(create_random_account)
  if [[ $? -ne 0 ]]
  then
    test_fail "${FUNCNAME[0]}: Failed to create account1: $account1"
    return 1
  fi

  result=$( (cleos push action -f $chex_contract burn "[$account1 \"$quantity $symbol\"]" -p $account1) 2>&1)
  if [[ $? -eq 0 ]]
  then
    test_fail "The burn succeeded, despite account1 having no funds"
    return 1
  fi

  test_pass "${FUNCNAME[0]}"
}

function burn_when_locked()
{
  local chex_contract=$(setup_chex_contract)
  if [[ $? -ne 0 ]]
  then
    test_fail "${FUNCNAME[0]}: Failed to set chex contract: $chex_contract"
    return 1
  fi
  local result=$( (cleos push action $chex_contract create "[\"$chex_contract\" \"$max_supply_quantity $symbol\"]" -p $chex_contract) 2>&1)
  if [[ $? -ne 0 ]]
  then
    test_fail "Failed to create $symbol token: $result"
    return 1
  fi
  local account1=$(create_random_account)
  if [[ $? -ne 0 ]]
  then
    test_fail "${FUNCNAME[0]}: Failed to create account1: $account1"
    return 1
  fi
  result=$( (helper_send_token $account1 $quantity $symbol $chex_contract $chex_contract) 2>&1)
  if [[ $? -ne 0 ]]
  then
    test_fail "${FUNCNAME[0]}: Failed to generate tokens for test: $result"
    return 1
  fi
  result=$( (cleos push action -f $chex_contract lock "[$account1 \"$quantity $symbol\" 1]" -p $account1) 2>&1)
  if [[ $? -ne 0 ]]
  then
    test_fail "${FUNCNAME[0]}: Failed to lock tokens: $result"
    return 1
  fi

  result=$( (cleos push action -f $chex_contract burn "[$account1 \"$quantity $symbol\"]" -p $account1) 2>&1)
  if [[ $? -eq 0 ]]
  then
    test_fail "The burn succeeded, despite account1 having its funds locked up"
    return 1
  fi

  result=$( (helper_send_token $account1 $quantity $symbol $chex_contract $chex_contract) 2>&1)
  if [[ $? -ne 0 ]]
  then
    test_fail "${FUNCNAME[0]}: Failed to generate tokens for test: $result"
    return 1
  fi

  local half_quantity=$(echo "scale=8; $quantity / 2.0" | bc)
  result=$( (cleos push action -f $chex_contract lock "[$account1 \"$half_quantity $symbol\" 1]" -p $account1) 2>&1)
  if [[ $? -ne 0 ]]
  then
    test_fail "${FUNCNAME[0]}: Failed to lock tokens: $result"
    return 1
  fi

  result=$( (cleos push action -f $chex_contract burn "[$account1 \"$quantity $symbol\"]" -p $account1) 2>&1)
  if [[ $? -eq 0 ]]
  then
    test_fail "The burn succeeded, despite account1 having its too many funds locked up"
    return 1
  fi

  test_pass "${FUNCNAME[0]}"
}
