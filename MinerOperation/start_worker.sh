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

APP_PATH=/root
LOCAL_IP=$(ifconfig |grep 192.168 |awk '{printf $2}')
conf=$1
t=$(date +%Y%m%d%H%M%S)
type=$(echo ${conf##*/}|cut -d_ -f2)
mkdir -p /var/logs
log=/var/logs/worker_${type}.log.${t}
ln_log=${APP_PATH}/worker.log

# judge if there's a lotus-woker process
pid=$(ps -ef |grep lotus-woker |grep -v grep |awk -F' ' '{print $2}')
if [ -n "${pid}" ]; then
  log_info "there a lotus-woker[${type}] process [${pid}] found already."
  log_info "quit"
  exit 0
fi

# get launch param
port=$(grep -v '^ *#' ${conf} |grep "worker" |grep ${LOCAL_IP} |awk -F' ' '{print $3}' |cut -d'=' -f2)
addpiece=$(grep -v '^ *#' ${conf} |grep "worker" |grep ${LOCAL_IP} |awk -F' ' '{print $4}' |cut -d'=' -f2)
precommit1=$(grep -v '^ *#' ${conf} |grep "worker" |grep ${LOCAL_IP} |awk -F' ' '{print $5}' |cut -d'=' -f2)
precommit2=$(grep -v '^ *#' ${conf} |grep "worker" |grep ${LOCAL_IP} |awk -F' ' '{print $6}' |cut -d'=' -f2)
commit1=$(grep -v '^ *#' ${conf} |grep "worker" |grep ${LOCAL_IP} |awk -F' ' '{print $7}' |cut -d'=' -f2)
commit2=$(grep -v '^ *#' ${conf} |grep "worker" |grep ${LOCAL_IP} |awk -F' ' '{print $8}' |cut -d'=' -f2)
unseal=$(grep -v '^ *#' ${conf} |grep "worker" |grep ${LOCAL_IP} |awk -F' ' '{print $9}' |cut -d'=' -f2)
p1_delay=$(grep -v '^ *#' ${conf} |grep "worker" |grep ${LOCAL_IP} |awk -F' ' '{print $10}' |cut -d'=' -f2)
p2_delay=$(grep -v '^ *#' ${conf} |grep "worker" |grep ${LOCAL_IP} |awk -F' ' '{print $11}' |cut -d'=' -f2)
c1_delay=$(grep -v '^ *#' ${conf} |grep "worker" |grep ${LOCAL_IP} |awk -F' ' '{print $12}' |cut -d'=' -f2)
c2_delay=$(grep -v '^ *#' ${conf} |grep "worker" |grep ${LOCAL_IP} |awk -F' ' '{print $13}' |cut -d'=' -f2)

# run lotus-worker
cd ${APP_PATH}
log_info "launch worker[${type}] ..."
log_info "launch pram: ./lotus-worker run --listen=${LOCAL_IP}:${port}
--addpiece=${addpiece} --precommit1=${precommit1} --precommit2=${precommit2}
--commit1=${commit1} --commit2=${commit2} --unseal=${unseal}
--p1-delay ${p1_delay} --p2-delay ${p2_delay} --c1-delay ${c1_delay} --c2-delay ${c2_delay}"
log_info "lotus-worker[${type}] log: ${log}"
nohup ./lotus-worker run --listen=${LOCAL_IP}:${port} \
--addpiece=${addpiece} --precommit1=${precommit1} --precommit2=${precommit2} \
--commit1=${commit1} --commit2=${commit2} --unseal=${unseal} \
--p1-delay ${p1_delay} --p2-delay ${p2_delay} --c1-delay ${c1_delay} --c2-delay ${c2_delay}
&> ${log} &

# wait for launch
v1=1
while [ ${v1} -ne 0 ]; do
  sleep 1s
  grep 'Worker registered successfully, waiting for tasks' ${log} &> /dev/null
  if [ ${v1} -gt 300 ]; then
    log_err "timeout : waiting for launch lotus-worker[${type}] ${v1}s ..."
    exit 1
  fi
  if [ $? -eq 0 ]; then
    v1=0
    log_info "launch lotus-worker[${type}] ... success"
  else
    log_info "waiting for launch lotus-worker[${type}] ${v1}s ..."
    v1=$((v1+1))
  fi
done

# check lotus-worker pid
pid=$(ps -ef |grep lotus-worker |grep -v grep |awk -F' ' '{print $2}')
if [ -n "${pid}" ]; then
  log_info "lotus-worker[${type}] pid: ${pid}"
  exit_value=0
else
  log_err "can't get lotus-worker[${type}] pid."
  exit_value=1
fi

# set log soft link
rm -rf ${ln_log}
ln -s ${log} ${ln_log}

exit ${exit_value}