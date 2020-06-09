class: CommandLineTool
cwlVersion: v1.0
$namespaces:
  sbg: 'https://www.sevenbridges.com/'
id: pindel_caller
baseCommand:
  - /bin/bash
  - /opt/Pindel_GermlineCaller/src/pindel_caller.process_sample_parallel.sh
inputs:
  - id: reference
    type: File
    inputBinding:
      position: 1
    label: Reference FASTA
    secondaryFiles:
      - .fai
      - ^.dict
  - id: bam     # this will not currently process CRAM
    type: File
    inputBinding:
      position: 2
    label: Input BAM
    secondaryFiles:
      - >-
        ${if (self.nameext === ".bam") {return self.basename + ".bai"} else
        {return self.basename + ".crai"}}
  - id: chrlist
    type: File?
    inputBinding:
      position: 0
      prefix: '-c'
    doc: List of genomic regions
    label: Genomic regions
  - id: njobs
    type: int?
    inputBinding:
      position: 0
      prefix: '-j'
    label: N parallel jobs
    doc: Number of jobs to run in parallel mode
  - id: dryrun
    type: boolean?
    inputBinding:
      position: 0
      prefix: '-d'
    label: dry run
    doc: 'Print out commands but do not execute, for testing only'
  - id: finalize
    type: boolean?
    inputBinding:
      position: 0
      prefix: '-F'
    label: finalize
    doc: Compress intermediate data and logs
  - id: pindel_args
    type: string?
    inputBinding:
      position: 0
      prefix: '-A'
    label: Pindel arguments
    doc: Arguments passed to pindel
  - id: sample_name
    type: string?
    inputBinding:
      position: 0
      prefix: '-s'
    doc: Sample name as used in pindel configuration file (default SAMPLE)
    label: Sample name
  - id: centromere
    type: File?
    inputBinding:
      position: 0
      prefix: '-J'
    doc: Exclude regions like centromeres from processing
    label: exclude BED
  - id: config_fn
    type: File?
    inputBinding:
      position: 0
      prefix: '-C'
    doc: Pindel config file to use instead of creating one
    label: pindel config
outputs:
  - id: pindel_sifted
    type: File
    outputBinding:
      glob: output/pindel_sifted.out
label: Pindel Caller
requirements:
  - class: ResourceRequirement
    ramMin: 28000
  - class: DockerRequirement
    dockerPull: 'mwyczalkowski/pindel_germlinecaller:20200608'
  - class: InlineJavascriptRequirement
