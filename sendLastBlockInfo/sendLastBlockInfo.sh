#!/bin/bash

PATH="your $PATH Variable"

# your pool id hash
PoolID=""

# get this from your account profile page on pooltool website
MyPooltoolApiKey=""

### Blockfrost API Key
bfKey=""

### Send Tip to pooltool.io
PLATFORM="POOL sendLastBlockInfo"
### Where POOL is replaced with your pool ticker

### SSH Access to BP
dir=<your dir>
bphost=$(cat $dir/.bphost)
pswd=$(cat $dir/.passwd)
port=$(cat $dir/.port)
### create .bphost, .passwd, .port with your values


while :
do

        blockInfo=$(curl -s https://cardano-mainnet.blockfrost.io/api/v0/blocks/latest -X GET -H "project_id: $bfKey")
        latestParams=$(curl -s https://cardano-mainnet.blockfrost.io/api/v0/epochs/latest/parameters -X GET -H "project_id: $bfKey")

        nodeVersion_out=$(cardano-node --version)
        nodeVersion=$(echo $nodeVersion_out | head -n 1 | cut -f 2 -d " ")

        ###  nodeTip: Get lastSlot, lastBlockHash, lastBlockHeight from BP Node:
        ###  In this scenario "username" is the bp remote user which run command sudo to impersonate tecuser and run 
        ###  the script check_tip2pooltool.sh which is just:
        ###  export CARDANO_NODE_SOCKET_PATH="/your_path/node.socket" ; cardano-cli query tip --mainnet
        ###  ensure you have ssh access with keys (root and password disabled) to your BP
        ###  and that you have same home username on your servers
        ###  you may need to adjust it to match your settings. 
        
        nodeTip=$(echo         ${pswd}    | ssh username@${bphost} -p ${port}  'sudo -u tecuser -S check_tip2pooltool.sh 2>/dev/null')
        lastSlot=$(echo        ${nodeTip} | jq -r .slot)
        lastBlockHash=$(echo   ${nodeTip} | jq -r .hash)
        lastBlockHeight=$(echo ${nodeTip} | jq -r .block)

        blockTime=$(echo ${blockInfo}     | jq -r .time)
        at=$(date -d @${blockTime} '+%Y-%m-%dT%H:%M:%S.%2NZ')
        parentHash=$(echo ${blockInfo}    | jq -r .previous_block)
        blockVrf=$(echo ${blockInfo}      | jq -r .block_vrf)
        slotLeader=$(echo ${blockInfo}    | jq -r .slot_leader)

        protocolMajorVersion=$(echo ${latestParams} | jq -r .protocol_major_ver)
        protocolMinorVersion=$(echo ${latestParams} | jq -r .protocol_minor_ver)


        JSONBLOCK="$(jq -n --compact-output --arg MY_API_KEY "$MyPooltoolApiKey" --arg MY_POOL_ID "$PoolID" --arg VERSION "$nodeVersion" --arg AT "$at" --arg BLOCKNO "$lastBlockHeight" --arg SLOTNO "$lastSlot" --arg PLATFORM "$PLATFORM" --arg BLOCKHASH "$lastBlockHash" --arg PARENTHASH "$parentHash" --arg BLOCKVRF "$blockVrf" --arg SLOTLEADER "$slotLeader" --arg PROTOMAJORVER "$protocolMajorVersion" --arg PROTOMINORVER "$protocolMinorVersion" '{apiKey: $MY_API_KEY, poolId: $MY_POOL_ID, data: {blockTime: $AT, blockNo: $BLOCKNO, slotNo: $SLOTNO, blockHash: $BLOCKHASH, parentHash: $PARENTHASH, blockVrf: $BLOCKVRF, slotLeader: $SLOTLEADER, protocolMajorVersion: $PROTOMAJORVER, protocolMinorVersion: $PROTOMINORVER, version: $VERSION, platform: $PLATFORM}}')"
        echo "Packet Sent: $JSONBLOCK"

        if [ "${lastBlockHeight}" != "" ]; then
        RESPONSE1="$(curl -s -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data "$JSONBLOCK" "https://api.pooltool.io/v0/sendstats")"
        echo $RESPONSE1
        fi

### I set this to just two seconds, I observed than a value higher than 5
### can cause some temporary switch-off (green to red) of the block number on pooltool.io
sleep 2

done