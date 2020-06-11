# Example command to run within docker.  Typically, start docker first with 0_start_docker.sh

PINDEL_OUT="/data/ea295a9b-2f90-4ae6-9971-656b9c366a36/call-pindel_germline_caller/execution/output/pindel_sifted.out" # succeeded
#PINDEL_OUT="/data/43e5d709-d9dc-41ab-b91d-ae7c3f89217d/call-pindel_germline_caller/execution/output/pindel_sifted.out" # failed

#PROCESS="/opt/Pindel_GermlineCaller/src/evaluate_success.sh"
PROCESS="../../src/evaluate_success.sh"
CHRLIST="/gscuser/mwyczalk/projects/TinDaisy/TinDaisy/params/chrlist/GRCh38.d1.vd1.chrlist.txt"
OUTD="./output"

bash $PROCESS "$@" -c $CHRLIST -o $OUTD -P $PINDEL_OUT

