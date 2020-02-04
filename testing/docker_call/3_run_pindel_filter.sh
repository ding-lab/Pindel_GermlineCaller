source ../../docker/docker_image.sh

DATD="../demo_data"
OUTD="./output"


DAT="/output/pindel_sifted.out"
REF="/data/Homo_sapiens_assembly19.COST16011_region.fa"
CONFIG="/data/pindel_germline_filter_config.ini"
PROCESS="/opt/Pindel_GermlineCaller/src/pindel_filter.process_sample.sh"

# Using python to get absolute path of DATD.  On Linux `readlink -f` works, but on Mac this is not always available
# see https://stackoverflow.com/questions/1055671/how-can-i-get-the-behavior-of-gnus-readlink-f-on-a-mac
ADATD=$(python -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' $DATD)
AOUTD=$(python -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' $OUTD)

# /output in container maps to $OUTD on host
ARG="-o /output"
CMD=" bash $PROCESS "$@" $DAT $REF $CONFIG"
DCMD="docker run -v $ADATD:/data -v $AOUTD:/output -it $IMAGE $CMD"
>&2 echo Running: $DCMD
eval $DCMD


