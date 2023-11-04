**pooltoolSendSlots:** python script to get stakepool slot leaders and send them to pooltool.io.\
<br/>
Needed to display assigned blocks and assigned performance in pooltool.io
<br/>
<br/>
This work comes from the merge and reworking of:
<br/>
<br/>
https://github.com/asnakep/YaLL
<br/>
<br/>
(Interactive Slot Leader checker for previous, current and next epoch using Koios API)
<br/>
<br/>
https://github.com/Josef3110/stakepool_python_tools/blob/main/scripts/sendslots.py 
<br/>
<br/>
(Gets slots schedule using "cardano-cli query leadership-schedule" and send the slots to pooltool.io)
<br/>
<br/>
**pooltoolSendBlocks:** bash script to send blocks information (send tip) to pooltool.io.\
<br/>
Needed to show your stakepool liveness (green highlighted last block height of block producer)\
of your stakepool section and for pooltool.io network analysis.
