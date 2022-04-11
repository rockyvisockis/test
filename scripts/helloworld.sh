#!/bin/bash

apt-get update > /dev/null
DEBIAN_FRONTEND=noninteractive apt-get install apt-utils -y > /dev/null
DEBIAN_FRONTEND=noninteractive apt-get install -y curl > /dev/null
DEBIAN_FRONTEND=noninteractive apt-get install -y jq > /dev/null
apt-get -qq -y install jq > /dev/null

# Use API?
export CONCOURSEURL="https://concourse.at.sky"

export DOWLOADLINK="$CONCOURSEURL/api/v1/cli"

curl $DOWLOADLINK -G -d 'arch=amd64' -d 'platform=linux' -o 'fly'

mv fly /usr/local/bin
chmod 0755 /usr/local/bin/fly

/usr/local/bin/fly -t main login --team-name cec -c $CONCOURSEURL \
    --username "concourse" \
    --password "$concourse_user_secret" 

/usr/local/bin/fly -t main workers --json > workers.json


jq '.[] | select(.state == "retiring") | .name' workers.json > retiring.txt

RETIRING=$(cat retiring.txt)

if [ "$RETIRING" == null]; then
    echo "All workers are running correctly"
else
    echo "Workers stuck in retiring"


