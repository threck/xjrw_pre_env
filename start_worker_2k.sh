#!/bin/bash
source common.sh

LOCAL_IP=$(ifconfig |grep inet |grep -v 127 |awk '{printf $2}')
conf=pre_env_2k.conf
port=$(grep "worker" ${conf} |grep ${LOCAL_IP} |cut -d' ' -f3 |cut -d'=' -f2)
addpiece=$(grep "worker" ${conf} |grep ${LOCAL_IP} |cut -d' ' -f4 |cut -d'=' -f2)
precommit1=$(grep "worker" ${conf} |grep ${LOCAL_IP} |cut -d' ' -f5 |cut -d'=' -f2)
precommit2=$(grep "worker" ${conf} |grep ${LOCAL_IP} |cut -d' ' -f6 |cut -d'=' -f2)
commit1=$(grep "worker" ${conf} |grep ${LOCAL_IP} |cut -d' ' -f7 |cut -d'=' -f2)
commit2=$(grep "worker" ${conf} |grep ${LOCAL_IP} |cut -d' ' -f8 |cut -d'=' -f2)
unseal=$(grep "worker" ${conf} |grep ${LOCAL_IP} |cut -d' ' -f9 |cut -d'=' -f2)

# run lotus-worker
cd /root
nohup ./lotus-worker run --listen=${LOCAL_IP}:${port} \
--addpiece=${addpiece} --precommit1=${precommit1} --precommit2=${precommit2} \
--commit1=${commit1} --commit2=${commit2} --unseal=${unseal} \
&> worker.log &

# check lotus-worker status
grep "Worker registered successfully, waiting for tasks" worker.log &> /dev/null
if [ $? -ne 0 ]; then
  log_err "cmd fail -> ./lotus-worker run --listen=${LOCAL_IP}:${port} \
--addpiece=${addpiece} --precommit1=${precommit1} --precommit2=${precommit2} \
--commit1=${commit1} --commit2=${commit2} --unseal=${unseal} "
  log_info "lotus-worker log : $(cat worker.log)"
  exit 1
fi

# check worker status
#sealing_worker=$(lotus-miner sealing workers)
#echo ${sealing_worker} |grep "host docker-node08-218 tasks C1|C2|PC2-0" &> /dev/null
#if [ $? -ne 0 ]; then
#  log_err "can not find worker's information in cmd log"
#  log_info "cmd log [lotus-miner sealing workers] : ${sealing_worker}"
#  exit 1
#fi

cd - &> /dev/null