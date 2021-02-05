#!/usr/bin/env bash

LOCALDIR=$(cd $(dirname $0) && pwd && cd - &> /dev/null)

cd ${LOCALDIR}

type=$1

if [ -z "${type}" ]; then
  echo "please run as: bash $0 [ 2K | 32G | 64G | 64G2]"
  echo "e.g. bash $0 2K"
  exit 1
fi

bash stop_miner.sh ${type}
bash start_miner.sh ${type}
cd - &> /dev/null
