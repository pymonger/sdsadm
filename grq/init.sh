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
comp_dir=$(get_comp_dir grq)


# create log directories
mkdir -p $comp_dir/log/elasticsearch \
         $comp_dir/log/httpd \
         $comp_dir/log/redis


# create lib directories
mkdir -p $comp_dir/var/lib/elasticsearch/data \
         $comp_dir/var/lib/redis


# initialize GRQ ES index with geonames pre-installed
es_cluster_data=$comp_dir/var/lib/elasticsearch/data/products_cluster
if [ ! -d "$es_cluster_data" ]; then
  pwd=$PWD
  tmp_dir=/tmp/.tmp_$$
  mkdir -p $tmp_dir
  cd $tmp_dir
  git clone https://github.com/hysds/puppet-grq.git
  cd puppet-grq/files
  cat elasticsearch-data.tbz2.* > elasticsearch-data.tbz2 
  tar xvfj elasticsearch-data.tbz2
  mv elasticsearch/products_cluster $es_cluster_data
  cd $pwd
  rm -rf $tmp_dir
fi


# setup etc directory
if [ -e "$comp_dir/etc" ]; then
  rsync -rptvzL $comp_dir/etc/ $comp_dir/etc.bak > /dev/null
else
  mkdir -p $comp_dir/etc
fi
mkdir -p $comp_dir/etc/conf.d


# increase limits
sudo cp -rp $prompt $BASE_PATH/config/10-hysds.conf /etc/sysctl.d/
sudo sysctl --system


# copy global configs
cp -rp $prompt $BASE_PATH/config/datasets.json $comp_dir/etc/
cp -rp $prompt $BASE_PATH/config/logging.yml $comp_dir/etc/
cp -rp $prompt $BASE_PATH/config/redis-config $comp_dir/etc/
cp -rp $prompt $BASE_PATH/config/inet_http_server.conf $comp_dir/etc/conf.d/inet_http_server.conf


# copy component-specific configs
cp -rp $prompt grq/config/* $comp_dir/etc/


# populate supervisord templates
for i in $(ls grq/config/conf.d); do
  sed "s/__IPADDRESS_ETH0__/$IPADDRESS_ETH0/g" grq/config/conf.d/$i | \
    sed "s/__FQDN__/$FQDN/g" > $comp_dir/etc/conf.d/$i
done
