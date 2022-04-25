#!/bin/bash

# Download dependencies
apt-get -qq update 
DEBIAN_FRONTEND=noninteractive apt-get -qq install apt-utils -y > /dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get -qq install curl -y > /dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get -qq install awscli -y 2> /dev/null
apt-get -qq install jq -y > /dev/null 2>&1



export DOWNLOADLINK="$concourse_url/api/v1/cli"
export AWS_ACCESS_KEY_ID="$access_key_id"
export AWS_SECRET_ACCESS_KEY="$secret_access_key"
export AWS_DEFAULT_REGION="eu-west-1"

aws --version
# Download and install fly cli
curl $DOWNLOADLINK -G -d 'arch=amd64' -d 'platform=linux' -o 'fly'

mv fly /usr/local/bin
chmod 0755 /usr/local/bin/fly


# Fly login to concourse
/usr/local/bin/fly -t main login --team-name cec -c $concourse_url \
    --username "concourse" \
    --password "$concourse_user_secret" 

# Worker status
/usr/local/bin/fly -t main workers --json > workers.json

# Querying for id's of retiring workers
jq '.[] | select(.state == "retiring") | .name' workers.json > retiring.txt



# Prune retiring workers and confirm ec2 status by using aws cli 
if [ -s retiring.txt ]; then
    echo "Workers stuck in 'retiring'"
    for worker in $(cat retiring.txt) ; do

        /usr/local/bin/fly -t main prune-worker --worker $worker >> file.txt

        aws ec2 describe-instances --filters "Name=private-ip-address,Values=$(echo $worker | tr -d 'aws-')" | jq -r .Reservations[0].Instances[0].InstanceId >> ec2.txt
         
    done
    for ec2 in $(cat ec2.txt) ; do

        aws ec2 terminate-instances --instance-ids $ec2 >> terminated.txt

        cat terminated.txt
    done
else
    echo "All workers are running" 
    touch prune-info/pruned.txt
    exit 0

fi

# Confirm if all the retiring workers were pruned successfully 
if [ $(cat file.txt | wc -l) -eq $(grep "pruned" file.txt | wc -l) ]; then
    sed 's/pruned/Pruned worker/g' file.txt > prune-info/pruned.txt
    exit 0
else
    echo "There was an error while pruning workers" > prune-info/pruned.txt
    exit 1
fi