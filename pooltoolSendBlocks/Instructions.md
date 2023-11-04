Edit **pooltoolSendBlocks.sh** and add needed variables, please read the script and its comments.
<br/>
Script takes lastSlot, lastBlockHash, lastBlockHeight values from your BP node by executing a remote ssh command from where you are executing it, a relay node for example.
<br/>
And blockTime, at, parentHash, blockVrf, slotLeader values of the same block from Koios API.
<br/>
Node version is sent too.
<br/>
A systemd service is needed to run it, use **pooltool_sendblocks.nix** and **pooltool_sendblocks.service** files as reference
for systemd service setup.
