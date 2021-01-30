#!/usr/bin/env bash

LOCALDIR=$(cd $(dirname $0) && pwd && cd - &> /dev/null)

cd ${LOCALDIR}
bash stop_miner.sh
bash start_miner.sh
cd - &> /dev/null
