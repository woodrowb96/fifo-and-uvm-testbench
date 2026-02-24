#!/bin/bash

#Get projects root directory
PROJECT_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

#scripts dir
XSIM_SCRIPTS_DIR="$PROJECT_ROOT_DIR/scripts/xsim"
FILE_LIST_DIR="$XSIM_SCRIPTS_DIR/filelist"

#sim directories for xsim
SIM_DIR="$PROJECT_ROOT_DIR/sim"
XSIM_DIR="$SIM_DIR/xsim"
XSIM_WORKING_DIR="$XSIM_DIR/xsim.dir/work"

#make sure script is run only from the projects root directory
if [ "$(pwd)" != "$PROJECT_ROOT_DIR" ] ; then
  echo "Error: please run script from project root directory (where the script is located)"
  echo "Usage: run from $PROJECT_ROOT_DIR"
  exit 1
fi

#check for too many arguments
if [ $# -gt 1 ] ; then
  echo 'Error: too many arguments'
  echo "Usage: $SCRIPT_NAME <path-to-file>"
  exit 1
fi

#check if file to be compiled was given, else exit
if [ -z "$1" ] ; then
  echo 'Error: no file specified'
  echo "Usage: $SCRIPT_NAME <path-to-file>"
  exit 1
fi

#Check if sim directory exists at project root, if not the create it
if [ ! -d "$SIM_DIR" ] ; then
  echo "no simulation directory found"
  echo $'creating ./sim directory\n'
  mkdir -p "$SIM_DIR"
fi

#Check if xsim directory exists in sim dir, if not create it
if [ ! -d "$XSIM_DIR" ] ; then
  echo "no xsim directory found"
  echo $'creating ./sim/xsim directory\n'
  mkdir -p "$XSIM_DIR"
fi

#---------  see if we have a filelist of dependencies -----------------

MODULE_NAME="$1"
MODULE_NAME=${MODULE_NAME##*/}
MODULE_NAME=${MODULE_NAME%.*}

if [[ -f "$FILE_LIST_DIR/$MODULE_NAME.f" ]] ; then
  FILE_LIST="$FILE_LIST_DIR/$MODULE_NAME.f"
  echo $'\n'
  echo "COMPILING FILELIST: $MODULE_NAME.f"
  echo $'\n'
  xvlog -sv -L uvm --work work="$XSIM_WORKING_DIR" -f "$FILE_LIST"
  if [ $? -ne 0 ] ; then
    echo $'\n'
    echo "WARNING $SCRIPT_NAME: $MODULE_NAME.f compilation failed"
  fi
else
  echo $'\n'
  echo "WARNING: no filelist $MODULE_NAME.f found"
fi

#-------------------- compile file ------------------------------

echo $'\n'
echo "COMPILING: $MODULE_NAME"
echo $'\n'
xvlog -sv -L uvm --work work="$XSIM_WORKING_DIR" "$PROJECT_ROOT_DIR/$1"
