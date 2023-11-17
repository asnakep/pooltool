<br/>
1. Install latest python version.
<br/><br/>
2. Install needed python libraries with "pip install -r pip-requirements.txt".
<br/><br/>
3. config.json instructions:
<br/><br/>
The send slots to pooltool.io part of pooltoolSendSlots.py, uses a configuration file, here named config.json which takes: pooltool api key, pool ticker, pool id in hash format, previous and current epoch with its N slots leaders (absolute slot values).
<br/><br/>
At each execution (once during the first 24hours of new epoch), epochs and slots are rotated by updating config.json 
<br/><br/>
You need to inform only once prev/curr epochs/slots section with your information.
<br/><br/>
Pooltool.io will receive your current scheduled slots quantity and the hash derived from the concatenation of your previous epoch scheduled slots separated by comma.
<br/><br/>
**config.json template**
<br/><br/>
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
                103308797,
                104309799,
                105310799
            ]
        }
    ]
}
<br/><br/>
4. Edit pooltoolSendSlots.py and add needed variables:
<br/><br/>
line 22.  PLATFORM = "YOUR_POOL_TICKER - pooltoolSendSlots.py"
<br/><br/>
line 26.  PoolIdBech    = ""
<br/><br/>
line 27.  VrfKeyFile    = '/path_to/vrf.skey'
<br/><br/>
5. Clone libsodium from github.com/input-output-hk
<br/><br/>
git clone https://github.com/input-output-hk/libsodium.git
<br/><br/>
cd libsodium
<br/><br/>
ensure you're in the branch iquerejeta/vrf_batchverify with git branch
<br/><br/>
./autogen.sh
<br/><br/>
./configure
<br/><br/>
make
<br/><br/>
sudo make install
<br/><br/>
6. A systemd service is needed to run pooltoolSendSlots.py using pooltoolSendSlots.sh.
<br/><br/>
Please use pooltool_sendslots_daily_check.nix and pooltool_sendslots_daily_check.service files as reference for systemd service setup.
<br/><br/>
Take into account that following parameters are mandatory for this service:
<br/><br/>
RemainAfterExit=no
<br/><br/>
Restart=no
<br/><br/>
8. uncomment the lines 205-210 of pooltoolSendSlots.py if you want to use a function that creates a prometheus-text-file type metric for assigned slots quantity.
<br/><br/>
You'll need to configure prometheus-text-file exporter for this.
<br/><br/>
