#!/bin/bash
function log_info() {
  echo $(date '+%Y-%m-%d %H:%M:%S')" [INFO] - $1"
}

function log_err() {
  echo $(date '+%Y-%m-%d %H:%M:%S')" [ERROR] - $1"
}


function scp_with_log(){
  ip=$1
  source_file=$2
  target_file=$3
  log_info "scp ${source_file} ${ip}:${target_file} ..."
  scp ${source_file} ${ip}:${target_file}
  ssh ${ip} "ls ${target_file}"
  [ $? -eq 0 ] && log_info "scp ${source_file} ${ip}:${target_file} ... success"
}