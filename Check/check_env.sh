#!/usr/bin/env bash
source ../common.sh

#[MINER-/etc/profile]
#[MINER-config.json]
#[MINER-files]
#[WORKER-/etc/profile]
#[WORKER-files]

function do_check_pro_env() {
    vars=$@
    for tmp in ${vars}
    do
      value=$(eval "echo \${${tmp}}")
      echo "${tmp}=${value}"
    done
}

function do_check_conf_env() {
    vars=$@
    for tmp in ${vars}
    do
      value=$(grep ${tmp} ${json} |cut -d: -f2)
      echo "${tmp}=${value}"
    done
}

function do_check_file() {
    vars=$@
    for tmp in ${vars}
    do
      value=$(eval "echo \${${tmp}}")
      echo "${tmp}=${value}"
      if [ -f "${value}" ]; then
        echo "${value} exist"
      else
        echo "${value} not exist"
      fi
    done
}

function check_miner_pro_env() {
    log_info "checking env variables now which need to set in /etc/profile of miner ..."
    do_check_pro_env "${miner_pro_env}"
    echo ""
}

function check_miner_conf_env() {
    log_info "checking env variables now which need to set in config.json of miner ..."
    do_check_conf_env "${miner_conf_env}"
    echo ""
}

function check_miner_file() {
    log_info "checking files of miner ..."
    do_check_file "${miner_file_env}"
    echo ""
}

function check_worker_pro_env() {
    log_info "checking env variables now which need to set in /etc/profile of worker ..."
    do_check_pro_env "${worker_pro_env}"
    echo ""
}

function check_worker_file() {
    log_info "checking files of worker ..."
    do_check_file "${worker_file_env}"
    echo ""
}

function main() {
    type=$1
    if [ -z "${type}" ]; then
      echo "please run as: bash $0 [ miner | worker ]"
      exit 1
    elif [[ ${type} == "miner" ]]; then
      check_miner_pro_env
      check_miner_conf_env
      check_miner_file
    elif [[ ${type} == "worker" ]]; then
      check_worker_pro_env
      check_worker_file
    fi
}

conf=check_env.conf
json=/root/config.json
miner_pro_env=$(sed -n '/MINER-\/etc\/profile/,/MINER-config.json/p' ${conf} |grep -v ^$ |grep -v '^\[')
miner_conf_env=$(sed -n '/MINER-config.json/,/MINER-files/p' ${conf} |grep -v ^$ |grep -v '^\[')
miner_file_env=$(sed -n '/MINER-files/,/WORKER-\/etc\/profile/p' ${conf} |grep -v ^$ |grep -v '^\[')
worker_pro_env=$(sed -n '/WORKER-\/etc\/profile/,/WORKER-files/p' ${conf} |grep -v ^$ |grep -v '^\[')
worker_file_env=$(sed -n '/WORKER-files/,$p' ${conf} |grep -v ^$ |grep -v '^\[')

main $1
exit 0
