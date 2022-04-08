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

fly -t cec-training login -c $CONCOURSEURL \
    --username "concourse" \
    --password "$concourse_user_secret" > "fly_login.txt"

case `grep -F "target saved" "fly_login.txt" >/dev/null; echo $?` in
  0)
    echo "Fly login ran successfully"
    cat "fly_login.txt"
    ;;
  1)
    echo "ERROR: Issued detected with fly login"
    cat "fly_login.txt"
    exit 1
    ;;
  *)
    echo "ERRROR: Some error occurred logging into fly"
    cat "fly_login.txt"
    exit 1
    ;;
esac

fly -t cec-training workers
