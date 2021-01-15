#!/usr/bin/env bash
# send 6 tasks every 420s

while true
do
sleep 420s
for ((i=1;i<=6;i++))
do
  echo "send ${i} task ..."
  /root/lotus-miner sectors pledge
done
done
