cd ../../..
CWL="cwl/pindel_caller.Pindel_GermlineCaller.cwl"
YAML="testing/cwl_call/demo.yaml"

mkdir -p results
RABIX_ARGS="--basedir results"

rabix $RABIX_ARGS $CWL $YAML
