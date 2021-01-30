#!/bin/bash

LOCALDIR=$(cd $(dirname $0) && pwd && cd - &> /dev/null)
BASEDIR=$(cd ${LOCALDIR}/.. && pwd && cd - &> /dev/null)
source ${BASEDIR}/Common/NetWork.sh

# 0. check cluster network
# check param
if [ -z "$1" ]; then
  echo "please run as: bash $0 [ miner_ip ]"
  echo "e.g. bash $0 192.168.0.150"
  exit 1
fi

# check cluster network
miner_ip=$1
conf_file=${LOCALDIR}/pre_env_2k.$(echo ${miner_ip} |cut -d. -f4).conf
cluster_list=$(grep -v '^ *#' ${conf_file} |grep -E "worker|miner" |awk -F' ' '{print $2}'|cut -d'=' -f2)
check_network_connection "${cluster_list}"
[ $? -ne 0 ] && exit 1

# 1. copy miner_pre script to miner_ip
miner_ip=$(grep -v '^ *#' ${conf_file} |grep "miner" |awk -F' ' '{print $2}'|cut -d'=' -f2)
ssh ${miner_ip} "mkdir -p ${LOCALDIR}"
scp_to ${LOCALDIR}/pre_env_2k_lotus_miner.sh ${miner_ip} ${LOCALDIR}
scp_to ${LOCALDIR}/${conf_file} ${miner_ip} ${LOCALDIR}
scp_to ${BASEDIR}/MinerOperation ${miner_ip} ${BASEDIR}/MinerOperation

# 2. run miner_pre script
ssh ${miner_ip} "bash ${LOCALDIR}/pre_env_2k_lotus_miner.sh ${conf_file}"
[ $? -ne 0 ] && exit 1

# 3. copy worker_pre script to worker_ip
exit_value=0
worker_ip=$(grep -v '^ *#' ${conf_file} |grep "worker" |awk -F' ' '{print $2}'|cut -d'=' -f2)
for worker in ${worker_ip}; do
  ssh ${worker} "mkdir -p ${LOCALDIR}"
  scp_to ${LOCALDIR}/pre_env_2k_worker.sh ${worker} ${LOCALDIR}
  scp_to ${LOCALDIR}/${conf_file} ${worker} ${LOCALDIR}
  scp_to ${BASEDIR}/MinerOperation ${worker} ${BASEDIR}/MinerOperation
  # 4. run worker_pre script
  ssh ${worker} "bash ${LOCALDIR}/pre_env_2k_worker.sh ${conf_file}"
  v=$?
  exit_value=$((exit_value+v))
done

exit ${exit_value}
