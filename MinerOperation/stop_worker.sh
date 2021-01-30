#!/usr/bin/env bash

LOCALDIR=$(cd $(dirname $0) && pwd && cd - &> /dev/null)
BASEDIR=$(cd ${LOCALDIR}/.. && pwd && cd - &> /dev/null)
source ${BASEDIR}/Common/Log.sh

# judge if there's a lotus-worker process
pid=$(ps -ef |grep lotus-worker |grep -v grep |awk '{print $2}')
if [ -z "${pid}" ]; then
  log_info "no lotus-worker process found."
  log_info "quit"
  exit 0
else
  log_info "lotus-worker process[${pid}] found"
fi

# kill lotus-worker
log_info "killing lotus-worker ..."
kill -9 ${pid}

# wait for stop lotus-worker
v1=1
while [ ${v1} -ne 0 ]; do
  sleep 1s
  worker_str=$(ps -ef |grep lotus-worker |grep -v grep)
  if [ -z "${worker_str}" ]; then
    v1=0
    log_info "killing lotus-worker ... success"
  else
    log_err "waiting for kill lotus-worker ${v1}s ..."
    v1=$((v1+1))
  fi
done
