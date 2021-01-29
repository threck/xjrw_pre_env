#!/usr/bin/env bash

LOCALDIR=$(cd $(dirname $0) && pwd && cd - &> /dev/null)

if [ -z "$1" ]; then
  echo "please run as: bash $0 [ jenkins_nodename ]"
  echo "e.g. bash $0 2k_miner_150"
  exit 1
fi
cd ${LOCALDIR}
bash stop_jenkins.sh
bash start_jenkins.sh $1
cd - &> /dev/null
