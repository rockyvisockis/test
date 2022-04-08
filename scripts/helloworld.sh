#!/bin/bash

apt-get update > /dev/null
DEBIAN_FRONTEND=noninteractive apt-get install apt-utils -y > /dev/null
DEBIAN_FRONTEND=noninteractive apt-get install -y curl > /dev/null
apt-get -qq -y install jq > /dev/null

# Vars
CONCOURSE_URL="https://concourse.at.sky"
CONCOURSE_USER="concourse"
CONCOURSE_PASS="$concourse_user_secret"
CONCOURSE_TARGET="cec-training"
FLY_ENDPOINT="/api/v1/cli?arch=amd64&platform=linux"
AUTH_ENDPOINT="/sky/login"

# Get fly binary
TMP_DIR=$(mktemp -d) && trap "rm -rf ${TMP_DIR}" EXIT
FLY_BIN="${TMP_DIR}/fly"
curl -o "${FLY_BIN}" "${CONCOURSE_URL}/api/v1/cli?arch=amd64&platform=linux"
chmod a+x "${FLY_BIN}"

COOKIE_FILE="${TMP_DIR}/cookie.txt"
AUTH2="$(curl -b ${COOKIE_FILE} -c ${COOKIE_FILE} -s -o /dev/null -L "${CONCOURSE_URL}${AUTH_ENDPOINT}" -D - | \
    grep "Location: /sky/issuer/auth" | cut -d ' ' -f 2 | tr -d '\r')"
curl -o /dev/null -s -b ${COOKIE_FILE} -c ${COOKIE_FILE} -L --data-urlencode "login=${CONCOURSE_USER}" \
    --data-urlencode "password=${CONCOURSE_PASS}" "${CONCOURSE_URL}${AUTH2}"
OAUTH_TOKEN=$(cat ${COOKIE_FILE} | grep 'skymarshal_auth' | grep -o 'Bearer .*$' | tr -d '"')
echo $OAUTH_TOKEN | $FLY_BIN -t $CONCOURSE_TARGET login -c $CONCOURSE_URL -n main