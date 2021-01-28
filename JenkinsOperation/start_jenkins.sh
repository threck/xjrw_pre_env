#!/usr/bin/env bash

LOCALDIR=$(cd $(dirname $0) && pwd && cd - &> /dev/null)
BASEDIR=${LOCALDIR}/..
source ${BASEDIR}/common.sh


if [ -z "$1" ]; then
  echo "please run as: bash $0 [ jenkins_nodename ]"
  echo "e.g. bash $0 2k_miner_150"
  exit 1
fi

t=$(date +%Y%m%d%H%M%S)
ip=$(ifconfig |grep 192 |awk -F' ' '{print $2}')
log=${LOCALDIR}/$0${t}.log
nodename=$1


# judge if there's a jenkins process
pid=$(ps -ef |grep jenkins-agent |grep -v grep |awk -F' ' '{print $2}')
if [ -n "${pid}" ]; then
  log_info "there a jenkins process [${pid}] found already."
  log_info "quit"
  exit 0
fi

# start jenkins
log_info "starting jenkins on ${ip} ..."
nohup java -jar ${LOCALDIR}/agent.jar -jnlpUrl http://192.168.0.4:8081/computer/${nodename}/jenkins-agent.jnlp \
-secret @secret-file -workDir "/var/jenkins_home" &> ${log} &

# check if jenkins start success
pid=$(ps -ef |grep jenkins-agent |grep -v grep |awk -F' ' '{print $2}')
if [ -z "${pid}" ]; then
  log_err "starting jenkins on ${ip} ... failed"
else
  log_info "starting jenkins on ${ip} ... success. pid [${pid}]"
fi

log_info "logs: ${log}"
