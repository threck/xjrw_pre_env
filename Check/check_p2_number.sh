#!/usr/bin/env bash
#check if p2 wait sectorID is same , after reboot P2 workers

source ../common.sh
ip=$1
if [ -z "$1" ]; then
    echo "please input ip addr: e.g. 122 or 123"
    exit 1
fi
while true
do
    pid_1=$(/root/lotus-miner sealing workers |grep ${ip} |grep PC2 |awk -F'[()]' '{print $2}' |sed 's/,/ /g')
    pid_1_num=$(echo ${pid_1} |awk -F' ' '{print NF}')

    log_info "shutdown worker"
    ssh 192.168.0.${ip} "bash /root/environment/start_worker_2k.sh 2"
    log_info "start worker over"
    log_info "wait 70s for sectors..."
    sleep 70s

    pid_2=$(/root/lotus-miner sealing workers |grep ${ip} |grep PC2 |awk -F'[()]' '{print $2}' |sed 's/,/ /g')
    pid_2_num=$(echo ${pid_2} |awk -F' ' '{print NF}')


    # check numbers of sector id
    if [[ ${pid_1_num} != ${pid_2_num} ]]; then
        log_info "${pid_1_num} pid before reboot worker ${ip}: -> ${pid_1}"
        log_info "${pid_2_num} pid after reboot worker ${ip}: -> ${pid_2}"
    else

    # check sector id
    for i in ${pid_1}
    do
      echo ${pid_2} |grep -w ${i} &> /dev/null
      if [ $? -ne 0 ]; then
        log_info "pid before reboot worker ${ip}: ${pid_1_num} -> ${pid_1}"
        log_info "pid after reboot worker ${ip}: ${pid_2_num} -> ${pid_2}"
        exit
      fi
    done

    for j in ${pid_2}
    do
      echo ${pid_1} |grep -w ${j} &> /dev/null
      if [ $? -ne 0 ]; then
        log_info "pid before reboot worker ${ip}: ${pid_1_num} -> ${pid_1}"
        log_info "pid after reboot worker ${ip}: ${pid_2_num} -> ${pid_2}"
      fi
    done

    fi
    log_info "wait 720s for re-restart worker..."
    sleep 660s
done