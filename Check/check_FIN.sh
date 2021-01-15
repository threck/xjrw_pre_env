#!/usr/bin/env bash



function get_time() {
    local time_str=$1
    local time_type=$2

    if [ ${time_type} = h ]; then
      echo ${time_str} |cut -d':' -f1 |grep ^0 &> /dev/null
      if [ $? -eq 0 ]; then
        echo ${time_str} |cut -d':' -f1 |grep 0$ &> /dev/null
        if [ $? -eq 0 ]; then
          echo 0
        else
          echo ${time_str} |cut -d':' -f1 | cut -d'0' -f2
        fi
      else
        echo ${time_str} |cut -d':' -f1
      fi
    elif [ ${time_type} = m ]; then
      echo ${time_str} |cut -d':' -f2 |grep ^0 &> /dev/null
      if [ $? -eq 0 ]; then
        echo ${time_str} |cut -d':' -f2 |grep 0$ &> /dev/null
        if [ $? -eq 0 ]; then
          echo 0
        else
          echo ${time_str} |cut -d':' -f2 | cut -d'0' -f2
        fi
      else
        echo ${time_str} |cut -d':' -f2
      fi
    elif [ ${time_type} = s ]; then
      echo ${time_str} |cut -d':' -f3 |grep ^0 &> /dev/null
      if [ $? -eq 0 ]; then
        echo ${time_str} |cut -d':' -f3 |grep 0$ &> /dev/null
        if [ $? -eq 0 ]; then
          echo 0
        else
          echo ${time_str} |cut -d':' -f3 | cut -d'0' -f2
        fi
      else
        echo ${time_str} |cut -d':' -f3
      fi
    else
      echo "wrong time type:${time_type}"
      return 1
    fi
}

function get_interval_time() {
    local start_time=$1
    local stop_time=$2
    start_h=$(get_time ${start_time} h)
    start_m=$(get_time ${start_time} m)
    start_s=$(get_time ${start_time} s)
    stop_h=$(get_time ${stop_time} h)
    stop_m=$(get_time ${stop_time} m)
    stop_s=$(get_time ${stop_time} s)
    interval_time=$(((${stop_h} - ${start_h})*3600 + (${stop_m} - ${start_m})*60 + (${stop_s} - ${start_s})))
    echo ${interval_time}
}

function check_fin_time() {
    id=$1
    gateway=$2
    ${lotus_miner} sectors status --log ${id} > ${tmp}
    start_time_str=$(cat ${tmp} |grep SectorProving |awk -F' ' '{print $3}')
    stop_time_str=$(cat ${tmp} |grep SectorFinalized |awk -F' ' '{print $3}')
    echo "sector id: ${id}"
    echo "start_time: ${start_time_str}"
    echo "stop_time: ${stop_time_str}"
    if [ -z "${start_time_str}" ] || [ -z "${stop_time_str}" ]; then
      echo "cannot get start_time or stop_time. sector_id: ${id}" |tee -a ${log}
    else
      interval=$(get_interval_time ${start_time_str} ${stop_time_str})

      if [ ${interval} -gt ${gateway} ]; then
        echo "FIN interval time: ${interval} gt ${gateway}. sector_id: ${id}" |tee -a ${log}
      else
        echo "FIN interval time: ${interval}"
      fi
    fi
    echo ""
}

function main() {
    sector_ids=$(${lotus_miner} sectors list | cut -d' ' -f1 |grep -Ev 'ID|IP')
    rm -rf ${log}
    for id in ${sector_ids}
    do
      check_fin_time ${id} 300
    done
    rm -rf ${tmp}
}

tmp=$0.tmp
log=$0.log
lotus_miner=/root/lotus-miner
main





