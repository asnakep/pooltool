#!/run/current-system/sw/bin/bash

PATH=/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin

# your pool id hash
PoolID="342350284fd76ba9dbd7fd4ed579b2a2058d5ee558f8872b37817b28"

# get this from your account profile page on pooltool website
MyPooltoolApiKey="cd45c100-643a-43ee-b617-6a8bb9ef7721"

### Blockfrost APIs
bfKey=jsLX87IunMrsi3BsHenNlKHecq4CxlhJ

### Leader Logs Checker
PLATFORM="SNAKE sendLastBlockInfo"

### SSH Access to BP
dir=/cardano/cnode/scripts
bphost=$(cat $dir/.bphost)
pswd=$(cat $dir/.passwd)
port=$(cat $dir/.port)

while :
do

        blockInfo=$(curl -s https://cardano-mainnet.blockfrost.io/api/v0/blocks/latest -X GET -H "project_id: $bfKey")
        latestParams=$(curl -s https://cardano-mainnet.blockfrost.io/api/v0/epochs/latest/parameters -X GET -H "project_id: $bfKey")

        nodeVersion_out=$(/cardano/cnode/bin/cardano-node --version)
        nodeVersion=$(echo $nodeVersion_out | head -n 1 | cut -f 2 -d " ")

        nodeTip=$(echo         ${pswd}    | ssh nodo@${bphost} -p ${port}  'sudo -u tecnode -S /cardano/cnode/scripts/check_tip2pooltool.sh 2>/dev/null')
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

sleep 2

done
