#!/bin/bash

### Replace paths with your binaries paths for PATH variable
### otherwise systemd will not find the binaries used by this script.
### you can also remove PATH variable from this script and add it in systemd service
### eg: Environment = "PATH=/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin";
PATH=/your_binaries_paths1/

# your pool id hash
PoolID=""

# get this from your account profile page on pooltool website
MyPooltoolApiKey=""

### Send Tip to pooltool.io
PLATFORM="POOL pooltoolSendBlocks.sh"
### Where POOL is replaced with your pool ticker

### SSH Access to BP
dir=<your dir>
bphost=$(cat $dir/.bphost)
pswd=$(cat $dir/.passwd)
port=$(cat $dir/.port)
### create .bphost, .passwd, .port with your values
### make them read only for your user with chmod 400

blocksInfo="https://api.koios.rest/api/v0/blocks"

while :
do

      blocks=$(curl -s -X GET $blocksInfo"?limit=2" -H "accept: application/json" -H "authorization: Bearer ${koiosToken}" | jq .)
      lastBlockInfo=$(echo "${blocks}" | jq .[0])
      prevblockHash=$(echo "${blocks}" | jq -r .[1].hash)
      nodeVersion_out=$(/cardano/cnode/bin/cardano-node --version)
      nodeVersion=$(echo $nodeVersion_out | head -n 1 | cut -f 2 -d " ")


      ###  nodeTip: Get lastSlot, lastBlockHash, lastBlockHeight from BP Node:
      ###  In this scenario "username" is the bp remote user which run command sudo to impersonate tecuser and run 
      ###  the script check_tip2pooltool.sh which is just:
      ###  export CARDANO_NODE_SOCKET_PATH="/your_path/node.socket" ; cardano-cli query tip --mainnet
      ###  ensure you have ssh access with keys (root and password disabled) to your BP
      ###  and that you have same home username on your servers
      ###  you may need to adjust it to match your settings. 
        
      nodeTip=$(echo         ${pswd}    | ssh username@${bphost} -p ${port}  'sudo -u tecuser -S /cardano/cnode/scripts/check_tip2pooltool.sh 2>/dev/null')
      lastSlot=$(echo        ${nodeTip} | jq -r .slot)
      blockHash=$(echo       ${nodeTip} | jq -r .hash)
      lastBlockHeight=$(echo ${nodeTip} | jq -r .block)

      blockTime=$(echo ${lastBlockInfo}     | jq -r .block_time)
      at=$(date -d @$blockTime '+%Y-%m-%dT%H:%M:%S.%2NZ')
      blockVrf=$(echo   ${lastBlockInfo}    | jq -r .vrf_key)
      slotLeader=$(echo ${lastBlockInfo}    | jq -r .pool)

      protocolMajorVersion=$(echo ${lastBlockInfo} | jq -r .proto_major)
      protocolMinorVersion=$(echo ${lastBlockInfo} | jq -r .proto_minor)


      JSONBLOCK="$(jq -n --compact-output --arg MY_API_KEY "$MyPooltoolApiKey" --arg MY_POOL_ID "$PoolID" --arg VERSION "$nodeVersion" --arg AT "$at" --arg BLOCKNO "$lastBlockHeight" --arg SLOTNO "$lastSlot" --arg PLATFORM "$PLATFORM" --arg BLOCKHASH "$blockHash" --arg PARENTHASH "$prevblockHash" --arg BLOCKVRF "$blockVrf" --arg SLOTLEADER "$slotLeader" --arg PROTOMAJORVER "$protocolMajorVersion" --arg PROTOMINORVER "$protocolMinorVersion" '{apiKey: $MY_API_KEY, poolId: $MY_POOL_ID, data: {blockTime: $AT, blockNo: $BLOCKNO, slotNo: $SLOTNO, blockHash: $BLOCKHASH, parentHash: $PARENTHASH, blockVrf: $BLOCKVRF, slotLeader: $SLOTLEADER, protocolMajorVersion: $PROTOMAJORVER, protocolMinorVersion: $PROTOMINORVER, version: $VERSION, platform: $PLATFORM}}')"
      echo "Packet Sent: $JSONBLOCK"

      if [ "${lastBlockHeight}" != "" ]; then
      RESPONSE1="$(curl -s -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data "$JSONBLOCK" "https://api.pooltool.io/v0/sendstats")"
      echo $RESPONSE1
      fi

sleep 20

done
