# Example command to run within docker.  Typically, start docker first with 0_start_docker.sh

BAM="/data/HCC1954.NORMAL.30x.compare.COST16011_region.bam"
REF="/data/Homo_sapiens_assembly19.COST16011_region.fa"
#BAM="/gscmnt/gc7210/dinglab/medseq/shared/Users/mwyczalk/ad-hoc/demo-data/HCC1954.NORMAL.30x.compare.COST16011_region.bam"
#REF="/gscmnt/gc7210/dinglab/medseq/shared/Users/mwyczalk/ad-hoc/demo-data/Homo_sapiens_assembly19.COST16011_region.fa"

PROCESS="../../src/pindel_caller.process_sample_parallel.sh"

OUTD="output-parallel"
CHRLIST="../demo_data/chrlist.dat"

# -F : finalize run

bash $PROCESS "$@" -c $CHRLIST -F -o $OUTD $REF $BAM 

