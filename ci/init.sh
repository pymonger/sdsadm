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
comp_dir=$(get_comp_dir ci)


# create log directories
mkdir -p $comp_dir/log


# setup etc directory
if [ -e "$comp_dir/etc" ]; then
  rsync -rptvzL $comp_dir/etc/ $comp_dir/etc.bak > /dev/null
else
  mkdir -p $comp_dir/etc
fi
mkdir -p $comp_dir/etc/conf.d


# setup jenkins directories
if [ -e "$HOME/jenkins" ]; then
  rsync -rptvzL $HOME/jenkins/ $HOME/jenkins.bak > /dev/null
else
  mkdir -p $HOME/jenkins
fi
if [ -e "$HOME/.jenkins" ]; then
  rsync -rptvzL $HOME/.jenkins/ $HOME/.jenkins.bak > /dev/null
else
  mkdir -p $HOME/.jenkins
fi


# copy global configs
cp -rp $prompt $BASE_PATH/config/datasets.json $comp_dir/etc/
cp -rp $prompt $BASE_PATH/config/supervisord.conf $comp_dir/etc/supervisord.conf


# copy component-specific configs
cp -rp $prompt ci/config/* $comp_dir/etc/
