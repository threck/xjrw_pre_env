
pid=$(ps -ef |grep lotus-miner |grep -v grep |awk '{print $2}')
kill -9 ${pid}

cd /root
nohup ./lotus-miner run --nosync &> miner.log &
cd - &> /dev/null



#!/usr/bin/env bash

LOCALDIR=$(cd $(dirname $0) && pwd && cd - &> /dev/null)
BASEDIR=${LOCALDIR}/..
source ${BASEDIR}/common.sh
# restart miner
# finished

# get miner's param and pid
miner_start_str=$(ps -ef |grep lotus-miner |grep -v grep |awk -F'lotus|miner' '{print $3}')
log_info "get lotus-miner params: [ ${miner_start_str}]"
pid=$(ps -ef |grep lotus-miner |grep -v grep |awk '{print $2}')
log_info "get lotus-miner pid: [ ${pid}]"

# kill miner
log_info "killing lotus-miner ..."
kill -9 ${pid}
sleep 2s
miner_str=$(ps -ef |grep lotus-miner |grep -v grep)
if [ -n "${miner_str}" ]; then
  log_err "killing lotus-miner ... failed. please try again."
  exit 1
else
  log_info "killing lotus-miner ... success"
fi

# start miner
log_info "starting lotus-miner ..."
cd /root
nohup ./lotus-miner ${miner_start_str} &> miner.log &
sleep 2s
pid=$(ps -ef |grep lotus-miner |grep -v grep |awk '{print $2}')
if [ -z "${pid}" ]; then
  log_err "starting lotus-miner ... failed. please try again."
else
  log_info "starting lotus-miner ... success"
fi
cd - &> /dev/null


# to do:
#