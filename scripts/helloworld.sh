#!/bin/bash

apt-get update > /dev/null
DEBIAN_FRONTEND=noninteractive apt-get install apt-utils -y > /dev/null
DEBIAN_FRONTEND=noninteractive apt-get install -y curl > /dev/null
apt-get -qq -y install jq > /dev/null


export DOWNLOADLINK="$concourseurl/api/v1/cli"

curl $DOWNLOADLINK -G -d 'arch=amd64' -d 'platform=linux' -o 'fly'

mv fly /usr/local/bin
chmod 0755 /usr/local/bin/fly

/usr/local/bin/fly -t main login --team-name cec -c $concourseurl \
    --username "concourse" \
    --password "$concourse_user_secret" 

/usr/local/bin/fly -t main workers --json > workers.json


jq '.[] | select(.state == "retiring") | .name' workers.json > retiring.txt


if [ -s retiring.txt ]; then
    echo "Workers stuck in 'retiring'"
    for worker in $(cat retiring.txt) ; do
        /usr/local/bin/fly -t main prune-worker --worker $worker >> file.txt
        
    done
    
    for outcome in $(cat file.txt)
    do

        case "$outcome" in
            pruned)
                echo "Workers have been pruned successfully" >> prune-info/pruned.txt   
                exit 0
                ;;
            
            *)
                echo "ERRROR: Some error occurred while prunning workers" >> prune-info/pruned.txt
                exit 1
                ;;
        esac
    done 

else
    echo "All workers are running" > prune-info/pruned.txt
    exit 0
fi
    
