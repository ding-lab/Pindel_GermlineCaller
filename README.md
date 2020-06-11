# Pindel_GermlineCaller

Pindel germline calling proceeds in several steps:

1. `pindel_caller.Pindel_GermlineCaller.cwl`
    A. pindel run generates raw files (`pindel_*D`, etc)
        * these may be run per chromosome by passing CHRLIST file
        * performed by `pindel_caller.process_sample.sh`
        * Default arguments passed to Pindel: "-x 4 -I -B 0 -M 3"
    B. Running `grep ChrID` on raw data generates one "sifted" file, `pindel_sifted.out`
        * performed by `pindel_caller.process_sample_parallel.sh`
2. `pindel_filter.Pindel_GermlineCaller.cwl`: 
    A. `GenomeVIP/pindel_filter.pl` then filters the sifted file to generate a VCF file
        i. apply CvgVafStrand Filter (coverage) to pindel output
        ii. Convert reads to VCF
        iii. apply homopolymer filter
    B. performed by `pindel_filter.process_sample.sh`


CHRLIST is a file listing genomic intervals over which to operate, with each
line passed to `pindel -c`.  Raw output from multiple chromsomes is merged in
the `grep` step.  Generally, a listing of all chromosomes will suffice

In general, if CHRLIST is defined, jobs will be submitted in parallel mode: use
GNU parallel to loop across all entries in CHRLIST, running -j JOBS at a time,
and wait until all jobs completed.  Output logs written to OUTD/logs/Pindel.$CHR.log
Parallel mode can be disabled with -j 0.

## Testing

`./testing` directory has demo data which can be quickly used to exercise different parts of pipeline
Pipeline can be called in 3 contexts:
* Direct, but entering docker container and running from command line 
* Docker, by invoking a docker run with the requested command
* CWL, using CWL workflow manager
  * Rabix and cromwell are supported

## Production

Setting `finalize` parameter to `true` will compress all intermediate files and logs

## Background

This pipeline closely based on https://github.com/ding-lab/GATK_GermlineCaller

## Further development

Pindel calling may fail silently due to inadequate memory (currently set at 28G in CWL)
This may be identified as no or too few calls for common chromosomes.  Example of this (8G run)
is / was in /gscmnt/gc2541/cptac3_analysis/cromwell-workdir/cromwell-executions/pindel_caller.Pindel_GermlineCaller.cwl/d54c10d0-3c99-49a8-bbb8-35c1dd491174/call-pindel_caller.Pindel_GermlineCaller.cwl/execution/output/logs
There, per-chrom logs Pindel_GermlineCaller.XXX.out.gz were truncated.  Most die immediately (3 lines output) but some go on for some number of loops

### `confirm_success` test

Because we are not catching out of memory errors with parallel, need to have test to confirm that the run succeeded.
This is done by evaluating the result file to confirm that it has reasonable representation of all chromosomes.


## Author

Matthew Wyczalkowski <m.wyczalkowski@wustl.edu>

