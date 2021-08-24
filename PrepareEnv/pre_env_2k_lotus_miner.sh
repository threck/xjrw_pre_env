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
  echo "e.g. bash $0 cluster_2K_150.conf"
  exit 1
fi

miner_ip=$(grep -v '^ *#' ${conf_file} |grep "miner" |awk -F' ' '{print $2}' |cut -d'=' -f2)
type=$(echo ${conf_file##*/}|cut -d_ -f2)
sed -i "s/miner_ip/${miner_ip}/g" ${LOCALDIR}/profiles/profile_${type}_miner
source ${LOCALDIR}/profiles/profile_${type}_miner
cp ${LOCALDIR}/profiles/profile_${type}_miner /etc/
mkdir -p ${TMPDIR}
echo "mkdir -p ${TMPDIR}"

# check env variables before initialize
bash ${BASEDIR}/Check/check_env.sh miner

# --initialize lotus daemon
log_info "===initialize lotus daemon==="

# 1.check some env
log_info "check environment variables ..."
[ -z "${LOTUS_PATH}" ] && echo "env LOTUS_PATH is null! please set it!" && exit 1
[ -z "${LOTUS_STORAGE_PATH}" ] && echo "env LOTUS_STORAGE_PATH is null! please set it!" && exit 1
my_pkill "lotus"
[ $? -ne 0 ] && exit 1
is_file_exist "${conf_file}"
[ $? -ne 0 ] && exit 1
check_process_not_exist "lotus-miner run"
[ $? -ne 0 ] && exit 1
check_process_not_exist "lotus daemon"
[ $? -ne 0 ] && exit 1

# 2.cleaning genesis_sectors;lotusdata;lotusminer;
log_info "cleaning environment ..."
  # remove data of genesis-sectors
remove_directory "${GENESIS_PATH}"
[ $? -ne 0 ] && exit 1
  # remove data of lotusdate
remove_directory "${LOTUS_PATH}"
[ $? -ne 0 ] && exit 1
  # remove data of lotusminer
remove_directory "${LOTUS_STORAGE_PATH}"
[ $? -ne 0 ] && exit 1
  # remove data of filecoin.db
remove_file "/root/filecoin.db"
[ $? -ne 0 ] && exit 1
  # remove data of sector.db
remove_file "/root/sector.db"
[ $? -ne 0 ] && exit 1


# 3.run lotus daemon
cd ${APP_PATH}
log_info "Download the 2048 byte parameters ..."
./lotus fetch-params 2048 2>&1 |tee ${TMP}
grep 'parameter and key-fetching complete' ${TMP} &> /dev/null
if [ $? -eq 0 ]; then
  log_info "Download the 2048 byte parameters ... success"
else
  log_err "Download the 2048 byte parameters ... failed"
  exit 1
fi

log_info "Pre-seal some sectors ..."
./lotus-seed pre-seal --sector-size 2KiB --num-sectors 2
if [ -f ${GENESIS_PATH}/pre-seal-t01000.json ]; then
  log_info "${GENESIS_PATH}/pre-seal-t01000.json created"
else
  log_err "create ${GENESIS_PATH}/pre-seal-t01000.json failed"
  log_err "Pre-seal some sectors ... failed"
  exit 1
fi

log_info "Create the genesis block and start up the first node ..."
./lotus-seed genesis new localnet.json
if [ -f ${APP_PATH}/localnet.json ]; then
  log_info "${APP_PATH}/localnet.json created"
else
  log_err "create ${APP_PATH}/localnet.json failed"
  exit 1
fi

./lotus-seed genesis add-miner localnet.json ${GENESIS_PATH}/pre-seal-t01000.json 2>&1 |tee ${TMP}
grep "Adding miner t01000 to genesis template" ${TMP} &> /dev/null
rtv1=$?
grep "Giving .* some initial balance" ${TMP} &> /dev/null
rtv2=$?
if [ ${rtv1} -eq 0 -a ${rtv2} -eq 0 ]; then
  log_info "Create the genesis block and start up the first node ... success"
else
  log_err "Create the genesis block and start up the first node ... failed"
  exit 1
fi

log_info "launch lotus deamon ..."
nohup ./lotus daemon --lotus-make-genesis=devgen.car --genesis-template=localnet.json --bootstrap=false &> ${APP_PATH}/lotus.log &
v1=1
while [ ${v1} -ne 0 ]; do
  sleep 1s
  grep 'mpool ready' ${APP_PATH}/lotus.log &> /dev/null
  if [ $? -eq 0 ]; then
    v1=0
    log_info "launch lotus deamon ... success"
  else
    log_info "waiting for launch lotus daemon ${v1}s..."
    v1=$((v1+1))
  fi
done
is_directory_exist "${LOTUS_PATH}"
[ $? -ne 0 ] && exit 1


# 4.run lotus-deamon
log_info "import the genesis miner key ..."
./lotus wallet import --as-default ${GENESIS_PATH}/pre-seal-t01000.key 2>&1 |tee ${TMP}
grep "imported key .* successfully!" ${TMP} &> /dev/null
if [ $? -eq 0 ]; then
  log_info "import the genesis miner key ... success"
else
  log_err "import the genesis miner key ... failed"
  exit 1
fi


# --initialize miner
log_info "===initialize lotus miner==="
# 0.initialize miner
log_info "initialize miner ..."
./lotus-miner init --genesis-miner --actor=t01000 --sector-size=2KiB \
--pre-sealed-sectors=${GENESIS_PATH} --pre-sealed-metadata=${GENESIS_PATH}/pre-seal-t01000.json \
--nosync 2>&1 |tee ${TMP}
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
batchprecommits=$(grep -v '^ *#' ${conf_file} |grep "miner" |awk -F' ' '{print $10}' |cut -d'=' -f2)
aggregatecommits=$(grep -v '^ *#' ${conf_file} |grep "miner" |awk -F' ' '{print $11}' |cut -d'=' -f2)

sed -i "s/#ListenAddress = \"\/ip4\/127.0.0.1\/tcp\/2345/  ListenAddress = \"\/ip4\/${m_ip}\/tcp\/${port}/g" ${miner_conf}
sed -i "s/#RemoteListenAddress = \"127.0.0.1:2345\"/  RemoteListenAddress = \"${m_ip}:${port}\"/g" ${miner_conf}
sed -i "s/#AllowAddPiece = true/  AllowAddPiece = ${addpiece}/g" ${miner_conf}
sed -i "s/#AllowPreCommit1 = true/  AllowPreCommit1 = ${precommit1}/g" ${miner_conf}
sed -i "s/#AllowPreCommit2 = true/  AllowPreCommit2 = ${precommit2}/g" ${miner_conf}
sed -i "s/#AllowCommit1 = true/  AllowCommit1 = ${commit1}/g" ${miner_conf}
sed -i "s/#AllowCommit2 = true/  AllowCommit2 = ${commit2}/g" ${miner_conf}
sed -i "s/#BatchPreCommits = true/  BatchPreCommits = ${batchprecommits}/g" ${miner_conf}
sed -i "s/#AggregateCommits = true/  AggregateCommits = ${aggregatecommits}/g" ${miner_conf}

log_info "content of miner config file: ${miner_conf}"
cat ${miner_conf}

# do run
bash ${BASEDIR}/MinerOperation/start_miner.sh $(echo ${conf_file##*/}|cut -d_ -f2)
return_value=$?
log_info "pre_env_2k_lotus_miner.sh return value: ${return_value}"
exit ${return_value}


