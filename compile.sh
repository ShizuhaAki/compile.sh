#!/bin/bash
function showHelp {
cat <<EOF
compile.sh, a tiny script for compiling and testing simple C++ programs

Arguments:
  -h | --help               Show this help
  -f | --file FILE          The file to compile, without the .cpp suffix
  -i | --input-file FILE    Feed input to your program from FILE
  -c | --compare PATH       Batch compare with data in PATH
                            This option assumes that the input and output files
                            are named name_id.in and name_id.out, where name is 
                            the argument to -f and id increases from 1
  --sanitize                Use G++ sanitize options
  --verbose                 Be more talkative
  --version                 Print version and copyright information.

EOF
}
function showVersion {
cat <<EOF
compile.sh version 0.0.1,

Copyright (c) 2021, Shu Shang (Lily White)

This script is free software. You may redistribute it under the terms of the
GNU General Public License, either version 3, or, at your option, any later version.

This script is distributed in the hope that it will be useful, but 
WITHOUT ANY WARRANTY, not even the IMPLIED WARRANTY OF MERCHANTABILITY or 
FITNESS FOR A PARTICULAR PURPOSE, see the GPL for more information.

You should have received a copy of the GPL along with this script. If not, 
see https://gnu.org/licenses/gpl
EOF
}
mkdir -p $PWD/tmp;
# colors
# Kudos to StackOverflow contributors!
#normal=$(tput sgr0)                      # normal text
normal=$'\e[0m'                           # (works better sometimes)
bold=$(tput bold)                         # make colors bold/bright
red="$bold$(tput setaf 1)"                # bright red text
green=$(tput setaf 2)                     # dim green text
fawn=$(tput setaf 3); beige="$fawn"       # dark yellow text
yellow="$bold$fawn"                       # bright yellow text
darkblue=$(tput setaf 4)                  # dim blue text
blue="$bold$darkblue"                     # bright blue text
purple=$(tput setaf 5); magenta="$purple" # magenta text
pink="$bold$purple"                       # bright magenta text
darkcyan=$(tput setaf 6)                  # dim cyan text
cyan="$bold$darkcyan"                     # bright cyan text
gray=$(tput setaf 7)                      # dim white text
darkgray="$bold"$(tput setaf 0)           # bold black = dark gray text
white="$bold$gray"                        # bright white text
# argparse
if [ "$#" = 0 ];
then
  showHelp;
  exit 1;
fi;
while [[ $# -gt 0 ]];
do
  i=$1;
  case $i in
    --sanitize)
      SANITIZE=1;
      shift;
      ;;
    --verbose)
      VERBOSE=1;
      shift;
      ;;
    -f|--file)
      FILE="$2";
      shift;
      shift;
      ;;
    -i|--input-file)
      INPUT="$2";
      USE_INPUT="1";
      shift;
      shift;
      ;;
    -h|--help)
      showHelp;
      exit 0;
      ;;
    -v|--version)
      showVersion;
      exit 0;
      ;;
    -c|--compare)
      COMPARE="1";
      CMPPATH="$2";
      shift;
      shift;
      ;;
    *)
      echo "${red}bad usage: unrecognized argument "$1" ${normal}";
      exit 1;
      ;;
  esac;
done;
set -- "${POSITIONAL[@]}" # restore positional parameters
# === CLI argument checking ===
if [ "$SANITIZE" = "1" ];
then 
  g++ -DLILYWHITE -fsanitize=undefined -fsanitize=address $FILE.cpp -o $PWD/tmp/$FILE -std=c++14 -g3 -Wall -Wextra 2> $PWD/tmp/compiler_output;
  echo "${bold}${purple}note: ${normal}You are using sanitize mode, program execution time will be considerably longer."
else
  g++ -DLILYWHITE $FILE.cpp -o $PWD/tmp/$FILE -std=c++14 -g3 -Wall -Wextra 2> $PWD/tmp/compiler_output;
fi;
if [ "$USE_INPUT" = "1" ] && [ "$COMPARE" = "1" ];
then
  echo "${red}bad usage: -i | --input-file contradicts with -c | --compare${normal}";
  exit 1;
fi;
# === Environment sanity checking ===

if [ $(grep error $PWD/tmp/compiler_output | wc -l) -ge 1 ];
then 
  if [ "$VERBOSE" = "1" ];
  then 
    cat $PWD/tmp/compiler_output;
  else
    cat $PWD/tmp/compiler_output | grep error;
  fi;
  echo "${red}Compile Error${normal}";
  exit 1;
else 
  if [ $(grep warning $PWD/tmp/compiler_output | wc -l) -ge 1 ];
  then
    cat $PWD/tmp/compiler_output | grep warning;
    echo "${fawn}Compilation Successful, with warnings${normal}";
  else
    echo "${green}Compilation Successful${normal}";
  fi;
fi;
if [ "$COMPARE" = "1" ];
then
  i=0;
  while true;
  do
    i=$(expr $i + 1);
    input=${CMPPATH}${FILE}_$i.in;
    output=${CMPPATH}${FILE}_$i.out;
    if [ -f "$input" ] && [ -f "$output" ];
    then
      $PWD/tmp/$FILE < $input > "user_out.txt";
      tput el;
      if diff -q "user_out.txt" $output;
      then
        echo "${green}✔ Accepted${normal} on test ${bold}#$i${normal}";
      else
        echo "${red}✘ Wrong Answer${normal} on test ${bold}#$i${normal}";
      fi;
    else
      exit 0;
    fi;
  done;
fi;
if [ "$USE_INPUT" = "1" ];
then
  time $PWD/tmp/$FILE < $INPUT;
else
  time $PWD/tmp/$FILE;
fi;

rm -rf $PWD/tmp;