#/bin/bash

read -r -d '' USAGE <<'EOF'
Process pindel run output and generate VCF.

Usage: pindel_filter.process_sample.sh [options] pindel_sifted.out reference pindel_config_template
 
Options:
-h: Print this help message
-d : Dry run - output commands but do not execute them
-V: Bypass filtering for CvgVafStrand 
-H: Bypass filtering for Homopolymer 
-o: output directory.  By default, same directory as the input data

pindel_config is GenomeVIP config file for pindel_filter

Creates configuration file and calls GenomeVIP/pindel_filter.pl, which performs the following:
1. apply CvgVafStrand Filter (coverage) to pindel output
2. Convert reads to VCF
3. apply homopolymer filter

Output filenames:
    OUTD/pindel_germline_filter_config.dat
    OUTD/pindel_sifted.out.CvgVafStrand_pass.Homopolymer_pass.vcf

GenomeVIP pindel_filter configuration file consists of two parts:
  * template lines obtained from pindel_config_template
  * run-specific lines generated here

Example pindel_config_template:
    pindel.filter.heterozyg_min_var_allele_freq = 0.2
    pindel.filter.homozyg_min_var_allele_freq = 0.8
    pindel.filter.mode = germline
    pindel.filter.apply_filter = true
    pindel.filter.germline.min_coverages = 10
    pindel.filter.germline.min_var_allele_freq = 0.20
    pindel.filter.germline.require_balanced_reads = true
    pindel.filter.germline.remove_complex_indels = true
    pindel.filter.germline.max_num_homopolymer_repeat_units = 6
EOF

# based on TinDaisy-Core/src/parse_pindel.pl

source /opt/Pindel_GermlineCaller/src/utils.sh
SCRIPT=$(basename $0)

PERL="/usr/bin/perl"
PINDELD="/usr/local/pindel"
GVIP_FILTER="/opt/Pindel_GermlineCaller/src/pindel_filter.pl"

# http://wiki.bash-hackers.org/howto/getopts_tutorial
while getopts ":hdVHo:" opt; do
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
    o)  
      OUTD="$OPTARG"
      SET_OUTD=1
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
    if [ $SET_OUTD ]; then
	mkdir -p $OUTD
	test_exit_status
        OUTD_STR="pindel.filter.output_dir = $OUTD"
    fi

    cp $CONFIG_TEMPLATE $CONFIG ; test_exit_status
    cat << EOF >> $CONFIG
pindel.filter.pindel2vcf = $PINDELD/pindel2vcf
pindel.filter.variants_file = $INFN
pindel.filter.REF = $REF
pindel.filter.date = 000000
$BYPASS_CVS_STR
$BYPASS_HOMOPOLYMER_STR
$OUTD_STR
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

if [ -z $OUTD]; then
    OUTD=$(dirname $INFN)
fi
# Filter script imposes this
FNOUT=$(basename $INFN)

CONFIG="$OUTD/pindel_germline_filter_config.dat"
make_config_genomevip $INFN $REF $CONFIG_TEMPLATE $CONFIG


CMD="$PERL $GVIP_FILTER $CONFIG"
run_cmd "$CMD" $DRYRUN

>&2 echo $SCRIPT success.
>&2 echo Written INDEL to $OUTD/${FNOUT}.CvgVafStrand_pass.Homopolymer_pass.vcf
