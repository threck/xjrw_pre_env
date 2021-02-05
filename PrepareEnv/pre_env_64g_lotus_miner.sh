#!/bin/bash

LOCALDIR=$(cd $(dirname $0) && pwd && cd - &> /dev/null)
BASEDIR=$(cd ${LOCALDIR}/.. && pwd && cd - &> /dev/null)
source ${BASEDIR}/Common/NetWork.sh
source ${BASEDIR}/Common/FileDirectory.sh
source ${BASEDIR}/Common/Process.sh

GENESIS_PATH=/root/.genesis-sectors
APP_PATH=/root
TMP=/tmp/${0##*/}.tmp
conf_file=$1

if [ -z "${conf_file}" ]; then
  echo "please run as: bash $0 [ conf_file ]"
  echo "e.g. bash $0 miner_cluster.150.conf"
  exit 1
fi

type=$(echo ${conf_file##*/}|cut -d_ -f2)
miner_ip=$(grep -v '^ *#' ${conf_file} |grep "miner" |awk -F' ' '{print $2}' |cut -d'=' -f2)
sed -i "s/miner_ip/${miner_ip}/g" ${conf_file}
source ${LOCALDIR}/profiles/profile_${type}_miner
# check env variables before initialize
bash ${BASEDIR}/Check/check_env.sh miner

# --initialize lotus daemon
log_info "===initialize lotus daemon==="
log_info "===cancel initialize lotus daemon on 64g environment ==="
# 1.check some env
log_info "check environment variables ..."
[ -z "${LOTUS_PATH}" ] && echo "env LOTUS_PATH is null! please set it!" && exit 1
[ -z "${LOTUS_STORAGE_PATH}" ] && echo "env LOTUS_STORAGE_PATH is null! please set it!" && exit 1
is_file_exist "${conf_file}"
[ $? -ne 0 ] && exit 1
check_process_not_exist "lotus-miner"
[ $? -ne 0 ] && exit 1

# 2.cleaning genesis_sectors;lotusdata;lotusminer;
log_info "cleaning environment ..."
  # remove data of lotusminer
remove_directory "${LOTUS_STORAGE_PATH}"
[ $? -ne 0 ] && exit 1

# --initialize miner
log_info "===initialize lotus miner==="
# 0_1.choose a wallet
wallet_addr=$(./lotus wallet list)

# 0_2.initialize miner
log_info "initialize miner ..."
./lotus-miner init --owner=${wallet_addr} --sector-size=64GiB 2>&1 |tee ${TMP}

grep "Miner successfully created" ${TMP} &> /dev/null
if [ $? -eq 0 ]; then
  log_info "initialize miner ... success"
else
  log_err "initialize miner ... failed"
  exit 1
fi
is_directory_exist "${LOTUS_STORAGE_PATH}"
[ $? -ne 0 ] && exit 1

# 1.modify .lotusminer/config.coml
miner_conf=${LOTUS_STORAGE_PATH}/config.toml
log_info "modify miner config file: ${miner_conf}"
m_ip=$(ifconfig |grep inet |grep -v 127 |awk '{printf $2}')
port=$(grep -v '^ *#' ${conf_file} |grep "miner" |awk -F' ' '{print $3}' |cut -d'=' -f2)
addpiece=$(grep -v '^ *#' ${conf_file} |grep "miner" |awk -F' ' '{print $4}' |cut -d'=' -f2)
precommit1=$(grep -v '^ *#' ${conf_file} |grep "miner" |awk -F' ' '{print $5}' |cut -d'=' -f2)
precommit2=$(grep -v '^ *#' ${conf_file} |grep "miner" |awk -F' ' '{print $6}' |cut -d'=' -f2)
commit1=$(grep -v '^ *#' ${conf_file} |grep "miner" |awk -F' ' '{print $7}' |cut -d'=' -f2)
commit2=$(grep -v '^ *#' ${conf_file} |grep "miner" |awk -F' ' '{print $8}' |cut -d'=' -f2)
unseal=$(grep -v '^ *#' ${conf_file} |grep "miner" |awk -F' ' '{print $9}' |cut -d'=' -f2)

sed -i "s/#  ListenAddress = \"\/ip4\/127.0.0.1/  ListenAddress = \"\/ip4\/${m_ip}/g" ${miner_conf}
sed -i "s/#  RemoteListenAddress = \"127.0.0.1:2345\"/  RemoteListenAddress = \"${m_ip}:${port}\"/g" ${miner_conf}
sed -i "s/#  AllowAddPiece = true/  AllowAddPiece = ${addpiece}/g" ${miner_conf}
sed -i "s/#  AllowPreCommit1 = true/  AllowPreCommit1 = ${precommit1}/g" ${miner_conf}
sed -i "s/#  AllowPreCommit2 = true/  AllowPreCommit2 = ${precommit2}/g" ${miner_conf}
sed -i "s/#  AllowCommit1 = true/  AllowCommit1 = ${commit1}/g" ${miner_conf}
sed -i "s/#  AllowCommit2 = true/  AllowCommit2 = ${commit2}/g" ${miner_conf}
log_info "content of miner config file: ${miner_conf}"
cat ${miner_conf}

# do run
bash ${BASEDIR}/MinerOperation/start_miner.sh $(echo ${conf_file}|cut -d_ -f2)
return_value=$?
log_info "pre_env_64g_lotus_miner.sh return value: ${return_value}"
exit ${return_value}


