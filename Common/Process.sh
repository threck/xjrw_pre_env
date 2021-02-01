#!/usr/bin/env bash

LOCALDIR=$(cd $(dirname $0) && pwd && cd - &> /dev/null)
BASEDIR=$(cd ${LOCALDIR}/.. && pwd && cd - &> /dev/null)
source ${BASEDIR}/Common/Log.sh

function check_process_not_exist(){
  process=$1
  log_info "checking process: ${process}"
  pid=$(ps -ef |grep ${process} |grep -v grep |grep -v pre_env_2k_lotus_miner |awk -F' ' '{print $2}')
  if [ -z "${pid}" ]; then
    log_info "process [ ${process} ] not exist."
    return_value=0
  else
    log_warn "process [ ${process} ] exist."
    return_value=1
  fi
  return ${return_value}
}


