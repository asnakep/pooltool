Edit **pooltoolSendBlocks.sh** and add needed variables, please read the script and its comments.
<br/><br/>
Script takes lastSlot, lastBlockHash, lastBlockHeight values from your BP node by executing a remote ssh command from where you are executing it, a relay node for example.
<br/><br/>
And blockTime, at, parentHash, blockVrf, slotLeader values of the same block from Koios API.
<br/><br/>
Node version is sent too.
<br/><br/>
A systemd service is needed to run it, use **pooltool_sendblocks.nix** and **pooltool_sendblocks.service** files as reference
for systemd service setup.
<br/><br/>
Mandatory parameters for this service are:
<br/><br/>
RemainAfterExit= "no";
<br/><br/>
Restart = "always";
