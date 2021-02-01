#!/bin/bash

LOCALDIR=$(cd $(dirname $0) && pwd && cd - &> /dev/null)
BASEDIR=$(cd ${LOCALDIR}/.. && pwd && cd - &> /dev/null)
source ${BASEDIR}/Common/NetWork.sh
source ${BASEDIR}/Common/FileDirectory.sh
source ${BASEDIR}/Common/Process.sh

APP_PATH=/root
LOCAL_IP=$(ifconfig |grep 192.168.0 |awk -F' ' '{print $2}')
conf_file=$1

# 1.check some env
log_info "===setup worker==="
[ -z "${LOTUS_WORKER_PATH}" ] && echo "env LOTUS_WORKER_PATH is null! please set it!" && exit 1
check_process_not_exist "lotus-worker"
if [ $? -ne 0 ]; then
  bash ${BASEDIR}/MinerOperation/stop_worker.sh
fi

# 2.cleaning lotusworker;
log_info "cleaning environment ..."
remove_directory "${LOTUS_WORKER_PATH}"
[ $? -ne 0 ] && exit 1


# 3.prepare 3 files: api, token, lotus-worker
miner_ip=$(grep -v '^ *#' ${conf_file} |grep "miner" |grep ${LOCAL_IP} |awk -F' ' '{print $2}' |cut -d'=' -f2)
mkdir -p ${LOTUS_STORAGE_PATH}

cp_from_remote ${miner_ip} ${M_USER} ${M_PWD} ${LOTUS_STORAGE_PATH}/api ${LOTUS_STORAGE_PATH}
cp_from_remote ${miner_ip} ${M_USER} ${M_PWD} ${LOTUS_STORAGE_PATH}/token ${LOTUS_STORAGE_PATH}
cp_from_remote ${miner_ip} ${M_USER} ${M_PWD} ${APP_PATH}/lotus-worker ${APP_PATH}

# 4.launch lotus-worker
bash ${BASEDIR}/MinerOperation/start_worker.sh ${conf_file}
[ $? -ne 0 ] && exit 1

