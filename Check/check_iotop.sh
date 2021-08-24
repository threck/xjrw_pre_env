#!/usr/bin/env bash


log=${0}.log
rm -rf ${log}

echo Actual time:$(date) >> ${log}
iotop -ob -n 5 >> ${log}

