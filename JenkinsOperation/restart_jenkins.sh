#!/usr/bin/env bash

LOCALDIR=$(cd $(dirname $0) && pwd && cd - &> /dev/null)



bash ${LOCALDIR}/stop_jenkins.sh
bash ${LOCALDIR}/start_jenkins.sh