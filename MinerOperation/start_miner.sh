#!/usr/bin/env bash

LOCALDIR=$(cd $(dirname $0) && pwd && cd - &> /dev/null)
BASEDIR=$(cd ${LOCALDIR}/.. && pwd && cd - &> /dev/null)
source ${BASEDIR}/Common/Log.sh

APP_PATH=/root
t=$(date +%Y%m%d%H%M%S)
ip=$(ifconfig |grep 192 |awk -F' ' '{print $2}')
log=${APP_PATH}/miner.log.${t}

# judge if there's a lotus-miner process
pid=$(ps -ef |grep lotus-miner |grep -v grep |awk -F' ' '{print $2}')
if [ -n "${pid}" ]; then
  log_info "there a lotus-miner process [${pid}] found already."
  log_info "quit"
  exit 0
fi

# launch lotus-miner
cd ${APP_PATH}
log_info "launch lotus-miner on ${ip} ..."
log_info "launch param: ./lotus-miner run --nosync ..."
nohup ./lotus-miner run --nosync &> ${log} &
log_info "lotus-miner logs: ${log}"

# wait for launch
v1=1
while [ ${v1} -ne 0 ]; do
  sleep 1s
  grep 'winning PoSt warmup successful' ${log} &> /dev/null
  if [ ${v1} -gt 300 ]; then
    log_err "timeout : waiting for launch lotus-miner ${v1}s ..."
    exit 1
  fi
  if [ $? -eq 0 ]; then
    v1=0
    log_info "launch lotus-miner ... success"
  else
    log_info "waiting for launch lotus-miner ${v1}s ..."
    v1=$((v1+1))
  fi
done

# check lotus-miner pid
pid=$(ps -ef |grep lotus-miner |grep -v grep |awk -F' ' '{print $2}')
if [ -n "${pid}" ]; then
  log_info "lotus-miner pid: ${pid}"
  exit 0
else
  log_err "can't get lotus-miner pid."
  exit 1
fi


