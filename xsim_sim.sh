#!/usr/bin/env bash

#------------------------------   Help Messages  ----------------------------

#get script name
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

#Print usage message
print_usage() 
{
  cat <<EOF
Usage: $SCRIPT_NAME [options] <tb_file>

EOF
}

#Print options message
print_options() 
{
  cat <<EOF
Options:
  -h                    Display help message
  -g                    Run simulation using the gui
  -t  <tcl_file>         Specify a non-default tcl script to run simulation with

EOF
}

#Print help message
print_help() 
{
  print_usage
  print_options
  cat <<EOF
Description:
  Script will simulate the <tb_file> testbench.

  By default script will run the simulation in cli mode, and will attempt to use the
  testbench's default tcl file (tcl file named <tb_file>.tcl, located in tcl directory).
  If no default do file exists, simulation will run without a tcl file.

Note:
  Script should be placed in, and run from the projects root directory.

EOF
}

#--------------------Create some dir path variables -----------

#the root directory, where the sim scripts live
PROJECT_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#sim directories for xsim
SIM_DIR="$PROJECT_ROOT_DIR/sim"
XSIM_DIR="$SIM_DIR/xsim"
XSIM_WORKING_DIR="$XSIM_DIR/xsim.dir/work"

#scripts dir
SCRIPTS_DIR="$PROJECT_ROOT_DIR/scripts/xsim"

#--------------------  Make sure we are running in projects root directory  -----------

#make sure we are running only from projects root directory
#if not then exit script
if [ "$(pwd)" != "$PROJECT_ROOT_DIR" ] ; then
  echo "Error: Please run script from project root directory"
  print_usage
  exit 1
fi

#--------------------  Parse options -------------------------------------------

GUI_MODE="false"    #by default we dont run in CLI mode
TCL_FILE=""          #if -t flag isnt set, this will stay empty

while getopts ":hgt:" FLAG; do
  case "$FLAG" in
    g)
      GUI_MODE="true"
      ;;
    t)
      #check for valid do file
      if [[ "$OPTARG" == -* ]] ; then   #if arg is a flag, then we didnt pass a .tcl file
        echo "Error: -t missing tcl file"
        exit 1
      elif [[ "$OPTARG" != *.tcl ]] ; then   #make sure arg is a .tcl file
        echo "Error: -t invalid tcl file"
        exit 1
      fi

      #get absolute path to tcl file
      TCL_FILE="$(cd "$(dirname "$OPTARG")" && pwd)/$(basename "$OPTARG")"
      ;;
    h)
      print_help
      exit 0
      ;;
    :)
      echo "Error: missing option argument -$OPTARG"
      exit 1
      ;;
    \?)
      echo "Error: unknown option -$OPTARG"
      exit 1
      ;;
  esac
done

#shift to the remaining arguments
shift $((OPTIND-1))


#-------------------- process test_bench argument  -----------------------------------

#check for too many arguments
if [ $# -gt 1 ] ; then
  echo 'Error: too many arguments'
  print_usage
  exit 1
fi

#check if file testbench file was given
if [ -z "$1" ] ; then
  echo 'Error: no testbench file specified'
  print_usage
  exit 1
fi

#get test bench from passed arg, and strip its path and file extension
TEST_BENCH_PATH="$1"
TEST_BENCH=${TEST_BENCH_PATH##*/}  #strip path from TEST_BENCH
TEST_BENCH=${TEST_BENCH%.*}   #strip .sv from TEST_BENCH


#-------------------- get correct do file ------------------------------------------

#get do file
if [[ ! -n "$TCL_FILE" ]] ; then   #if a tcl file was not set by the -t flag
  if [[ -f "$SCRIPTS_DIR/$TEST_BENCH.tcl" ]] ; then  #if default tcl file exists
    TCL_FILE="$SCRIPTS_DIR/$TEST_BENCH.tcl"   #get abs path to tcl file
  fi
fi

#----------------  get correct filelist file ---------------------------------------

#make sure we have a filelist
if [[ -f "$SCRIPTS_DIR/filelist/$TEST_BENCH.f" ]] ; then
  FILE_LIST="$SCRIPTS_DIR/filelist/$TEST_BENCH.f"
else
  echo $'\n'
  echo "ERROR MISSING FILELIST: $TEST_BENCH.f"
  exit 1
fi

#-------------------- ensure sim directory exists      ------------------------------

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

#-------------------- compile filelist dependencies ----------------

echo "COMPILING FILELIST DEPENDENCIES: $FILE_LIST"
echo $'\n'
xvlog -sv -L uvm --work work="$XSIM_WORKING_DIR" --log "$XSIM_DIR/xvlog.log" -f "$FILE_LIST"

#If we failed to compile the dependencies, then dont run the sim
if [ $? -ne 0 ] ; then
  echo $'\n'
  echo "ERROR $SCRIPT_NAME: $FILE_LIST compilation failed"
  exit 1
fi
echo $'\n'


#-------------------- compile test_bench ------------------------------

echo "COMPILING TEST BENCH: $TEST_BENCH"
echo $'\n'
xvlog -sv -L uvm --work work="$XSIM_WORKING_DIR" --log "$XSIM_DIR/xvlog.log" "$PROJECT_ROOT_DIR/$TEST_BENCH_PATH"

#If we failed to compile the tb, then dont run the sim
if [ $? -ne 0 ] ; then
  echo $'\n'
  echo "ERROR $SCRIPT_NAME: $TEST_BENCH compilation failed"
  exit 1
fi
echo $'\n'

#-------------------- elaborate test_bench ------------------------------

cd "$XSIM_DIR" || exit 1

echo "ELABORATING TEST BENCH: $TEST_BENCH"
echo $'\n'
xelab -L uvm $TEST_BENCH -debug typical

#If we failed the elaboration, then dont run the sim
if [ $? -ne 0 ] ; then
  echo $'\n'
  echo "ERROR $SCRIPT_NAME: elaboration failed"
  exit 1
fi
echo $'\n'

# #-------------------- run the simulation    ------------------------------

echo "SIMULATING TEST BENCH: $TEST_BENCH"
echo $'\n'

#create do command
TCL="$TCL_FILE"               #by default use the TCL file
if [[ ! -n "$TCL" ]] ; then  #but if there is none, then just run -all
  echo "WARNING:  Default TCL file ($TEST_BENCH.tcl) not found."
  echo "          Running sim with no tcl file"
  echo $'\n'
fi

#run in cli or in gui
if [ "$GUI_MODE" = "true" ] ; then        #if we are in gui mode
  if [ -n "$TCL" ] ; then
    xsim $TEST_BENCH -gui -tclbatch "$TCL"
  else
    xsim $TEST_BENCH -gui
  fi
else                                      #else we are in CLI mode
  if [ -n "$TCL" ] ; then
    xsim $TEST_BENCH -tclbatch "$TCL"
  else
    xsim $TEST_BENCH -runall
  fi
fi
