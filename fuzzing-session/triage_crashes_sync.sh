#!/bin/sh
#
# american fuzzy lop - crashes convergence utility
# -----------------------------------------
#

echo "simple crashes convergence utility for afl-fuzz"
echo "based on triage_crashes.sh worte by Michal Zalewski <lcamtuf@google.com>"
echo

ulimit -v 100000 2>/dev/null
ulimit -d 100000 2>/dev/null

if [ "$#" -lt "2" ]; then
  echo "Usage: $0 /path/to/afl_output_dir /path/to/tested_binary [...target params...]" 1>&2
  echo 1>&2
  exit 1
fi

DIR="$1"
BIN="$2"
shift
shift

if [ "$AFL_ALLOW_TMP" = "" ]; then

  echo "$DIR" | grep -qE '^(/var)?/tmp/'
  T1="$?"

  echo "$BIN" | grep -qE '^(/var)?/tmp/'
  T2="$?"

  if [ "$T1" = "0" -o "$T2" = "0" ]; then
    echo "[-] Error: do not use shared /tmp or /var/tmp directories with this script." 1>&2
    exit 1
  fi

fi

if [ ! -f "$BIN" -o ! -x "$BIN" ]; then
  echo "[-] Error: binary '$2' not found or is not executable." 1>&2
  exit 1
fi

subdircount=`find $DIR -maxdepth 1 -mindepth 1 -type d | wc -l`
SYNC=""

if [ -d "$DIR/queue" ]; then
	# need to test if DIR contains multiple directory and one (so all) 
  # verify existence DIR/queue too
  echo "Single output directory found"
  SYNC=0
elif [ ! $subdircount -eq 0 ]; then
  #For all subdirectories inside $DIR
  for d in $(find $DIR -maxdepth 1 -mindepth 1 -type d)
  do
    # echo $d
    if [ ! -d "$d/queue" ]; then
      # need to test if d contains multiple directory and one (so all) 
      # verify existence DIR/queue too
  
      echo "[-] Error: directory '$1' not found or not created by afl-fuzz." 1>&2
      exit 1
    fi
  done
  SYNC=1
else
	echo "[-] Error: directory '$1' not found or not created by afl-fuzz." 1>&2
  exit 1
fi


file1="crashes_output_convergence.txt"
file2="sorted_crashes_output_convergence.txt"

if [ -f $file1 ] ; then
    rm "$file1"
fi
if [ -f "$file2" ] ; then
    rm "$file2"
fi

# if [ ! -d "$DIR/queue" ]; then
#   # need to test if DIR contains multiple directory and one (so all) 
#   # verify existence DIR/queue too
#   echo "$DIR"
#   echo "what"
#   echo "$DIR/queue"
#   echo "[-] Error: directory '$1' not found or not created by afl-fuzz." 1>&2
#   exit 1
# else 
#   echo "$DIR"
#   echo "what"
#   echo "$DIR/queue"
# fi

# CCOUNT=$((`ls -- "$DIR/crashes" 2>/dev/null | wc -l`))

# if [ "$CCOUNT" = "0" ]; then
#   echo "No crashes recorded in the target directory - nothing to be done."
#   exit 0
# fi

echo

if [ "$SYNC" = "0" ]; then
  CCOUNT=$((`ls -- "$DIR/crashes" 2>/dev/null | wc -l`))

  if [ "$CCOUNT" = "0" ]; then
    echo "No crashes recorded in the target directory - nothing to be done."
    exit 0
  fi

  echo "Case single output"
  echo
  #if single output directory for crashes
  for crash in $DIR/crashes/id:*; do

  id=`basename -- "$crash" | cut -d, -f1 | cut -d: -f2`
  sig=`basename -- "$crash" | cut -d, -f2 | cut -d: -f2`

  # Grab the args, converting @@ to $crash

  use_args=""
  use_stdio=1

  for a in $@; do
    if [ "$a" = "@@" ] ; then
      args="$args $crash"
      unset use_stdio
    else
      args="$args $a"
    fi

  done

  # Strip the trailing space
  args="${args# }"

  echo "+++ ID $id, SIGNAL $sig +++ "
  echo "running $BIN $args :"


  # Passing one by one crashes to binary
  # Terminal output redirected to file

  if [ "$use_stdio" = "1" ]; then 
    # echo "Case 1"
    # echo "$args +++ $crash"
    $BIN $args $crash | sed -n 's/.*raised//p' >> $file1
  else
    # echo "Case 2"
    # echo "$args +++ $crash"
    $BIN $args | sed -n 's/.*raised//p' >> $file1
  fi
  echo

  #reset args
  args=""
done
else
  echo "Case synchronous output"
  echo

   # !!!! not working

  # CCOUNT=$((`ls -- "$DIR/*/crashes" 2>/dev/null | wc -l`))
  # echo $CCOUNT
  # if [ "$CCOUNT" = "0" ]; then
  # echo "No crashes recorded in the target directory - nothing to be done."
  # exit 0
  # fi

 

  for crash in $DIR/*/crashes/id:*; do

  id=`basename -- "$crash" | cut -d, -f1 | cut -d: -f2`
  sig=`basename -- "$crash" | cut -d, -f2 | cut -d: -f2`

  # Grab the args, converting @@ to $crash

  use_args=""
  use_stdio=1

  for a in $@; do
    if [ "$a" = "@@" ] ; then
      args="$args $crash"
      unset use_stdio
    else
      args="$args $a"
    fi

  done

  # Strip the trailing space
  args="${args# }"

  echo "+++ ID $id, SIGNAL $sig +++ "
  echo "running $BIN $args :"


  # Passing one by one crashes to binary
  # Terminal output redirected to file

  if [ "$use_stdio" = "1" ]; then 
    # echo "Case 1"
    echo "$args +++ $crash"
    $BIN $args $crash | sed -n 's/.*raised//p' >> $file1
  else
    # echo "Case 2"
    echo "$args +++ $crash"
    $BIN $args | sed -n 's/.*raised//p' >> $file1
  fi
  echo

  #reset args
  args=""
  
  done
fi


# Sort and count output file
cat $file1 | sort | uniq -c > $file2
