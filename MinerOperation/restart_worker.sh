#!/usr/bin/env bash

LOCALDIR=$(cd $(dirname $0) && pwd && cd - &> /dev/null)
BASEDIR=$(cd ${LOCALDIR}/.. && pwd && cd - &> /dev/null)
source ${BASEDIR}/Common/Log.sh

if [ -z "$1" ]; then
  echo "please run as: bash $0 [ config_file ]"
  echo "e.g. bash $0 pre_env_2k.150.conf"
  exit 1
elif [ ! -f "$1" ]; then
  log_err "$1 is not exist!! check please!"
  exit 1
fi

cd ${LOCALDIR}
bash stop_worker.sh
bash start_worker.sh $1
cd - &> /dev/null

