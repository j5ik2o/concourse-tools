#!/usr/bin/env bash

FLY='./fly'

PIPE_LINE_NAME='deploy'

if [ $# == 0 ]; then
  echo "Parameters is empty."
  exit 1
fi

while getopts e:c:t:n:h OPT
do
  case $OPT in
    "e" ) ENV_NAME="$OPTARG" ;;
    "c" ) CONCOURSE_ENDPOINT="$OPTARG" ;;
    "t" ) TARGET="$OPTARG" ;;
    "n" ) TEAM_NAME="$OPTARG" ;;
    "h" ) echo "Usage: $0 [-e environment-name] [-c concourse-host] [-t target] [-n team-name]"
          echo "Show help: $0 -h"
          exit 1
          ;;
       *) echo "Invalid parameters"
          exit 1
          ;;
  esac
done

echo "ENV_NAME=${ENV_NAME}"
echo "CONCOURSE_ENDPOINT=${CONCOURSE_ENDPOINT}"
echo "TARGET=${TARGET}"
echo "TEAM_NAME=${TEAM_NAME}"

set -e

PIPE_LINE_YML='pipeline.yml'
CREDENTIAL_YML="environment/${ENV_NAME}/credential.yml"
VARIABLE_YML="environment/${ENV_NAME}/variable.yml"

if [ ! -f $CREDENTIAL_YML ]; then
  echo "$CREDENTIAL_YML is not found."
  exit 1
fi

if [ ! -f $VARIABLE_YML ]; then
  echo "$VARIABLE_YML is not found."
  exit 1
fi

OPT_TEAM_NAME=
if [ ! -z "${TEAM_NAME}" ]; then
  OPT_TEAM_NAME="-n ${TEAM_NAME}"
fi

echo y | ${FLY} -t ${TARGET} set-pipeline ${OPT_TEAM_NAME} -p ${PIPE_LINE_NAME} -l ${CREDENTIAL_YML} -l ${VARIABLE_YML} -c ${PIPE_LINE_YML}
