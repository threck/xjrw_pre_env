#!/usr/bin/env bash

LOCALDIR=$(cd $(dirname $0) && pwd && cd - &> /dev/null)


function log_info() {
  echo $(date '+%Y-%m-%d %H:%M:%S')" [INFO] - $1"
}

function log_err() {
  echo $(date '+%Y-%m-%d %H:%M:%S')" [ERROR] - $1"
}

function log_warn() {
  echo $(date '+%Y-%m-%d %H:%M:%S')" [WARN] - $1"
}

function check_and_deal_from_repr_failure() {
    key="from_repr failure"
    log_info "check [ ${key} ] from ${log_file} ..."
    grep -n -B 1 "${key}" ${log_file} > log_tmp
    if [ $? -eq 0 ]; then
        [ -f ${tmp_file} ] && log_info "clean ${tmp_file} ..." && rm -rf ${tmp_file}
        cat log_tmp |grep post |awk -F'\\(|\\)' '{print $2}' |uniq >> ${tmp_file}
        count=1
        total=$(cat ${tmp_file}|wc -l)
        for broken_sector_id in $(cat ${tmp_file} |uniq)
        do
            is_sector_found ${broken_sector_id}
            if [ $? -ne 0 ]; then
                log_warn "checking: found a *new* broken sector: ${broken_sector_id} "
                log_warn "${log_tmp}"
                mv_broken_sector ${broken_sector_id}
                echo "${broken_sector_id}" >> ${broken_sectors_list}
            else
                log_info "checking: found a *old* broken sector: ${broken_sector_id}"
                [ ${count} -eq ${total} ] && log_info "check over: no new broken sector found."
                count=$((count+1))
            fi
        done
    else
        log_info "no new broken sector found."
    fi
    log_info "check [ ${key} ] from ${log_file} ... end"
}

function check_and_deal_faulty_sectors() {
    key="faulty sectors"
    log_info "check [ ${key} ] from ${log_file} ..."
    grep -n "${key}" ${log_file} > log_tmp
    if [ $? -eq 0 ]; then
        [ -f ${tmp_file} ] && log_info "clean ${tmp_file} ..." && rm -rf ${tmp_file}
        cat log_tmp |grep post |awk -F'\\(|\\)' '{print $2}' |uniq >> ${tmp_file}
        count=1
        total=$(cat ${tmp_file}|wc -l)
        for broken_sector_id in $(cat ${tmp_file} |uniq)
        do
            is_sector_found ${broken_sector_id}
            if [ $? -ne 0 ]; then
                log_warn "checking: found a *new* broken sector: ${broken_sector_id} "
                log_warn "${log_tmp}"
                mv_broken_sector ${broken_sector_id}
                echo "${broken_sector_id}" >> ${broken_sectors_list}
            else
                log_info "checking: found a *old* broken sector: ${broken_sector_id}"
                [ ${count} -eq ${total} ] && log_info "check over: no new broken sector found."
                count=$((count+1))
            fi
        done
    else
        log_info "no new broken sector found."
    fi
    log_info "check [ ${key} ] from ${log_file} ... end"

}

function check_and_deal_merkle_tree_failed() {
    key="merkle_tree failed"
    key4="panic"
    log_info "check [ ${key} ] from ${log_file} ..."
    grep -n "${key}" ${log_file} > log_tmp
    if [ $? -eq 0 ]; then
        [ -f ${tmp_file} ] && log_info "clean ${tmp_file} ..." && rm -rf ${tmp_file}
        cat log_tmp |awk -F'\\(|\\)' '{print $2}' |uniq >> ${tmp_file}
        count=1
        total=$(cat ${tmp_file}|wc -l)
        for broken_sector_id in $(cat ${tmp_file} |uniq)
        do
            is_sector_found ${broken_sector_id}
            if [ $? -ne 0 ]; then
                log_warn "checking: found a *new* broken sector: ${broken_sector_id} "
                log_warn "${log_tmp}"
                mv_broken_sector ${broken_sector_id}
                echo "${broken_sector_id}" >> ${broken_sectors_list}
            else
                log_info "checking: found a *old* broken sector: ${broken_sector_id}"
                [ ${count} -eq ${total} ] && log_info "check over: no new broken sector found."
                count=$((count+1))
            fi
        done
    else
        log_info "no new broken sector found."
    fi
    log_info "check [ ${key} ] from ${log_file} ... end"

}


function is_sector_found(){
    sector_id=$1
    grep ${sector_id} ${broken_sectors_list} &> /dev/null
    return $?
}


function mv_broken_sector() {
    sector_id=$1
    mkdir -p ${broken_sector_root}/cache
    mkdir -p ${broken_sector_root}/sealed
    log_info "moving broken_sector_s-t${miner_id}-${sector_id} ..."

    log_info "mv ${sector_root}/cache/s-t${miner_id}-${sector_id} ${broken_sector_root}/cache/ ..."
    mv ${sector_root}/cache/s-t${miner_id}-${sector_id} ${broken_sector_root}/cache/
    if [ $? -eq 0 ]; then
        log_info "mv ${sector_root}/cache/s-t${miner_id}-${sector_id} ${broken_sector_root}/cache/ ... success"
    else
        log_err "mv ${sector_root}/cache/s-t${miner_id}-${sector_id} ${broken_sector_root}/cache/ ... failed"
    fi

    log_info "mv ${sector_root}/sealed/s-t${miner_id}-${sector_id} ${broken_sector_root}/sealed/ ..."
    mv ${sector_root}/sealed/s-t${miner_id}-${sector_id} ${broken_sector_root}/sealed/
    if [ $? -eq 0 ]; then
        log_info "mv ${sector_root}/sealed/s-t${miner_id}-${sector_id} ${broken_sector_root}/sealed/ ... success"
    else
        log_err "mv ${sector_root}/sealed/s-t${miner_id}-${sector_id} ${broken_sector_root}/sealed/ ... failed"
    fi

    log_info "moving broken_sector_s-t${miner_id}-${sector_id} ... end"
}


function main() {

    # get windowspost_turn_nu
    lotus-miner proving deadlines |grep -E '^0|^1|^2|^3|^4|^5|^6|^7|^8|^9' |awk -F' ' '{print $1" "$3}' |grep -v ' 0' |awk -F' ' '{print $1}' > ${tmp_file}
    log_info "found windowspost turn number: $(cat ${tmp_file})"

    # run every deadline post
    log_info "run_deadlinepost and deal broken sectors ... start"
    for turn_nu in $(cat ${tmp_file})
    do
        continue_do=0
        count=1
        echo ""
        log_info "run [ lotus-miner xjrw deadlinepost ${turn_nu} ] ..."
        while [ ${continue_do} -eq 0 ]; do
            log_info "time count: ${count}"
            lotus-miner xjrw deadlinepost ${turn_nu}
            check_and_deal_from_repr_failure
            [ $? -eq 0 ] && continue_do=$((continue_do+1))
            check_and_deal_faulty_sectors
            [ $? -eq 0 ] && continue_do=$((continue_do+1))
            check_and_deal_merkle_tree_failed
            [ $? -eq 0 ] && continue_do=$((continue_do+1))
            count=$((count+1))
        done
        log_info "run [ lotus-miner xjrw deadlinepost ${turn_nu} ] ... end"
    done
    log_info "run_deadlinepost and deal broken sectors ... end"

    # run windowspost
    log_info "run_windowspost and deal broken sectors ... start"
    last_sector_id=$(lotus-miner info|grep -i total: |awk -F' ' '{print $2}')
    log_info "detect ${last_sector_id} sectors"
    continue_do=1
    count=1
    log_info "run [ lotus-miner xjrw windowspost 0 ${last_sector_id} ] ..."
    while [ ${continue_do} -eq 1 ]; do
        log_info "time count: ${count}"
        lotus-miner xjrw windowspost 0 ${last_sector_id}
        check_and_deal_from_repr_failure
        [ $? -eq 0 ] && continue_do=0
        count=$((count+1))
    done
    log_info "run [ lotus-miner xjrw windowspost 0 ${last_sector_id} ] ... end"
    log_info "run_windowspost and deal broken sectors ... end"

}


# params
conf=check_broken_sectors.conf

sector_root=${LOTUS_MINER_PATH}
broken_sector_root=/dcs_data/broken_sectors_$(date +%Y%m%d%H%M%S)
log_info "getting miner_id ..."
miner_id=$(lotus-miner info |grep Miner: |awk -F' |f' '{print $3}')
log_info "miner_id: ${miner_id}"
log_file=/home/xjrw/logs/miner_runtime.log
broken_sectors_list=${LOCALDIR}/broken_sectors_list.log
tmp_file=${LOCALDIR}/$0.tmp

#key_error=$(sed -n '/KEY-ERROR/,/SECTORS-BROKEN/p' ${conf} |grep -v ^$ |grep -v '^\[')
#sectors_broken=$(sed -n '/SECTORS-BROKEN/,$p' ${conf} |grep -v ^$ |grep -v '^\[')

# rm sectors_list file if it's exists
[ -f ${broken_sectors_list} ] && log_info "clean ${broken_sectors_list} ..." && rm -rf ${broken_sectors_list}
# rm tmp file if it's exists
[ -f ${tmp_file} ] && log_info "clean ${tmp_file} ..." && rm -rf ${tmp_file}



main

