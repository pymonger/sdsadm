#!/bin/bash
set -ex
BASE_PATH=$(dirname "${BASH_SOURCE}")
BASE_PATH=$(cd "${BASE_PATH}/.."; pwd)
source ${BASE_PATH}/funcs


# prompt if overwriting
prompt="-i"


# parse options
PARAMS=""
while (( "$#" )); do
  case "$1" in
    -f|--force)
      prompt=""
      shift 1
      ;;
    --) # end argument parsing
      shift
      break
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS=$@
      break
      ;;
  esac
done


# set positional arguments in their proper place
eval set -- "$PARAMS"


# globals
comp_dir=$(get_comp_dir factotum)


# create log directories
mkdir -p $comp_dir/log


# setup etc directory
if [ -e "$comp_dir/etc" ]; then
  rsync -rptvzL $comp_dir/etc/ $comp_dir/etc.bak > /dev/null
else
  mkdir -p $comp_dir/etc
fi
mkdir -p $comp_dir/etc/conf.d


# copy global configs
cp -rp $prompt $BASE_PATH/config/datasets.json $comp_dir/etc/
cp -rp $prompt $BASE_PATH/config/supervisord.conf $comp_dir/etc/supervisord.conf
cp -rp $prompt $BASE_PATH/config/inet_http_server.conf $comp_dir/etc/conf.d/inet_http_server.conf


# copy component-specific configs
cp -rp $prompt factotum/config/* $comp_dir/etc/


# populate supervisord templates
for i in $(ls factotum/config/conf.d); do
  sed "s/__IPADDRESS_ETH0__/$IPADDRESS_ETH0/g" factotum/config/conf.d/$i | \
    sed "s/__FQDN__/$FQDN/g" > $comp_dir/etc/conf.d/$i
done
