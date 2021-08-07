#!/bin/bash

LOCALDIR=$(cd $(dirname $0) && pwd && cd - &> /dev/null)
BASEDIR=$(cd ${LOCALDIR}/.. && pwd && cd - &> /dev/null)
source ${BASEDIR}/Common/NetWork.sh
source ${BASEDIR}/Common/FileDirectory.sh

# 0. check cluster network
# check param
if [ -z "$1" ]; then
  echo "please run as: bash $0 [ conf_file ]"
  echo "e.g. bash $0 cluster_2K_150.conf"
  exit 1
fi
[ -z "${M_USER}" ] && echo "env M_USER is null! please set it!" && exit 1
[ -z "${M_PWD}" ] && echo "env M_PWD is null! please set it!" && exit 1

# check cluster network
conf_file=${LOCALDIR}/${1##*/}
is_file_exist "${conf_file}"
miner_ip=$(grep -v '^ *#' ${conf_file} |grep "miner" |awk -F' ' '{print $2}'|cut -d'=' -f2)
worker_ip=$(grep -v '^ *#' ${conf_file} |grep "worker" |awk -F' ' '{print $2}'|cut -d'=' -f2)
log_info "cluster miner: ${miner_ip}"
log_info "cluster worker: ${worker_ip}"
cluster_list=$(grep -v '^ *#' ${conf_file} |grep -E "worker|miner" |awk -F' ' '{print $2}'|cut -d'=' -f2)
check_network_connection "${cluster_list}"
[ $? -ne 0 ] && exit 1

# 1. copy miner_pre script to miner_ip
log_info "prepare for cluster-miner : ${miner_ip}..."
type=$(echo $1|cut -d_ -f2)
run_command_remote ${miner_ip} ${M_USER} ${M_PWD} "mkdir -p ${LOCALDIR}"
[ $? -ne 0 ] && exit 1
sync_to_remote ${LOCALDIR}/pre_env_2k_lotus_miner.sh ${miner_ip} ${M_USER} ${M_PWD} ${LOCALDIR}
[ $? -ne 0 ] && exit 1
sync_to_remote ${conf_file} ${miner_ip} ${M_USER} ${M_PWD} ${LOCALDIR}
[ $? -ne 0 ] && exit 1
sync_to_remote ${LOCALDIR}/profiles/profile_${type}_miner ${miner_ip} ${M_USER} ${M_PWD} ${LOCALDIR}/profiles/
[ $? -ne 0 ] && exit 1
sync_to_remote ${BASEDIR}/MinerOperation/ ${miner_ip} ${M_USER} ${M_PWD} ${BASEDIR}/MinerOperation
[ $? -ne 0 ] && exit 1
sync_to_remote ${BASEDIR}/Common/ ${miner_ip} ${M_USER} ${M_PWD} ${BASEDIR}/Common
[ $? -ne 0 ] && exit 1
sync_to_remote ${BASEDIR}/Check/ ${miner_ip} ${M_USER} ${M_PWD} ${BASEDIR}/Check
[ $? -ne 0 ] && exit 1

# 2. run miner_pre script
run_command_remote ${miner_ip} ${M_USER} ${M_PWD} "bash -l ${LOCALDIR}/pre_env_2k_lotus_miner.sh ${conf_file}"
[ $? -ne 0 ] && exit 1

# 3. copy worker_pre script to worker_ip
function pre_2k_env() {
    worker_ip_tmp=$1
    log_info "prepare for cluster-worker: ${worker_ip_tmp} ..."
    exit_value=0
    run_command_remote ${worker_ip_tmp} ${M_USER} ${M_PWD} "mkdir -p ${LOCALDIR}"
    ((exit_value=exit_value+$?))
    sync_to_remote ${LOCALDIR}/pre_env_2k_worker.sh ${worker_ip_tmp} ${M_USER} ${M_PWD} ${LOCALDIR}
    ((exit_value=exit_value+$?))
    sync_to_remote ${conf_file} ${worker_ip_tmp} ${M_USER} ${M_PWD} ${LOCALDIR}
    ((exit_value=exit_value+$?))
    sync_to_remote ${LOCALDIR}/profiles/profile_${type}_worker ${worker_ip_tmp} ${M_USER} ${M_PWD} ${LOCALDIR}/profiles/
    ((exit_value=exit_value+$?))
    sync_to_remote ${BASEDIR}/MinerOperation/ ${worker_ip_tmp} ${M_USER} ${M_PWD} ${BASEDIR}/MinerOperation
    ((exit_value=exit_value+$?))
    sync_to_remote ${BASEDIR}/Common/ ${worker_ip_tmp} ${M_USER} ${M_PWD} ${BASEDIR}/Common
    ((exit_value=exit_value+$?))
    sync_to_remote ${BASEDIR}/Check/ ${worker_ip_tmp} ${M_USER} ${M_PWD} ${BASEDIR}/Check
    ((exit_value=exit_value+$?))
    # 4. run worker_pre script
    run_command_remote ${worker_ip_tmp} ${M_USER} ${M_PWD} "bash -l ${LOCALDIR}/pre_env_2k_worker.sh ${conf_file}"
    ((exit_value=exit_value+$?))
    return ${exit_value}
}

exit_value=0
pids=""
rm -rf ${LOCALDIR}/pid_ip_relation.tmp
for worker_ip_tmp in ${worker_ip}; do
    pre_2k_env ${worker_ip_tmp} &
    pid=$!
    echo "${pid} ${worker_ip_tmp}" >> ${LOCALDIR}/pid_ip_relation.tmp
    pids=$(echo "${pids} ${pid}")
done

for pid in ${pids}
do
    ip_tmp=$(grep "^${pid} " ${LOCALDIR}/pid_ip_relation.tmp |awk '{print $2}')
    wait ${pid}
    [ $? -ne 0 ] && log_info "init worker [ ${ip_tmp} ] failed." || log_info "init worker [ ${ip_tmp} ] success."
done

log_info "pre_env_2k.sh return value: ${exit_value}"
exit ${exit_value}
