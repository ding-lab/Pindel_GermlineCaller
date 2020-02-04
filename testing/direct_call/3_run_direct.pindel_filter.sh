# Example command to run within docker.  Typically, start docker first with 0_start_docker.sh

DAT="output.parallel/pindel_sifted.out"
REF="/opt/Pindel_GermlineCaller/testing/demo_data/Homo_sapiens_assembly19.COST16011_region.fa"
CONFIG="/opt/Pindel_GermlineCaller/params/pindel_germline_filter_config.ini"
OUTD="filtered"

PROCESS="/opt/Pindel_GermlineCaller/src/pindel_filter.process_sample.sh"

bash $PROCESS "$@" -o $OUTD $DAT $REF $CONFIG

