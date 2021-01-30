#!/usr/bin/env bash
# check the temperature of GPU
# finished
interval=$1
if [ -z "${interval}" ]; then
  echo "please run as: bash $0 [ ${interval time} ](units: S)"
  echo "e.g. bash $0 1"
  exit 1
fi

log=$0.log
rm -rf ${log}
echo "GPU temperature check ..."
echo "interval time: ${interval}s ..."
while true
do
  temp=$(nvidia-smi |grep % |awk -F' ' '{print $3}' |cut -dC -f1)
  d=$(date "+%Y-%m-%d %H:%M:%S")
  echo "${d} GPU temperature: ${temp}"
  if [ ${temp} -gt 80 ]; then
    echo "${d} GPU temperature: ${temp}" >> ${log}
  fi
  sleep ${interval}s
done