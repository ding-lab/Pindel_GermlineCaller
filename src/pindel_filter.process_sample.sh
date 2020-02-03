#/bin/bash

read -r -d '' USAGE <<'EOF'
Process pindel run output and generate VCF.

Usage: pindel_filter.process_sample.sh [options] pindel_sifted.dat reference pindel_config
 
Options:
-h: Print this help message
-d : Dry run - output commands but do not execute them
-V: Bypass filtering for CvgVafStrand 
-H: Bypass filtering for Homopolymer 

pindel_config is GenomeVIP config file for pindel_filter

Creates configuration file and calls GenomeVIP/pindel_filter.pl, which performs the following:
1. apply CvgVafStrand Filter (coverage) to pindel output
2. Convert reads to VCF
3. apply homopolymer filter

Output filenames:
    OUTD/... config
    OUTD/pindel_raw.CvgVafStrand_pass.Homopolymer_pass.vcf

Note that OUTD is the same directory as the input data

EOF

# based on TinDaisy-Core/src/parse_pindel.pl

source /opt/Pindel_GermlineCaller/src/utils.sh
SCRIPT=$(basename $0)

PERL="/usr/bin/perl"
PINDELD="/usr/local/pindel"
GVIP_FILTER="/usr/local/TinDaisy-Core/src/GenomeVIP/pindel_filter.pl"

# Set defaults
OUTVCF="final.SV.WGS.vcf"

# http://wiki.bash-hackers.org/howto/getopts_tutorial
while getopts ":hdVH" opt; do
  case $opt in
    h)
      echo "$USAGE"
      exit 0
      ;;
    d)  # binary argument
      DRYRUN=1
      ;;
    V)  # binary argument
      BYPASS_CVS=1
      ;;
    H)  # binary argument
      BYPASS_HOMOPOLYMER=1
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

function make_config_genomevip {
    INFN=$1
    REF=$2
    CONFIG_TEMPLATE=$3
    CONFIG=$4

    # Set up parse_pindel configuration file.  It takes CONFIG_TEMPLATE and adds several lines to it
    >&2 echo Making $CONFIG from $CONFIG_TEMPLATE

    if [ $BYPASS_CVS ]; then
        BYPASS_CVS_STR="pindel.filter.skip_filter1 = true"
    fi
    if [ $BYPASS_HOMOPOLYMER ]; then
        BYPASS_HOMOPOLYMER_STR="pindel.filter.skip_filter2 = true"
    fi

    cp $CONFIG_TEMPLATE $CONFIG ; test_exit_status
    cat << EOF >> $CONFIG
pindel.filter.pindel2vcf = $PINDELD/pindel2vcf
pindel.filter.variants_file = $INFN
pindel.filter.REF = $REF
pindel.filter.date = 000000
$BYPASS_CVS_STR
$BYPASS_HOMOPOLYMER_STR
EOF
}

if [ "$#" -ne 3 ]; then
    >&2 echo Error: Wrong number of arguments
    >&2 echo "$USAGE"
    exit 1
fi

INFN=$1 ; confirm $INFN
REF=$2 ; confirm $REF
CONFIG_TEMPLATE=$3 ; confirm $PINDEL_CONFIG

OUTD=$(dirname $INFN)
# Filter script imposes this
FNOUT=$(basename $INFN)

CONFIG="$OUTD/pindel_germline_filter_config.dat"
make_config_genomevip $INFN $REF $CONFIG_TEMPLATE $CONFIG


CMD="$PERL $GVIP_FILTER $CONFIG"
run_cmd "$CMD" $DRYRUN

>&2 echo $SCRIPT success.
>&2 echo Written INDEL to $OUTD/$FNOUT.CvgVafStrand_pass.Homopolymer_pass.vcf
