#!/bin/bash

apt-get update 
DEBIAN_FRONTEND=noninteractive apt-get install apt-utils -y 
DEBIAN_FRONTEND=noninteractive apt-get install -y curl 
apt-get -qq -y install jq 


export CONCOURSEURL="https://concourse.at.sky"

export DOWLOADLINK="$CONCOURSEURL/api/v1/cli"

curl $DOWLOADLINK -G -d 'arch=amd64' -d 'platform=linux' -o 'fly'

mv fly /usr/local/bin
chmod 0755 /usr/local/bin/fly

/usr/local/bin/fly --target="main" login \
    --concourse-url $CONCOURSEURL \
    --username "concourse" --password "$concourse_user_secret" > "fly_login.txt"
