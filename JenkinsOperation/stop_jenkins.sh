#!/usr/bin/env bash

LOCALDIR=$(cd $(dirname $0) && pwd && cd - &> /dev/null)
BASEDIR=${LOCALDIR}/..
source ${BASEDIR}/common.sh

# judge if there's a jenkins process
pid=$(ps -ef |grep jenkins-agent |grep -v grep |awk -F' ' '{print $2}')
if [ -z "${pid}" ]; then
  log_info "no jenkins process found."
  log_info "quit"
  exit 0
else
  log_info "jenkins process[${pid}] found"
fi

# stop jenkins
log_info "stoping jenkins ..."
kill -9 ${pid}

# check if jenkins killed success
pid=$(ps -ef |grep jenkins-agent |grep -v grep |awk -F' ' '{print $2}')
if [ -z "${pid}" ]; then
  log_info "stoping jenkins ... success"
else
  log_info "stoping jenkins ... failed"
fi