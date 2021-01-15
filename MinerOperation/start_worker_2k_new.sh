#!/bin/bash
#source /root/environment/common.sh
source /etc/profile

LOCAL_IP=$(ifconfig |grep inet |grep -v 127 |awk '{printf $2}')
conf=/root/environment/pre_env_2k.conf
port=$(grep -v "^ *#" ${conf} |grep worker |grep ${LOCAL_IP} |cut -d' ' -f3 |cut -d'=' -f2)
addpiece=$(grep -v "^ *#" ${conf} |grep worker |grep ${LOCAL_IP} |cut -d' ' -f4 |cut -d'=' -f2)
precommit1=$(grep -v "^ *#" ${conf} |grep worker |grep ${LOCAL_IP} |cut -d' ' -f5 |cut -d'=' -f2)
precommit2=$(grep -v "^ *#" ${conf} |grep worker |grep ${LOCAL_IP} |cut -d' ' -f6 |cut -d'=' -f2)
commit1=$(grep -v "^ *#" ${conf} |grep worker |grep ${LOCAL_IP} |cut -d' ' -f7 |cut -d'=' -f2)
commit2=$(grep -v "^ *#" ${conf} |grep worker |grep ${LOCAL_IP} |cut -d' ' -f8 |cut -d'=' -f2)
unseal=$(grep -v "^ *#" ${conf} |grep worker |grep ${LOCAL_IP} |cut -d' ' -f9 |cut -d'=' -f2)

#echo "
#`echo -e "\033[35m 1)开启worker\033[0m"`
#`echo -e "\033[35m 2)重启worker\033[0m"`
#`echo -e "\033[35m 3)关闭worker\033[0m"`
#`echo -e "\033[35m 4)清空worker\033[0m"`
#"
# run lotus-worker
#cd /root
start_worker(){
        nohup /root/lotus-worker run --listen=${LOCAL_IP}:${port} --addpiece=${addpiece} --precommit1=${precommit1} --precommit2=${precommit2} --commit1=${commit1} --commit2=${commit2} --unseal=${unseal} >/root/worker.log 2>&1  &
        sleep 2s
}

stop_worker(){
        pkill -9 lotus-worker >>/dev/null 2>&1
        ps -ef|grep "lotus-worker run"|grep -v grep
        if [ $? -eq 0 ]
        then
                echo "$LOCAL_IP lotus-worker failed please try again"
        else
                echo "$LOCAL_IP lotus-worker关闭完成"
        fi
        sleep 2s
}

delete_worker(){
        [ -z "${WORKER_PATH}" ] && echo "env WORKER_PATH is null! please set it!" && exit 1
        if [ -n "${WORKER_PATH}" ]; then
                rm -rf ${WORKER_PATH}
                [ ! -d "${WORKER_PATH}" ] && echo "removing ${LOTUS_PATH} success!"
        fi
}

main(){
        case $1 in
        1)
        start_worker
        ;;
        2)
        stop_worker
        start_worker
        ;;
        3)
        stop_worker
        ;;
        4)
        stop_worker
        delete_worker
        ;;
        *)
        echo "请按照提示菜单输入:"
        esac
}
main $1
