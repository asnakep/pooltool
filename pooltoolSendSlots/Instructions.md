Edit **config.json** once to add pool_id, pooltool api key, previous and current epoch, and your slots leader for previous and current epoch.
<br/>
Install python libraries with "pip install -t pip-requirements.txt".
<br/>
<br/>
Edit **pooltoolSendSlots.py** and add needed variables.
<br/>
<br/>
Install libsodium
<br/>
<br/>
A systemd service is needed to run it, use pooltool_sendslots_daily_check.nix and pooltool_sendslots_daily_check.service files as reference for systemd service setup.
