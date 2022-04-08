#!/bin/bash

apt-get update > /dev/null
DEBIAN_FRONTEND=noninteractive apt-get install apt-utils -y > /dev/null
DEBIAN_FRONTEND=noninteractive apt-get install -y curl > /dev/null
apt-get -qq -y install jq > /dev/null

# Use API?
export CONCOURSEURL="https://concourse.at.sky"

export DOWLOADLINK="$CONCOURSEURL/api/v1/cli"

curl $DOWLOADLINK -G -d 'arch=amd64' -d 'platform=linux' -o 'fly'

mv fly /usr/local/bin
chmod 0755 /usr/local/bin/fly

touch ~/.flyrc

fly -t cec-training login -c $CONCOURSEURL \
    --username "concourse" \
    --password "$concourse_user_secet" > login.txt

cat login.txt
