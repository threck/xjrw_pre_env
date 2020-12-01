#!/bin/bash
source ./common.sh
GENESIS_PATH=/root/.genesis-sectors
APP_PATH=/root

# 1.check some env
echo "checking env var ..."
[ -z "${LOTUS_PATH}" ] && echo "env LOTUS_PATH is null! please set it!" && exit 1
[ -z "${LOTUS_MINER_PATH}" ] && echo "env LOTUS_MINER_PATH is null! please set it!" && exit 1
[ -z "${LOTUS_WORKER_PATH}" ] && echo "env LOTUS_WORKER_PATH is null! please set it!" && exit 1

# 2.cleaning genesis_sectors;lotusdata;lotusminer;
echo "cleaning environment ..."
  # remove data of genesis-sectors
if [ -n "${GENESIS_PATH}" ]; then
    rm -rf ${GENESIS_PATH}
    [ ! -d "${GENESIS_PATH}" ] && echo "removing ${GENESIS_PATH} success!"
fi
  # remove data of lotusdate
if [ -n "${LOTUS_PATH}" ]; then
    rm -rf ${LOTUS_PATH}
    [ ! -d "${LOTUS_PATH}" ] && echo "removing ${LOTUS_PATH} success!"
fi
  # remove data of lotusminer
if [ -n "${LOTUS_MINER_PATH}" ]; then
    rm -rf ${LOTUS_MINER_PATH}
    [ ! -d "${LOTUS_MINER_PATH}" ] && echo "removing ${LOTUS_MINER_PATH} success!"
fi

# 3.run lotus daemon
cd ${APP_PATH}
./lotus fetch-params 2048

./lotus-seed pre-seal --sector-size 2KiB --num-sectors 2

./lotus-seed genesis new localnet.json

./lotus-seed genesis add-miner localnet.json ${GENESIS_PATH}/pre-seal-t01000.json

nohup ./lotus daemon --lotus-make-genesis=devgen.car --genesis-template=localnet.json --bootstrap=false &> lotus.log &

# 4.run lotus-deamon
./lotus wallet import --as-default ${GENESIS_PATH}/pre-seal-t01000.key

./lotus-miner init --genesis-miner --actor=t01000 --sector-size=2KiB --pre-sealed-sectors=${GENESIS_PATH} --pre-sealed-metadata=${GENESIS_PATH}/pre-seal-t01000.json --nosync

# modify .lotusminer/config.coml
m_ip=$(ifconfig |grep inet |grep -v 127 |awk '{printf $2}')
sed -i "s/#  ListenAddress = \"\/ip4\/127.0.0.1/  ListenAddress = \"\/ip4\/${m_ip}/g" ${LOTUS_MINER_PATH}/config.toml
sed -i "s/#  RemoteListenAddress = \"127.0.0.1:2345\"/  RemoteListenAddress = \"${m_ip}:2345\"/g" ${LOTUS_MINER_PATH}/config.toml
sed -i 's/#  AllowAddPiece = true/  AllowAddPiece = false/g' ${LOTUS_MINER_PATH}/config.toml
sed -i 's/#  AllowPreCommit1 = true/  AllowPreCommit1 = false/g' ${LOTUS_MINER_PATH}/config.toml
sed -i 's/#  AllowPreCommit2 = true/  AllowPreCommit2 = false/g' ${LOTUS_MINER_PATH}/config.toml
sed -i 's/#  AllowCommit1 = true/  AllowCommit1 = false/g' ${LOTUS_MINER_PATH}/config.toml
sed -i 's/#  AllowCommit2 = true/  AllowCommit2 = false/g' ${LOTUS_MINER_PATH}/config.toml

# run lotus-miner
nohup ./lotus-miner run --nosync &> miner.log &

# 5.start worker
# prepare 3 files: api, token, lotus-worker
workers=$(grep "worker" pre_env_2k.conf |cut -d' ' -f2 |cut -d'=' -f2)
for ip in ${workers}
do
  ssh ${ip} "mkdir -p ${LOTUS_MINER_PATH}"
  scp_with_log ${ip} ${LOTUS_MINER_PATH}/api ${LOTUS_MINER_PATH}/api
  scp_with_log ${ip} ${LOTUS_MINER_PATH}/token ${LOTUS_MINER_PATH}/token
  scp_with_log ${ip} ${APP_PATH}/lotus-worker ${APP_PATH}/lotus-worker
done


# run ./lotus-worker
bash start_worker_2k.sh
[ $? -ne 0 ] && exit 1

