class: CommandLineTool
cwlVersion: v1.0
id: pindel_caller.Pindel_GermlineCaller
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
  - id: bam
    type: File
    inputBinding:
      position: 2
    label: Input BAM/CRAM
    secondaryFiles: ${if (self.nameext === ".bam") {return self.basename + ".bai"} else {return self.basename + ".crai"}}
  - id: chrlist
    type: File?
    inputBinding:
      position: 0
      prefix: '-c'
    label: List of genomic regions
  - id: njobs
    type: int?
    inputBinding:
      position: 0
      prefix: '-j'
    label: Parallel job count
    doc: 'Number of jobs to run in parallel mode'
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
    doc: 'Compress intermediate data and logs'
  - id: pindel_args
    type: string?
    inputBinding:
      position: 0
      prefix: '-A'
    label: 'Arguments passed to Pindel.  Default: "-x 4 -I -B 0 -M 3"'
  - id: sample_name
    type: string?
    inputBinding:
      position: 0
      prefix: '-s'
    label: 'Sample name as used in pindel configuration file.  Default: SAMPLE'
  - id: centromere
    type: File?
    inputBinding:
      position: 0
      prefix: '-J'
    label: optional bed file passed to pindel to exclude regions
  - id: config_fn
    type: File?
    inputBinding:
      position: 0
      prefix: '-C'
    label: Pindel config file to use instead of creating one
outputs:
  - id: pindel_sifted
    type: File
    outputBinding:
      glob: output/pindel_sifted.out
label: pindel_caller.Pindel_GermlineCaller
requirements:
  - class: ResourceRequirement
    ramMin: 28000
  - class: DockerRequirement
    dockerPull: mwyczalkowski/pindel_germlinecaller:20200608
  - class: InlineJavascriptRequirement
