#!/bin/bash

setup_o_contract(){
  local oheyoheyohey=$(generate_random_name)
  result=$( (cleos system newaccount eosio $oheyoheyohey $public_key --stake-net "100000.00000000 O" --stake-cpu "100000.00000000 O" --buy-ram-kbytes 10000) 2>&1)
  if [[ $? -ne 0 ]]
  then
    echo "Failed to create account $oheyoheyohey: $result"
    return 1
  fi
  result=$( (cleos set contract $oheyoheyohey $OHEYOHEYOHEY_DIR/builds/test/oheyoheyohey oheyoheyohey.wasm oheyoheyohey.abi) 2>&1)
  if [[ $? -ne 0 ]]
  then
    echo "Failed to set oheyoheyohey contract"
    return 1
  fi
  result=$( (cleos set account permission $oheyoheyohey active --add-code) 2>&1)
  if [[ $? -ne 0 ]]
  then
    echo "Failed to set up eosio.code permission for o contract"
    return 1
  fi
  echo $oheyoheyohey
}

function helper_send_token()
{
  account=$1
  quantity=$2
  symbol=$3
  contract=$4
  issuer=$5

  if [[ $quantity != "0.0000" ]]
  then
    result=$( (cleos push action -f $contract issue "[$issuer, \"$quantity $symbol\", \"memo\"]" -p $issuer) 2>&1)
    if [[ $? -ne 0 ]]
    then 
      echo "Failed to issue $quantity $symbol to $contract: $result"
      return 1
    fi
    if [[ $issuer != $account ]]
    then
      result=$( (cleos push action -f $contract transfer "[$issuer, $account, \"$quantity $symbol\", \"memo\"]" -p $issuer) 2>&1)
      if [[ $? -ne 0 ]]
      then 
        echo "Failed to transfer $quantity $symbol to $account: $result"
        return 1
      fi
    fi
  fi
}
