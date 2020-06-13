cd ../../..
CWL="cwl/pindel_filter.Pindel_GermlineCaller.cwl"
YAML="testing/cwl_call/pindel_filter.yaml"

mkdir -p results
RABIX_ARGS="--basedir results"

rabix $RABIX_ARGS $CWL $YAML
