#!/usr/bin/env bash

LOCALDIR=$(cd $(dirname $0) && pwd && cd - &> /dev/null)
BASEDIR=${LOCALDIR}/..
source ${BASEDIR}/common.sh

t=$(date +%Y%m%d%H%M%S)
ip=$(ifconfig |grep 192 |awk -F' ' '{print $2}')
log=$0${t}.log

# start jenkins
log_info "starting jenkins on ${ip} ..."
nohup java -jar ${LOCALDIR}/agent.jar -jnlpUrl http://${ip}:8081/computer/miner_201/jenkins-agent.jnlp \
-secret @secret-file -workDir "/var/jenkins_home" &> ${log} &

# check if jenkins start success
pid=$(ps -ef |grep jenkins |grep -v grep |awk -F' ' '{print $2}')
if [ -z ${pid} ]; then
  log_err "starting jenkins on ${ip} ... failed"
else
  log_info "starting jenkins on ${ip} ... success"
fi

log_info "logs: ${log}"
