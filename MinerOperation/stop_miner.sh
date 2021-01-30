#!/usr/bin/env bash

LOCALDIR=$(cd $(dirname $0) && pwd && cd - &> /dev/null)
BASEDIR=$(cd ${LOCALDIR}/.. && pwd && cd - &> /dev/null)
source ${BASEDIR}/Common/Log.sh

# judge if there's a lotus-miner process
pid=$(ps -ef |grep lotus-miner |grep -v grep |awk '{print $2}')
if [ -z "${pid}" ]; then
  log_info "no lotus-miner process found."
  log_info "quit"
  exit 0
else
  log_info "lotus-miner process[${pid}] found"
fi

# kill lotus-miner
log_info "killing lotus-miner ..."
kill -9 ${pid}

# wait for stop lotus-miner
v1=1
while [ ${v1} -ne 0 ]; do
  sleep 1s
  miner_str=$(ps -ef |grep lotus-miner |grep -v grep)
  if [ -z "${miner_str}" ]; then
    v1=0
    log_info "killing lotus-miner ... success"
  else
    log_err "waiting for kill lotus-miner ${v1}s ..."
    v1=$((v1+1))
  fi
done
