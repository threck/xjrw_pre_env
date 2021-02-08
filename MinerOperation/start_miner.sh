#!/usr/bin/env bash

LOCALDIR=$(cd $(dirname $0) && pwd && cd - &> /dev/null)
BASEDIR=$(cd ${LOCALDIR}/.. && pwd && cd - &> /dev/null)
source ${BASEDIR}/Common/Log.sh

type=$(echo ${1##*/}|cut -d_ -f2)
if [ -z "${type}" ]; then
  echo "please run as: bash $0 [ 2K | 32G | 64G | 64G2]"
  echo "e.g. bash $0 2K"
  exit 1
fi

APP_PATH=/root
t=$(date +%Y%m%d%H%M%S)
ip=$(ifconfig |grep 192 |awk -F' ' '{print $2}')
mkdir -p /var/logs
log=/var/logs/miner_${type}.log.${t}
ln_log=${APP_PATH}/miner.log

# judge if there's a lotus-miner process
miner_pid=$(grep MINER_PID_${type} /etc/profile |awk -F'=' '{print $2}')
if [ -n "${miner_pid}" ]; then
# judge if there's a lotus-miner process
  pid=$(ps -ef |grep lotus-miner |grep -v grep |awk '{print $2}' |grep ${miner_pid})
  if [ -n "${pid}" ]; then
    log_err "lotus-miner[${type}] process[${pid}] found"
    exit 1
  else
    log_info "no lotus-miner[${type}] process found"
  fi
fi


# launch lotus-miner
cd ${APP_PATH}
log_info "launch lotus-miner[${type}] on ${ip} ..."
if [ ${type} = "2K" ]; then
  log_info "launch param: ./lotus-miner run --nosync ..."
  nohup ./lotus-miner run --nosync &> ${log} &
  pid=$!
else
  log_info "launch param: ./lotus-miner run ..."
  nohup ./lotus-miner run &> ${log} &
  pid=$!
fi
log_info "lotus-miner pid: ${pid}"
log_info "lotus-miner logs: ${log}"

# wait for launch
v1=1
while [ ${v1} -ne 0 ]; do
  sleep 1s
  if [ ${type} = "2K" ]; then
    grep 'winning PoSt warmup successful' ${log} &> /dev/null
  else
    grep 'skipping winning PoSt warmup, no sectors' ${log} &> /dev/null
  fi
  if [ $? -eq 0 ]; then
    v1=0
    cat ${log}
    log_info "launch lotus-miner ... over"
  else
    log_info "waiting for launch lotus-miner ${v1}s ..."
    v1=$((v1+1))
  fi
  if [ ${v1} -gt 360 ]; then
    cat ${log}
    log_err "timeout : waiting for launch lotus-miner ${v1}s ..."
    exit 1
  else
    grep -v 'nvidia' ${log} |grep 'ERROR:' &> /dev/null
    if [ $? -eq 0 ]; then
      cat ${log}
      log_err "launch lotus-miner ... failed"
      exit 1
    fi
  fi
done

# check lotus-miner pid
ps -ef |grep lotus-miner |grep -v grep |awk -F' ' '{print $2}' |grep ${pid} &> /dev/null
if [ $? -eq 0 ]; then
  log_info "lotus-miner pid: ${pid}"
  log_info "launch lotus-miner ... success"
  exit_value=0
else
  log_err "can't get lotus-miner pid."
  log_info "launch lotus-miner ... failed"
  exit_value=1
fi

# add miner pid environment to /etc/profile
grep MINER_PID_${type}= /etc/profile &> /dev/null
if [ $? -ne 0 ]; then
  sed -i "\$aexport MINER_PID_${type}=${pid}" /etc/profile
else
  sed -i "s/MINER_PID_${type}=.*$/MINER_PID_${type}=${pid}/g" /etc/profile
fi

# set log soft link
rm -rf ${ln_log}
ln -s ${log} ${ln_log}

exit ${exit_value}

