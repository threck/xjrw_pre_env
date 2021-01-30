#!/usr/bin/env bash

LOCALDIR=$(cd $(dirname $0) && pwd && cd - &> /dev/null)
BASEDIR=$(cd ${LOCALDIR}/.. && pwd && cd - &> /dev/null)
source ${BASEDIR}/Common/Log.sh

function scp_to(){
  source_file=$1
  ip=$2
  target_file=$3
  return_value=0
  log_info "scp ${source_file} ${ip}:${target_file} ..."
  scp ${source_file} ${ip}:${target_file}
  ssh ${ip} "ls ${target_file}"
  if [ $? -eq 0 ]; then
    log_info "scp ${source_file} ${ip}:${target_file} ... success"
  else
    log_err "scp ${source_file} ${ip}:${target_file} ... failed"
    return_value=1
  fi
  return ${return_value}
}

function scp_from(){
  ip=$1
  source_file=$2
  target_file=$3
  return_value=0
  log_info "scp ${ip}:${source_file} ${target_file} ..."
  scp ${ip}:${source_file} ${target_file}
  ls ${target_file}
  if [ $? -eq 0 ]; then
    log_info "scp ${ip}:${source_file} ${target_file} ... success"
  else
    log_err "scp ${ip}:${source_file} ${target_file} ... failed"
    return_value=1
  fi
  return ${return_value}
}

function check_network_connection() {
  ip_list=$@
  return_value=0
  log_info "checking connection to: [ ${ip_list} ]"
  for ip in ${ip_list}; do
    log_info "ping ${ip} ..."
    ping ${ip} -c 4 &> /dev/null
    if [ $? -eq 0 ]; then
      log_info "ping ${ip} ... network good."
      return_value=$((return_value+0))
    else
      log_err "ping ${ip} ... failed. check your network please!!"
      return_value=$((return_value+1))
    fi
  done
  return ${return_value}
}