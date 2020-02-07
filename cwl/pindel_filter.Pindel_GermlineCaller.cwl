class: CommandLineTool
cwlVersion: v1.0
id: pindel_filter.Pindel_GermlineCaller
baseCommand:
  - /bin/bash
  - /opt/Pindel_GermlineCaller/src/pindel_filter.process_sample.sh
inputs:
  - id: pindel_sifted
    type: File
    inputBinding:
      position: 1
    label: Output of pindel_caller
  - id: reference
    type: File
    inputBinding:
      position: 2
    label: Reference FASTA
    secondaryFiles:
      - .fai
  - id: pindel_config_template
    type: File
    inputBinding:
      position: 3
    label: Pindel Config Template
  - id: dryrun
    type: boolean?
    inputBinding:
      position: 0
      prefix: '-d'
    label: dry run
    doc: 'Print out commands but do not execute, for testing only'
  - id: bypass_cvs
    type: boolean?
    inputBinding:
      position: 0
      prefix: '-V'
    label: bypass_cvs
    doc: 'Bypass filtering for CvgVafStrand'
  - id: compress_output
    type: boolean?
    inputBinding:
      position: 0
      prefix: '-I'
    label: Compress output
    doc: 'Compress and index output VCF files'
  - id: bypass_homopolymer
    type: boolean?
    inputBinding:
      position: 0
      prefix: '-H'
    label: bypass_homopolymer
    doc: 'Bypass filtering for Homopolymer'
outputs:
# output name is based on assumption that default filenames used
  - id: indel_vcf
    type: File
    outputBinding:
      glob: filtered/pindel_sifted.out.CvgVafStrand_pass.Homopolymer_pass.vcf
label: pindel_filter.Pindel_GermlineCaller
arguments:
  - position: 0
    prefix: '-o'
    valueFrom: filtered
requirements:
  - class: ResourceRequirement
    ramMin: 8000
  - class: DockerRequirement
    dockerPull: mwyczalkowski/pindel_germlinecaller
  - class: InlineJavascriptRequirement
