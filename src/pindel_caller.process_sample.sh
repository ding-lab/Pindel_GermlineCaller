#/bin/bash

read -r -d '' USAGE <<'EOF'
Run pindel germline variant caller to generate raw pindel output

Usage: process_sample.sh [options] reference.fa input.bam 
 
Options:
-h: Print this help message
-d: Dry run - output commands but do not execute them
-L INPUT_INTERVAL : One or more genomic intervals over which to operate
  This is passed verbatim to pindel -c INPUT_INTERVAL
-l INTERVAL_LABEL : A short label for interval, used for filenames.  Default is INPUT_INTERVAL
-s SAMPLE_NAME : Sample name as used in pindel configuration file [ "SAMPLE" ]
-o OUTD : Output directory [ ./output ]
-J CENTROMERE: optional bed file passed to pindel to exclude regions
-A PINDEL_ARGS: Arguments passed to Pindel.  Default: "-x 4 -I -B 0 -M 3"
-C CONFIG_FN: Config file to use instead of creating one here

Output filenames:
    OUTD/pindel_XXX* 
    OUTD/pindel_config.XXX.dat
where XXX is given by INTERVAL_LABEL
EOF

source /opt/Pindel_GermlineCaller/src/utils.sh
SCRIPT=$(basename $0)

PINDEL_BIN="/usr/local/pindel/pindel"

# Set defaults
OUTD="./output"
PINDEL_ARGS="-x 4 -I -B 0 -M 3"
SAMPLE_NAME="SAMPLE"

# http://wiki.bash-hackers.org/howto/getopts_tutorial
while getopts ":hdL:l:s:o:J:A:C:" opt; do
  case $opt in
    h)
      echo "$USAGE"
      exit 0
      ;;
    d)  # binary argument
      DRYRUN=1
      ;;
    L) # value argument
      INPUT_INTERVAL="$OPTARG"
      ;;
    l) # value argument
      INTERVAL_LABEL="$OPTARG"
      ;;
    s) # value argument
      SAMPLE_NAME="$OPTARG"
      ;;
    o) # value argument
      OUTD=$OPTARG
      ;;
    J)
      confirm $OPTARG
      CENTROMERE_ARG="-J $OPTARG"
      ;;
    A) # value argument
      PINDEL_ARGS="$OPTARG"
      ;;
    C) # value argument
      CONFIG_FN="$OPTARG"
      confirm $CONFIG_FN
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

function make_config_fn {
    CONFIG_FN=$1
    BAM=$2

    >&2 echo Writing configuration file $CONFIG_FN
    TAB="$(printf '\t')"
    cat << EOF > $CONFIG_FN
$BAM${TAB}500${TAB}$SAMPLE_NAME
EOF

}


if [ "$#" -ne 2 ]; then
    >&2 echo Error: Wrong number of arguments
    >&2 echo "$USAGE"
    exit 1
fi

REF=$1
BAM=$2

confirm $BAM
confirm $REF

# IX forms part of suffix of output filename
# If INTERVAL_LABEL is given, IX takes that value
# otherwise, get value from INPUT_INTERVAL
if [ "$INTERVAL_LABEL" ]; then
    IX="$INTERVAL_LABEL"
else
    IX="$INPUT_INTERVAL"
fi

if [ "$INPUT_INTERVAL" ]; then
    PINDEL_ARGS="$PINDEL_ARGS -c $INPUT_INTERVAL"
fi

LOGD="$OUTD/logs"
TMPD="$OUTD/tmp"
mkdir -p $OUTD ; test_exit_status
mkdir -p $LOGD ; test_exit_status
mkdir -p $TMPD ; test_exit_status

# Create default configuration file if one is not provided
if [ -z $CONFIG_FN ]; then
    CONFIG_FN="$OUTD/pindel_config.${IX}.dat"
    make_config_fn $CONFIG_FN $BAM
fi

# Run 

OUT_SUCCESS="$OUTD/pindel_${IX}.succeeded"
rm -f $OUT_SUCCESS

OUT="$OUTD/pindel_${IX}"

CMD="$PINDEL_BIN -f $REF -i $CONFIG_FN -o $OUT $PINDEL_ARGS $CENTROMERE_ARG "

run_cmd "$CMD" $DRYRUN

# Write out success file
CMD="echo Success > $OUT_SUCCESS"
run_cmd "$CMD" $DRYRUN

>&2 echo $SCRIPT $IX success
