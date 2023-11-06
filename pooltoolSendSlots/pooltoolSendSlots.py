#!/bin/env python3

import requests
import urllib.request
from urllib.request import urlopen
import math
import binascii
import json
import argparse
import hashlib
import re
from ctypes import *
import sys
from os import system, path
import shutil
from datetime import datetime, timezone
from sys import exit, platform

### Send Slots to pooltool.io
### Change POOL_TICKER with your one.
PLATFORM = "POOL_TICKER - pooltoolSendSlots.py"
URL      = "https://api.pooltool.io/v0/sendslots"
VERSION  = "v1.0"

### Set These Variables ###
PoolIdBech    = ""
VrfKeyFile    = '/path_to/vrf.skey'
### -------------------------------------------------------------- ###

### Koios Headers and BaseURL ###
koiosHeaders = {'content-type': 'application/json'}
koiosBaseUrl = "https://api.koios.rest/api/v0/"

### Current Current Epoch number and epoch_slot for execution conditions ###
koiosTipUrl        = koiosBaseUrl+"tip"
request            = urllib.request.Request(koiosTipUrl, headers=koiosHeaders)
response           = urllib.request.urlopen(request).read()
tipData            = json.loads(response.decode('utf-8'))
epoch_slot         = int(tipData[0]['epoch_slot'])
epoch              = int(tipData[0]['epoch_no'])

## Important!
## The systemd service for this script checks everyday at 22:00UTC if a range of epoch_slots
## is available to run this script that calculates pool's scheduled blocks,
## and send the list of absolute_slots (your pool's slot leaders) to pooltool.io.
## Slots can be sent to pooltool.io during the first 24hours of a new epoch.

start_slot = 3600   # after one hour of new epoch
end_slot   = 85000 # 23minutes less than full 24hours value 86400 to leave a margin for its execution during the testing of the service.

## feel free to adjust start_slot and end_slot varables as per your preferences,
## taking into account the related systemd service time settings.


if epoch_slot >= start_slot and epoch_slot <= end_slot:

  ### Get Current Epoch Nonce ###
  koiosEpochParamUrl   = koiosBaseUrl+"epoch_params?_epoch_no="+str(epoch)
  request              = urllib.request.Request(koiosEpochParamUrl, headers=koiosHeaders)
  response             = urllib.request.urlopen(request).read()
  epochParamData       = json.loads(response.decode('utf-8'))
  eta0                 = epochParamData[0]['nonce']

  ### Get Current Pool Stake and Network Stake ###
  koiosPoolSnapshotUrl = koiosBaseUrl+"pool_stake_snapshot?_pool_bech32="+PoolIdBech
  request              = urllib.request.Request(koiosPoolSnapshotUrl, headers=koiosHeaders)
  response             = urllib.request.urlopen(request).read()
  poolStakeSnapData    = json.loads(response.decode('utf-8'))
  pStake               = int(poolStakeSnapData[1]['pool_stake'])
  nStake               = int(poolStakeSnapData[1]['active_stake'])

  ### Get Current Pool Sigma ###
  poolInfoUrl          = koiosBaseUrl+"pool_info"
  poolPostData         = {"_pool_bech32_ids":[PoolIdBech]}
  poolinfo             = requests.post(poolInfoUrl, data=json.dumps(poolPostData))
  poolinfo             = poolinfo.text
  poolinfo             = json.loads(poolinfo)
  sigma                = poolinfo[0]['sigma']

  ### Get Genesis Info Needed for Slots Calculation ###
  koiosGenesisUrl      = koiosBaseUrl+"genesis"
  request              = urllib.request.Request(koiosGenesisUrl, headers=koiosHeaders)
  response             = urllib.request.urlopen(request).read()
  networkGenesisData   = json.loads(response.decode('utf-8'))
  epochLength          = int(networkGenesisData[0]['epochlength'])
  activeSlotCoeff      = float(networkGenesisData[0]['activeslotcoeff'])

  ###################################################
  ### Start Current Epoch Leader Logs Computation ###
  
  # https://github.com/papacarp/pooltool.io/blob/master/leaderLogs/leaderLogs.py
  # leader logs proof of concept - all credit goes to
  # @andrewwestberg of BCSH,
  # @AC8998 (Antonio) of CSP
  # @iiLap (Pal Dorogi) of UNDR
  # for the algo extraction from cardano-node

  ### Opening vrf.skey file   ####
  with open(VrfKeyFile) as f:
          skey = json.load(f)
          pool_vrf_skey = skey['cborHex'][4:]

  ### Load libsodium library from /usr/local/lib/  ###
  libsodium = cdll.LoadLibrary("/usr/local/lib/libsodium.so")
  libsodium.sodium_init()

  ### Epoch211FirstSlot ###
  firstShelleyBlockHash = "33a28456a44277cbfb3457082467e56f16554932eb2a9eb7ceca97740bd4f4db"
  blockInfoUrl          = koiosBaseUrl+"block_info"
  postData              = {"_block_hashes":[firstShelleyBlockHash]}
  blockInfo             = requests.post(blockInfoUrl, data=json.dumps(postData))
  blockInfo             = blockInfo.text
  blockInfo             = json.loads(blockInfo)
  firstSlot             = blockInfo[0]['abs_slot']

  ### calculate first slot of target epoch ###
  firstSlotOfEpoch = (firstSlot) + (epoch - 211)*epochLength


  # Determine if our pool is a slot leader for this given slot
  # @param slot The slot to check
  # @param activeSlotCoeff The activeSlotsCoeff value from protocol params
  # @param sigma The controlled stake proportion for the pool
  # @param eta0 The epoch nonce value
  # @param pool_vrf_skey The vrf signing key for the pool

  from decimal import *
  getcontext().prec = 9
  getcontext().rounding = ROUND_HALF_UP

  def mk_seed(slots, eta0):
      h = hashlib.blake2b(digest_size=32)
      h.update(slots.to_bytes(8, byteorder='big') + binascii.unhexlify(eta0))
      slotToSeedBytes = h.digest()

      return slotToSeedBytes

  def vrf_eval_certified(seed, praosCanBeLeaderSignKeyVRF):
      if isinstance(seed, bytes) and isinstance(praosCanBeLeaderSignKeyVRF, bytes):
          proof = create_string_buffer(libsodium.crypto_vrf_ietfdraft03_proofbytes())
          libsodium.crypto_vrf_prove(proof, praosCanBeLeaderSignKeyVRF, seed, len(seed))
          proof_hash = create_string_buffer(libsodium.crypto_vrf_outputbytes())
          libsodium.crypto_vrf_proof_to_hash(proof_hash, proof)

          return proof_hash.raw
      else:
          print("Error.  Feed me bytes")
          sys.exit()

  def vrf_leader_value(vrfCert):
      h = hashlib.blake2b(digest_size=32)
      h.update(str.encode("L"))
      h.update(vrfCert)
      vrfLeaderValueBytes = h.digest()

      return int.from_bytes(vrfLeaderValueBytes, byteorder="big", signed=False)

  def isOverlaySlot(firstSlotOfEpoch, currentSlot, decentralizationParam):
      diff_slot = float(currentSlot - firstSlotOfEpoch)
      left = Decimal(diff_slot) * Decimal(decentralizationParam)
      right = Decimal(diff_slot + 1) * Decimal(decentralizationParam)
      if math.ceil(left) < math.ceil(right):
          return True
      return False

      if slotscount == 0:
          print("No SlotLeader Schedules Found for Epoch: " +str(epoch))
          sys.exit()

  ### For Epochs inside Praos Time ###
  if float(epoch) >= 364:
      def is_slot_leader(slots, activeSlotsCoeff, sigma, eta0, pool_vrf_skey):
          seed = mk_seed(slots, eta0)
          praosCanBeLeaderSignKeyVRFb = binascii.unhexlify(pool_vrf_skey)
          cert = vrf_eval_certified(seed, praosCanBeLeaderSignKeyVRFb)
          certLeaderVrf = vrf_leader_value(cert)
          certNatMax = math.pow(2, 256)
          denominator = certNatMax - certLeaderVrf
          q = certNatMax / denominator
          c = math.log(1.0 - activeSlotsCoeff)
          sigmaOfF = math.exp(-sigma * c)

          return q <= sigmaOfF

      slotscount=0

      for slots in range(firstSlotOfEpoch,epochLength+firstSlotOfEpoch):

          slotLeader = is_slot_leader(slots, activeSlotCoeff, sigma, eta0, pool_vrf_skey)

          seed = mk_seed(slots, eta0)
          praosCanBeLeaderSignKeyVRFb = binascii.unhexlify(pool_vrf_skey)
          cert = vrf_eval_certified(seed,praosCanBeLeaderSignKeyVRFb)
          certLeaderVrf = vrf_leader_value(cert)
          certNatMax = math.pow(2,256)
          denominator = certNatMax - certLeaderVrf
          q = certNatMax / denominator
          c = math.log(1.0 - activeSlotCoeff)
          sigmaOfF = math.exp(-sigma * c)

          ### End Current Epoch Leader Logs Computation ###
          #################################################
          
          if slotLeader:
              pass
              timestamp = datetime.fromtimestamp(slots + 1591566291)
              slotscount+=1

              blocksEpoch = 21600
              epoch_luck = int((100 * slotscount) / (blocksEpoch * pStake / nStake / 1000000))


      ### write slots count and epoch luck to prometheus textfile metrics
      ### uncomment below line if you intend to use it
      #def write_prometheus_metric(file_path, metric_name, value):
      #  try:
      #    with open(file_path, 'w') as file:
      #        file.write(f'{metric_name} {value}\n')
      #  finally:
      #        file.close()


      file_path = "/var/lib/prometheus-node-exporter-text-files/assignedblocks.prom"
      metric_name = "pool_assignedblocks"
      value = slotscount
      write_prometheus_metric(file_path, metric_name,  value)

      file_path = "/var/lib/prometheus-node-exporter-text-files/assignedluck.prom"
      metric_name = "pool_assignedluck"
      value = epoch_luck
      write_prometheus_metric(file_path, metric_name,  value)


  ### Send Slots to pooltool.io
  def postPooltool(content):
      try:
          newHeaders = {'Content-type': 'application/json', 'Accept': 'Accept: application/json'}
          response = requests.post(URL, data=content, headers=newHeaders)
          requests.post(URL)
          response.raise_for_status()
      except requests.exceptions.HTTPError as errh:
          print(ec, "Http Error: " + repr(errh))
          sys.exit()
      except requests.exceptions.ConnectionError as errc:
          print(ec,+ "Error Connecting: " + repr(errc))
          sys.exit()
      except requests.exceptions.Timeout as errt:
          print(ec, + "Timeout Error: " + repr(errt))
          sys.exit()
      except requests.exceptions.RequestException as err:
          print(ec, + "OOps: Something Else " + repr(err))
          sys.exit()
      finally:
          return response;

  def getconfig(configfile):
      with open(configfile) as f:
          data = json.load(f)
      return data;

  def writeconfig(configfile, configjson):
      try:
          with open(configfile, 'w') as f:
              f.write(json.dumps(configjson, indent=4))
      except Exception as e:
          print("Error writing config file: " + str(e))
          sys.exit(1)
      return 0

  def parse_query(slots):
      slot_list = []
      value = int(slots)
      slot_list.append(value)
      return slot_list


  parser = argparse.ArgumentParser(description="sendslots to pooltool.io")
  parser.add_argument("-c", "--config", type=str, nargs='?', help="path to config file in json format")
  parser.add_argument("-d", "--debug", help="prints debugging information", action="store_true")
  args = parser.parse_args()

  if args.debug:
      print("Debugging enabled")
      print_debug = True
  else:
      print_debug = False

  if args.config:
          print("Config file path: " + args.config)
          my_config = getconfig(args.config)
          api_key   = my_config['api_key']
          poolID    = my_config['pools'][0]['pool_id']
  else:
          print("ERROR: please provide a config file!")
          sys.exit(1)

  if print_debug:
          print("Data to pooltool.io")
          print()
          print("\tAPI key "    + api_key)
          print("\tpool ID "    + poolID )
          print("\tsaved_data " + str(my_config['saved_data']))

  epoch1 = my_config['saved_data'][0]['epoch']
  epoch2 = my_config['saved_data'][1]['epoch']

  if ((epoch-1) > epoch1):
          my_config['saved_data'][0]['epoch'] = epoch - 1
          if (epoch2 == (epoch-1)):
                  my_config['saved_data'][0]['slots'] = my_config['saved_data'][1]['slots']
          else:
                  my_config['saved_data'][0]['slots'] = []
  if (epoch > epoch2):
          slot_list = parse_query(slots)
          if print_debug:
                  print("DEBUG: current list of slots " + str(slot_list))
          my_config['saved_data'][1]['epoch'] = epoch
          my_config['saved_data'][1]['slots'] = slot_list

  writeconfig(args.config,my_config)

  print()
  print("Config File Has Been Updated")
  print()

  ### Pack JSON Info for pooltool.io
  message = {}
  message["apiKey"]  = api_key
  message["poolId"]  = poolID
  message["epoch"]   = epoch
  message["slotQty"] = len(my_config['saved_data'][1]['slots'])
  slotsstring        = json.dumps(my_config['saved_data'][1]['slots'],separators=(',', ':'))

  ## generate hash to be included in json message for pooltool.io
  h=hashlib.blake2b(digest_size=32)
  h.update(slotsstring.encode())
  hresult=h.hexdigest()

  message["hash"]      = str(hresult)
  message["prevSlots"] = json.dumps(my_config['saved_data'][0]['slots'],separators=(',', ':'))

  ### Send data to pooltool.io
  if print_debug:
          print(json.dumps(message))
          response = postPooltool(json.dumps(message))
  if print_debug:
          print("pooltool.io response: " + str(response.json()))


else:

  print("Leader Slots can be sent in epoch_slot range [3600..86000]")
  sys.exit()
