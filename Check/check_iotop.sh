#!/usr/bin/env bash


log=${0}.log
rm -rf ${log}

echo Actual time:$(date) >> ${log}
iotop -ob -d 1 >> ${log}

