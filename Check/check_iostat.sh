#!/usr/bin/env bash

runtime=18000
log=${0}.log
rm -rf ${log}

for ((i=0;i<${runtime};i++)); do
  echo loop${i}
  date >> ${log}
  iostat >> ${log}
  sleep 1s
done