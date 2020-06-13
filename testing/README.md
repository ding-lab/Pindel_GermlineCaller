Several levels of calls available for testing

- direct\_call: Calling directly from within container
- docker\_call: Instantiate docker container and call scripts within it
- cwl\_call: Run rabix or Cromwell workflow manager to call CWL workflow
  * cwl\_call.orig - testing used in initial development
  * cwl\_call-MGI, -compute1 - simplified testing based on VEP_annotate
- demo\_data: simple demonstration data for testing varscan VCF file remapping

Before running Demo data, be sure to uncompress reference:
```
cd demo_data
tar -xvjf Homo_sapiens_assembly19.COST16011_region.fa.tar.bz2
```
