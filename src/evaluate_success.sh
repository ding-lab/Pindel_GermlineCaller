#/bin/bash

read -r -d '' USAGE <<'EOF'
Evaluate probable success of Pindel run by looking at output features

Usage: evaluate_success.sh [options] 

Options:
-h: Print this help message
-W: Print warning, do not exit if results suspect
-c CHRLIST: File listing genomic intervals over which to operate.  Required
-o OUTD: output directory
-P PINDEL_OUT: path to pindel_sifted.out.  Required

Pindel may run out of memory and exit silently, producing incomplete results with
no error warnings.  This script evaluates output data to confirm that variants are
found for every chromosome.  Exits with an error if some expected chromosomes are
missing

Creates list of counts of chromosomes seen "$OUTD/pindel_sifted.chrom.txt"

EOF

source /opt/Pindel_GermlineCaller/src/utils.sh
SCRIPT=$(basename $0)

OUTD="."

# http://wiki.bash-hackers.org/howto/getopts_tutorial
while getopts ":hWc:o:P:" opt; do
  case $opt in
    h)
      echo "$USAGE"
      exit 0
      ;;
    W)  # binary argument
      WARN_ONLY=1
      ;;
    c) 
      CHRLIST_FN=$OPTARG
      ;;
    o) 
      OUTD=$OPTARG
      ;;
    P) 
      PINDEL_OUT=$OPTARG
      ;;
    \?)
      >&2 echo "Invalid option: -$OPTARG"
      >&2 echo "$USAGE"
      exit 1
      ;;
    :)
      >&2 echo "Option -$OPTARG requires an argument."
      >&2 echo "$USAGE"
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))

confirm $CHRLIST_FN
CHRLIST=$(cat $CHRLIST_FN)

mkdir -p $OUTD
test_exit_status 

# Evaluate chromosomes seen in output and create list like,
#    9047 chr1
#    3900 chr10
CHRTEST="$OUTD/pindel_sifted.chrom.txt"
CMD="cut -f 4 $PINDEL_OUT | cut -f 2 -d ' ' | sort  | uniq -c > $CHRTEST"
run_cmd "$CMD" $DRYRUN

WARN_SEEN=0
for CHRX in $CHRLIST; do

# if CHRLIST looks like chr1:1-1000000, evaluate just chr1
    CHR=$(echo "$CHRX" | cut -f 1 -d ':')

    if ! grep -Fwq "$CHR" $CHRTEST; then
        if [ "$WARN_ONLY" ]; then
            >&2 echo $SCRIPT : WARNING : CONFIRM_SUCCESS test failed.  Chromosome $CHR not found in $PINDEL_OUT
            WARN_SEEN=1
        else
            >&2 echo $SCRIPT : ERROR : CONFIRM_SUCCESS test failed.  Chromosome $CHR not found in $PINDEL_OUT
            exit 1
        fi
    fi
done

test_exit_status 

if [ $WARN_SEEN == 0 ]; then
    >&2 echo CONFIRM_SUCCESS test succeeded
else
    >&2 echo CONFIRM_SUCCESS test had warnings.  Continuing
fi
