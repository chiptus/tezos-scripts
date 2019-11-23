#!/bin/bash

# This is a helper script for adding more peers to an already
# running tezos-node. It first queries for, and adds all
# foundation nodes, then queries tzscan's API for more peers and
# adds them as well.
#
# The tezos-admin-client binary will output 'Error' messages in
# most cases, even when already connected to a peer.
#
# Be sure to install jq and configure the TZPATH variable below
# [yum|apt] install jq
#
# If you found this script helpful, send us a tip!
# Baking Tacos! tz1RV1MBbZMR68tacosb7Mwj6LkbPSUS1er1
#

newpeers=0

# get foundation nodes
for i in dubnodes franodes sinnodes nrtnodes pdxnodes; do
    for j in `dig $i.tzbeta.net +short`; do
      echo "Connecting foundation $j..."
      tezos-admin-client connect address [$j]:9732
      if [ $? -eq 0 ]; then
        ((newpeers++))
      #  echo "New connection to $j established"
      fi
    done
done

# Public Nodes
# Loop over pages from tzscan. Swap variable below for use on alphanet nodes.
#TZSCANAPI=api.alphanet.tzscan.io"
TZSCANAPI="api6.tzscan.io"

for page in {0..5}; do
  
  # get array of peers
  peers=($(curl -s "https://$TZSCANAPI/v3/network?state=running&p=$page&n=50" | jq -r '.[] | .point_id' | xargs))
  if [ ${#peers[@]} -eq 0 ]; then
    # exit loop, no results for page
    echo "No more peers found. Exiting."
    break
  fi
  
  # loop through peers array
  for i in ${peers[@]}; do

    # handle ipv4 or ipv6
    numparts=$(echo $i | awk -F: '{print NF}')
    basenum=$((numparts-1))
    port=$(echo $i | cut -d: -f$numparts)
    base=$(echo $i | cut -d: -f1-$basenum)
    formatted="[$base]:$port"

    echo "Connecting $formatted..."
    tezos-admin-client connect address $formatted
    if [ $? -eq 0 ]; then
      ((newpeers++))
    #  echo "New connection to $j established"
    fi
  done
done

# how many peers do we have now? how many did we add?
numpeers=$($TZPATH/tezos-admin-client p2p stat | grep "BETA\|MAINNET" | wc -l)
echo "Added $newpeers peers. Currently $numpeers connected. Done."
