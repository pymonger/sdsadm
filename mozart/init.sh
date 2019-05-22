#!/bin/bash
BASE_PATH=$(dirname "${BASH_SOURCE}")
BASE_PATH=$(cd "${BASE_PATH}/.."; pwd)
source ${BASE_PATH}/funcs


# globals
comp_dir=$SDS_CLUSTER_DIR/mozart


# create log directories
mkdir -p $comp_dir/var/log/elasticsearch \
         $comp_dir/var/log/httpd \
         $comp_dir/var/log/rabbitmq \
         $comp_dir/var/log/redis


# create lib directories
mkdir -p $comp_dir/var/lib/elasticsearch/data \
         $comp_dir/var/lib/redis \
         $comp_dir/var/lib/rabbitmq


# copy configs
if [ ! -e "$comp_dir/etc" ]; then
  cp -rp mozart/config $comp_dir/etc
fi
