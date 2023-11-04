<br/>
<br/>
1. Install last python version.
2. Install needed python libraries with "pip install -r pip-requirements.txt".
<br/>
<br/>
3.__config.json instructions:__
<br/>
<br/>
The send slots to pooltool.io part of pooltoolSendSlots.py, uses a configuration file, here named config.json which takes: pooltool api key, pool ticker, pool id in hash format, previous and current epoch with its N slots leaders (absolute slot values).
<br/>
<br/>
At each execution (once during the first 24hours of new epoch), epochs and slots are rotated.
<br/>
<br/>
You need to inform only once epochs/slots section with your information.
<br/>
<br/>
Pooltool.io will receive your current scheduled slots quantity and the hash deriveed from the concatenation of your previous epoch schedlued slots.
<br/>
<br/>
**config.json template**
{
    "api_key": "pooltool api key",
    "pools": [
        {
            "name": "TICKER",
            "pool_id": "POOL_ID HASH"
        }
    ],
    "saved_data": [
        {
            "epoch": 445,
            "slots": [
                107358789
            ]
        },
        {
            "epoch": 446,
            "slots": [
                103302799,
                102308799,
                107304799
            ]
        }
    ]
}
<br/>
<br/>
Edit **pooltoolSendSlots.py** and add needed variables.
<br/>
<br/>
Install libsodium
<br/>
<br/>
A systemd service is needed to run it, use pooltool_sendslots_daily_check.nix and pooltool_sendslots_daily_check.service files as reference for systemd service setup.
