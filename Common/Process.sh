#!/usr/bin/env bash

LOCALDIR=$(cd $(dirname $0) && pwd && cd - &> /dev/null)
BASEDIR=$(cd ${LOCALDIR}/.. && pwd && cd - &> /dev/null)
source ${BASEDIR}/Common/Log.sh

function check_process_not_exist(){
  process=$1
  pid=$(ps -ef |grep ${process} |grep -v grep |awk -F' ' '{print $2}')
  if [ -n "${pid}" ]; then
    log_info "process [ ${process} ] not exist."
    return_value=0
  else
    log_err "process [ ${process} ] exist."
    return_value=1
  fi
  return ${return_value}
}


