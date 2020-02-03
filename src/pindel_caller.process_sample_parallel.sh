#!/bin/bash

# Matthew Wyczalkowski <m.wyczalkowski@wustl.edu>
# https://dinglab.wustl.edu/

read -r -d '' USAGE <<'EOF'
Run pindel germline caller, possibly for multiple intervals in parallel,
and generate one pindel output file

Usage: 
  process_sample_parallel.sh [options] REF BAM

Output: 
    OUTD/pindel.Final.out ???

Options:
-h : print usage information
-d : dry-run. Print commands but do not execute them
-1 : stop after iteration over CHRLIST
-c CHRLIST: File listing genomic intervals over which to operate
-j JOBS: if parallel run, number of jobs to run at any one time.  If 0, run sequentially.  Default: 4
-o OUTD: set output root directory.  Default ./output
-F : finalize run by compressing per-region output and logs
-s SAMPLE_NAME : Sample name as used in pindel configuration file [ "SAMPLE" ]
-J CENTROMERE: optional bed file passed to pindel to exclude regions
-C CONFIG_FN: Config file to use instead of creating one here
-D: Do not delete pindel temp files

The following arguments are passed to process_sample.sh directly:
-A PINDEL_ARGS: Arguments passed to Pindel.  Default: "-x 4 -I -B 0 -M 3"

For single region, calls look like,:
  pindel ...
  gatk SelectVariants -O Pindel.snp.Final.vcf -select-type SNP -select-type MNP 
  gatk SelectVariants -O Pindel.indel.Final.vcf -select-type INDEL

For multiple regions (specified by -c CHRLIST), calls are like,
  for CHR in CHRLIST
    gatk HaplotypeCaller -R REF -I BAM -L CHR
    gatk SelectVariants -O CHR_SNP -select-type SNP -select-type MNP 
    gatk SelectVariants -O CHR_INDEL -select-type INDEL
  bcftools concat -o Pindel.snp.Final.vcf
  bcftools concat -o Pindel.indel.Final.vcf

CHRLIST is a file listing genomic intervals over which to operate, with each
line passed to `pindel -c`. 

In general, if CHRLIST is defined, jobs will be submitted in parallel mode: use
GNU parallel to loop across all entries in CHRLIST, running -j JOBS at a time,
and wait until all jobs completed.  Output logs written to OUTD/logs/Pindel.$CHR.log
Parallel mode can be disabled with -j 0.

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
PROCESS="/opt/Pindel_GermlineCaller/src/pindel_caller.process_sample.sh"

# http://wiki.bash-hackers.org/howto/getopts_tutorial
while getopts ":hd1c:j:o:Fs:J:C:A:D:" opt; do
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
    D) 
      NO_DELETE_TEMP=1
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

# Per-region output goes here
if [ ! "$NO_CHRLIST" ]; then
    OUTDR="$OUTD/regions"
    mkdir -p $OUTDR
fi

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
        CMD="$PROCESS $PS_ARGS -o $OUTD -l Final $REF $BAM | gzip > $STDOUT_FN 2> $STDERR_FN"
    else
        CMD="$PROCESS $PS_ARGS -o $OUTDR -L $CHR $REF $BAM | gzip > $STDOUT_FN 2> $STDERR_FN"
    fi

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

# Now parse pindel output to get pindel-raw.out file
# testing for globs from https://stackoverflow.com/questions/2937407/test-whether-a-glob-has-any-matches-in-bash

PINDEL_OUT="$OUTD/pindel-raw.out"

PATTERN="$OUTDR/pindel_*D $OUTDR/pindel_*SI $OUTDR/pindel_*INV $OUTDR/pindel_*TD"
if stat -t $PATTERN >/dev/null 2>&1; then
    OUT="$OUTD/pindel-raw.out"
    CMD="grep -h $PATTERN > $OUT"
    run_cmd "$CMD" $DRYRUN
    >&2 echo Raw pindel output : $OUT
else
    >&2 echo $SCRIPT : pindel : no output found matching $PATTERN
fi


if [[ "$FINALIZE" ]] ; then

    LOGD="$OUTD/logs"
    TAR="$OUTD/logs.tar.gz"
    if [ -e $TAR ]; then
        >&2 echo WARNING: $TAR exists
        >&2 echo Skipping log finalize
    else
        CMD="tar -zcf $TAR $LOGD && rm -rf $LOGD"
        run_cmd "$CMD" $DRYRUN
        >&2 echo Logs in $LOGD is compressed as $TAR and deleted
    fi

    if [[ ! "$NO_CHRLIST" ]]; then
        TAR="$OUTD/regions.tar.gz"
        if [ -e $TAR ]; then
            >&2 echo WARNING: $TAR exists
            >&2 echo Skipping regions finalize
        else
            CMD="tar -zcf $TAR $OUTDR && rm -rf $OUTDR"
            run_cmd "$CMD" $DRYRUN
            >&2 echo Intermediate output in $OUTDR is compressed as $TAR and deleted
        fi
    fi
fi

if [[ $NO_DELETE_TEMP == 1 ]]; then
    >&2 echo Not deleting intermediate pindel files
else
    >&2 echo Deleting intermediate pindel files
    CMD="rm -f pindel_* pindel*out.gz"
    run_cmd "$CMD" $DRYRUN
    CMD="rm -rf tmp"
    run_cmd "$CMD" $DRYRUN
fi

echo Final result written to $PINDEL_OUT

NOW=$(date)
>&2 echo [ $NOW ] $SCRIPT : SUCCESS
