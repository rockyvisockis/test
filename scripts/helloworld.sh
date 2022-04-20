#!/bin/bash

apt-get -qq update 
DEBIAN_FRONTEND=noninteractive apt-get -qq install apt-utils -y > /dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get -qq install -y curl > /dev/null 2>&1
apt-get -qq install jq -y > /dev/null 2>&1
apt-get -qq install awscli -y > /dev/null 2>&1


export DOWNLOADLINK="$concourse_url/api/v1/cli"

curl $DOWNLOADLINK -G -d 'arch=amd64' -d 'platform=linux' -o 'fly'

mv fly /usr/local/bin
chmod 0755 /usr/local/bin/fly

/usr/local/bin/fly -t main login --team-name cec -c $concourse_url \
    --username "concourse" \
    --password "$concourse_user_secret" 

/usr/local/bin/fly -t main workers --json > workers.json


jq '.[] | select(.state == "retiring") | .name' workers.json > retiring.txt


if [ -s retiring.txt ]; then
    echo "Workers stuck in 'retiring'"
    for worker in $(cat retiring.txt) ; do
        /usr/local/bin/fly -t main prune-worker --worker $worker >> prune-info/file.txt
    done

else
    echo "All workers are running" 
    touch prune-info/pruned.txt
    exit 0

fi
    
if [ $(cat file.txt | wc -l) -eq $(grep "pruned" file.txt | wc -l) ]; then
    cat prune-info/file.txt > prune-info/pruned.txt
    exit 0
else
    echo "There was an error while pruning workers" > prune-info/pruned.txt
    exit 1
fi