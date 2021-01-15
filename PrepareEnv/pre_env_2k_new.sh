#!/bin/bash

GENESIS_PATH=/root/.genesis-sectors
SECTOR_PATH=/root/sector.db
APP_PATH=/root
ENV_PATH=/root/environment
conf=pre_env_2k.conf
source ../common.sh

echo -e "\033[35m 1)初始化并启动\033[0m"
echo -e "\033[35m 2)修改config文件，并复制相关文件到worker\033[0m"
echo -e "\033[35m 3)复制文件，并启动worker\033[0m"
echo -e "\033[35m 4)重启worker\033[0m"
echo -e "\033[35m 5)关闭worker\033[0m"
echo -e "\033[35m 6)删除worker，并清空\033[0m"
echo -e "\033[35m 7)清空miner环境\033[0m"
echo -e "\033[35m 8)清空worker环境\033[0m"


# 1.check some env
checking_env_var(){
    echo "checking env var ..."
    [ -z "${LOTUS_PATH}" ] && echo "env LOTUS_PATH is null! please set it!" && exit 1
    [ -z "${LOTUS_STORAGE_PATH}" ] && echo "env LOTUS_STORAGE_PATH is null! please set it!" && exit 1
    [ -z "${WORKER_PATH}" ] && echo "env WORKER_PATH is null! please set it!" && exit 1

    # 2.cleaning genesis_sectors;lotusdata;lotusminer;
    echo "cleaning environment ..."
    # remove data of genesis-sectors
    if [ -n "${GENESIS_PATH}" ]; then
            rm -rf ${GENESIS_PATH}
            [ ! -d "${GENESIS_PATH}" ] && echo "removing ${GENESIS_PATH} success!"
    fi
    if [ -n "${SECTOR_PATH}" ]; then
            rm -rf ${SECTOR_PATH}
            [ ! -d "${SECTOR_PATH}" ] && echo "removing ${SECTOR_PATH} success!"
    fi
    # remove data of lotusdate
    if [ -n "${LOTUS_PATH}" ]; then
            rm -rf ${LOTUS_PATH}
            [ ! -d "${LOTUS_PATH}" ] && echo "removing ${LOTUS_PATH} success!"
    fi
    # remove data of lotusminer
    if [ -n "${LOTUS_STORAGE_PATH}" ]; then
            rm -rf ${LOTUS_STORAGE_PATH}
            [ ! -d "${LOTUS_STORAGE_PATH}" ] && echo "removing ${LOTUS_STORAGE_PATH} success!"
    fi
}

# 3.run lotus daemon
init_lotus(){
    cd ${APP_PATH}

    ./lotus-seed pre-seal --sector-size 2KiB --num-sectors 2

    sleep 2s

    #2020-12-14T15:21:46.452+0800   INFO    preseal seed/seed.go:232        Writing preseal manifest to /root/.genesis-sectors/pre-seal-t01000.json
    ./lotus-seed genesis new localnet.json

    ./lotus-seed genesis add-miner localnet.json ${GENESIS_PATH}/pre-seal-t01000.json

    nohup ./lotus daemon --lotus-make-genesis=devgen.car --genesis-template=localnet.json --bootstrap=false &> lotus.log &

    sleep 3s
    ./lotus wallet import --as-default ${GENESIS_PATH}/pre-seal-t01000.key
    #successfully!
    ./lotus-miner init --genesis-miner --actor=t01000 --sector-size=2KiB --pre-sealed-sectors=${GENESIS_PATH} --pre-sealed-metadata=${GENESIS_PATH}/pre-seal-t01000.json --nosync
    #2020-12-14T15:23:15.236+0800   INFO    main    lotus-storage-miner/init.go:266 Miner successfully created, you can now start it with 'lotus-miner run'
}

# modify .lotusminer/config.coml
modify_config(){
    m_ip=$(ifconfig |grep inet |grep -v 127 |awk '{printf $2}')
    sed -i "s/#  ListenAddress = \"\/ip4\/127.0.0.1/  ListenAddress = \"\/ip4\/${m_ip}/g" ${LOTUS_STORAGE_PATH}/config.toml
    sed -i "s/#  RemoteListenAddress = \"127.0.0.1:2345\"/  RemoteListenAddress = \"${m_ip}:2345\"/g" ${LOTUS_STORAGE_PATH}/config.toml
    sed -i 's/#  AllowAddPiece = true/  AllowAddPiece = false/g' ${LOTUS_STORAGE_PATH}/config.toml
    sed -i 's/#  AllowPreCommit1 = true/  AllowPreCommit1 = false/g' ${LOTUS_STORAGE_PATH}/config.toml
    sed -i 's/#  AllowPreCommit2 = true/  AllowPreCommit2 = false/g' ${LOTUS_STORAGE_PATH}/config.toml
    sed -i 's/#  AllowCommit1 = true/  AllowCommit1 = false/g' ${LOTUS_STORAGE_PATH}/config.toml
    sed -i 's/#  AllowCommit2 = true/  AllowCommit2 = false/g' ${LOTUS_STORAGE_PATH}/config.toml
}

#modify export_miner.config
modify_export(){
    wc_number=$(cat export_miner.config|wc -l)
    for i in $(seq 1 $wc_number)
    do
        export_miner_awk=$(sed -n "$i"p export_miner.config|awk -F'=' '{print $1}')
        export_miner=$(sed -n "$i"p export_miner.config)
        if ! grep ${export_miner_awk}  /etc/profile
        then
               echo "export ${export_miner}" >>/etc/profile
        fi
    done
}

# run lotus-miner
start_miner(){
    nohup ./lotus-miner run --nosync &> miner.log &
    sleep 5s
}

# 5.start worker
# prepare 3 files: api, token, lotus-worker
scp_work(){
    workers=$(grep -v "^ *#" ${conf} |grep worker |cut -d' ' -f2 |cut -d'=' -f2)
    for ip in ${workers}
    do
        ssh ${ip} "mkdir -p ${LOTUS_STORAGE_PATH}"
        scp_with_log ${ip} ${LOTUS_STORAGE_PATH}/api ${LOTUS_STORAGE_PATH}/api
        scp_with_log ${ip} ${LOTUS_STORAGE_PATH}/token ${LOTUS_STORAGE_PATH}/token
        scp_with_log ${ip} ${APP_PATH}/lotus-worker ${APP_PATH}/lotus-worker
        scp_with_log ${ip} $ENV_PATH/start_worker_2k.sh $ENV_PATH
        scp_with_log ${ip} $ENV_PATH/pre_env_2k.sh $ENV_PATH
        scp_with_log ${ip} $ENV_PATH/common.sh $ENV_PATH
        scp_with_log ${ip} ${conf} $ENV_PATH
    done
}

#1、启动worker
#2、重启worker
#3、关闭worker
#4、删除worker

choice_work(){
    workers=$(grep -v "^ *#" ${conf} |grep worker |cut -d' ' -f2 |cut -d'=' -f2)
    for ip in ${workers}
    do
        ssh ${ip} "bash $ENV_PATH/start_worker_2k.sh $1" &
        sleep 2s
        [ $? -ne 0 ] && exit 1
    done
}

checking_worker_env(){
    workers=$(grep -v "^ *#" ${conf} |grep worker |cut -d' ' -f2 |cut -d'=' -f2)
    for ip in ${workers}
    do
        scp_with_log ${ip} ${conf} $ENV_PATH
        choice_work 4
        sleep 2s
    done
}

main(){
    case $1 in
    1)
    checking_env_var
    init_lotus
    modify_config
    start_miner
    scp_work
    choice_work 1
    ;;
    2)
    modify_export
    ;;
    3)
    scp_work
    choice_work 1
    ;;
    4)
    choice_work 2
    ;;
    5)
    choice_work 3
    ;;
    6)
    choice_work 4
    ;;
    7)
    checking_env_var
    ;;
    8)
    checking_worker_env
    ;;
    *)
    echo "提示菜单"
    esac
}

main $1