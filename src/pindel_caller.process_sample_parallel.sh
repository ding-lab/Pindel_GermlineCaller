#!/bin/bash

# Matthew Wyczalkowski <m.wyczalkowski@wustl.edu>
# https://dinglab.wustl.edu/

read -r -d '' USAGE <<'EOF'
Run pindel germline caller, possibly for multiple intervals in parallel,
and perform `grep ChrID` on output to generate one sifted output file

Usage: 
  process_sample_parallel.sh [options] REF BAM

Output: 
    OUTD/pindel_sifted.out

Options:
-h : print usage information
-d : dry-run. Print commands but do not execute them
-1 : stop after one iteration over CHRLIST
-c CHRLIST: File listing genomic intervals over which to operate
-j JOBS: if parallel run, number of jobs to run at any one time.  If 0, run sequentially.  Default: 4
-o OUTD: set output root directory.  Default ./output
-F : finalize run by compressing per-region output and logs
-s SAMPLE_NAME : Sample name as used in pindel configuration file [ "SAMPLE" ]
-J CENTROMERE: optional bed file passed to pindel to exclude regions
-C CONFIG_FN: Config file to use instead of creating one here
-K : confirm success by testing output to make sure all chromosomes represented
-W : print warning but do not exit if confirm success fails

The following arguments are passed to process_sample.sh directly:
-A PINDEL_ARGS: Arguments passed to Pindel.  Default: "-x 4 -I -B 0 -M 3"

The general procedure generally looks like,
  make_config > OUTD/pindel_config.dat
  pindel > OUTD/raw
  grep ChrID OUTD/raw > OUTD/pindel_sifted.out

CHRLIST is a file listing genomic intervals over which to operate, with each
line passed to `pindel -c`.  Raw output from multiple chromsomes is merged in
the `grep` step

In general, if CHRLIST is defined, jobs will be submitted in parallel mode: use
GNU parallel to loop across all entries in CHRLIST, running -j JOBS at a time,
and wait until all jobs completed.  Output logs written to OUTD/logs/Pindel.$CHR.log
Parallel mode can be disabled with -j 0.

If CHRLIST is defined and CONFIRM_SUCCESS (-K) is set, test pindel_sifted.out to make sure
all chromosomes are represented.  This is to deal with silent out of memory errors which
result in missing data.  

EOF

source /opt/Pindel_GermlineCaller/src/utils.sh
SCRIPT=$(basename $0)

# Background on `parallel` and details about blocking / semaphores here:
#    O. Tange (2011): GNU Parallel - The Command-Line Power Tool,
#    ;login: The USENIX Magazine, February 2011:42-47.
# [ https://www.usenix.org/system/files/login/articles/105438-Tange.pdf ]

# set defaults
NJOBS=4
DO_PARALLEL=0
OUTD="./output"
PROCESS="/bin/bash /opt/Pindel_GermlineCaller/src/pindel_caller.process_sample.sh"
EVALUATE_SUCCESS="/bin/bash /opt/Pindel_GermlineCaller/src/evaluate_success.sh"

# http://wiki.bash-hackers.org/howto/getopts_tutorial
while getopts ":hd1c:j:o:Fs:J:C:A:KW" opt; do
  case $opt in
    h)
      echo "$USAGE"
      exit 0
      ;;
    d)  # example of binary argument
      >&2 echo "Dry run" 
      DRYRUN=1
      ;;
    1) 
      JUSTONE=1
      ;;
    c) 
      CHRLIST_FN=$OPTARG
      DO_PARALLEL=1
      ;;
    j) 
      NJOBS=$OPTARG  
      ;;
    o) 
      OUTD=$OPTARG
      ;;
    F) 
      FINALIZE=1
      ;;
    s) 
      PS_ARGS="$PS_ARGS -s \"$OPTARG\""
      ;;
    J) 
      PS_ARGS="$PS_ARGS -J \"$OPTARG\""
      ;;
    C) 
      PS_ARGS="$PS_ARGS -C \"$OPTARG\""
      ;;
    A) 
      PS_ARGS="$PS_ARGS -A \"$OPTARG\""
      ;;
    K) 
      CONFIRM_SUCCESS=1
      ;;
    W) 
      CS_ARGS="$CS_ARGS -W"
      ;;
    \?)
      >&2 echo "$SCRIPT: ERROR: Invalid option: -$OPTARG"
      >&2 echo "$USAGE"
      exit 1
      ;;
    :)
      >&2 echo "$SCRIPT: ERROR: Option -$OPTARG requires an argument."
      >&2 echo "$USAGE"
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))

if [ "$#" -ne 2 ]; then
    >&2 echo ERROR: Wrong number of arguments
    >&2 echo "$USAGE"
    exit 1
fi

REF=$1;   confirm $REF
BAM=$2;   confirm $BAM

# Read CHRLIST_FN to get list of elements
# These were traditionally individual chromosomes, 
# but can be other regions as well
if [ $CHRLIST_FN ]; then
    confirm $CHRLIST_FN
    CHRLIST=$(cat $CHRLIST_FN)
    # Will need to merge multiple VCFs
else
    # Will not need to merge multiple VCFs
    CHRLIST="Final"
    NO_CHRLIST=1
fi
    
# Output, tmp, and log files go here
mkdir -p $OUTD

# raw output goes here
OUTDR="$OUTD/raw"
mkdir -p $OUTDR

LOGD="$OUTD/logs"
mkdir -p $LOGD

NOW=$(date)
MYID=$(date +%Y%m%d%H%M%S)

if [ $NJOBS == "0" ]; then 
    DO_PARALLEL=0
fi

if [ $DO_PARALLEL == 1 ]; then
    >&2 echo [ $NOW ]: Parallel run 
    >&2 echo . 	  Looping over $CHRLIST
    >&2 echo . 	  Parallel jobs: $NJOBS
    >&2 echo . 	  Log files: $LOGD
else
    >&2 echo [ $NOW ]: Single region at a time
    >&2 echo . 	  Looping over $CHRLIST
    >&2 echo . 	  Log files: $LOGD
fi

# CHRLIST newline-separated list of regions passed to Pindel -c 
for CHR in $CHRLIST; do
    NOW=$(date)
    >&2 echo \[ $NOW \] : Processing $CHR

    STDOUT_FN="$LOGD/Pindel_GermlineCaller.$CHR.out.gz"
    STDERR_FN="$LOGD/Pindel_GermlineCaller.$CHR.err"

    # core call to process_sample.sh
    if [ "$NO_CHRLIST" ]; then
        LARG="-l Final"
    else
        LARG="-L $CHR"
    fi

    CMD="$PROCESS $PS_ARGS -o $OUTDR $LARG $REF $BAM | gzip > $STDOUT_FN 2> $STDERR_FN"

    if [ $DO_PARALLEL == 1 ]; then
        JOBLOG="$LOGD/Pindel_GermlineCaller.$CHR.log"
        CMD=$(echo "$CMD" | sed 's/"/\\"/g' )   # This will escape the quotes in $CMD
        CMD="parallel --semaphore -j$NJOBS --id $MYID --joblog $JOBLOG --tmpdir $LOGD \"$CMD\" "
    fi

    run_cmd "$CMD" $DRYRUN

    if [ "$JUSTONE" ]; then
        >&2 echo Exiting after one
        break
    fi
done

if [ $DO_PARALLEL == 1 ]; then
    # this will wait until all jobs completed
    CMD="parallel --semaphore --wait --id $MYID"
    run_cmd "$CMD" $DRYRUN
fi

# Now parse pindel output to get pindel_sifted.out file
# testing for globs from https://stackoverflow.com/questions/2937407/test-whether-a-glob-has-any-matches-in-bash

PINDEL_OUT="$OUTD/pindel_sifted.out"

PATTERN="$OUTDR/pindel_*D $OUTDR/pindel_*SI $OUTDR/pindel_*INV $OUTDR/pindel_*TD"
if stat -t $PATTERN >/dev/null 2>&1; then
    CMD="grep -h ChrID $PATTERN > $PINDEL_OUT"
    run_cmd "$CMD" $DRYRUN
    >&2 echo Sifted pindel output : $PINDEL_OUT
else
    >&2 echo $SCRIPT : pindel : no output found matching $PATTERN
fi

# Evaluate success
>&2 echo DEBUG: CONFIRM_SUCCESS = $CONFIRM_SUCCESS
if [ ! "$NO_CHRLIST" ] && [ "$CONFIRM_SUCCESS" == 1 ]; then
    >&2 echo Running CONFIRM_SUCCESS
    CS_CMD="$EVALUATE_SUCCESS $CS_ARGS -c $CHRLIST_FN -o $OUTD -P $PINDEL_OUT"
    run_cmd "$CS_CMD" $DRYRUN
else
    >&2 echo Skipping CONFIRM_SUCCESS
fi

if [[ "$FINALIZE" ]] ; then

    TAR="$OUTD/raw.tar.gz"
    if [ -e $TAR ]; then
        >&2 echo WARNING: $TAR exists
        >&2 echo Skipping raw finalize
    else
        CMD="tar -zcf $TAR -C $OUTD raw && rm -rf $OUTDR"
        run_cmd "$CMD" $DRYRUN
        >&2 echo Intermediate output in $OUTDR is compressed as $TAR and deleted
    fi
fi

echo Final result written to $PINDEL_OUT

NOW=$(date)
>&2 echo [ $NOW ] $SCRIPT : SUCCESS
