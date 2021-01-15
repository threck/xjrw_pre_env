tmpfile=sealing_jobs.log.tmp
logfile=$0.log
rm -rf ${logfile}
while true; do
    dt=$(date)
    /root/lotus-miner sealing jobs > ${tmpfile}
    sectors=$(cat ${tmpfile} |grep -Ev "192.|Sector" |awk -F' ' '{print $2}')
    for i in ${sectors}; do
      sec=$(cat ${tmpfile} |grep -Ev "192.|Sector" |awk -F' ' '{print $2}' |grep -w $i |wc -l)
      if [ ${sec} -ne 1 ]; then
            echo "------------------" >> ${logfile}
            echo ${dt}  >> ${logfile}
            cat ${tmpfile}  >> ${logfile}
            echo "====> found repetitive sector: ${i}" >> ${logfile}
            echo "------------------" >> ${logfile}
            echo "" >> ${logfile}
            break
      fi
    done
    date
    cat ${tmpfile}
    echo ""
    sleep 5s
done
rm ${tmpfile}