# callability

Workflow to calculate the callability of a matched tumour sample, where callability is defined as the percentage of genomic regions where a normal and a tumor bam coverage is greater than a threshold(s).

## Overview

## Dependencies

* [mosdepth 0.2.9](https://github.com/brentp/mosdepth)
* [bedtools 2.27](https://bedtools.readthedocs.io/en/latest/)
* [python 3.7](https://www.python.org)


## Usage

### Cromwell
```
java -jar cromwell.jar run callability.wdl --inputs inputs.json
```

### Inputs

#### Required workflow parameters:
Parameter|Value|Description
---|---|---
`normalBam`|File|Normal bam input file.
`normalBamIndex`|File|Normal bam index input file.
`tumorBam`|File|Tumor bam input file.
`tumorBamIndex`|File|Tumor bam index input file.
`normalMinCoverage`|Int|Normal must have at least this coverage to be considered callable.
`tumorMinCoverage`|Int|Tumor must have at least this coverage to be considered callable.
`intervalFile`|String|The interval file of regions to calculate callability on.


#### Optional workflow parameters:
Parameter|Value|Default|Description
---|---|---|---


#### Optional task parameters:
Parameter|Value|Default|Description
---|---|---|---
`calculateCallability.threads`|Int|4|The number of threads to run mosdepth with.
`calculateCallability.outputFileNamePrefix`|String?|None|Output files will be prefixed with this.
`calculateCallability.outputFileName`|String|"callability_metrics.json"|Output callability metrics file name.
`calculateCallability.jobMemory`|Int|8|Memory allocated to job (in GB).
`calculateCallability.cores`|Int|1|The number of cores to allocate to the job.
`calculateCallability.timeout`|Int|12|Maximum amount of time (in hours) the task can run for.
`calculateCallability.modules`|String|"mosdepth/0.2.9 bedtools/2.27 python/3.7"|Environment module name and version to load (space separated) before command execution.


### Outputs

Output | Type | Description
---|---|---
`callabilityMetrics`|File|Json file with pass, fail and callability percent (# of pass bases / # total bases)


## Commands
 This section lists command(s) run by WORKFLOW workflow
 
 * Running WORKFLOW
 
 === Description here ===.
 
 <<<
   set -euo pipefail
 
   #export variables with mosdepth uses to add a fourth column to a new bed, merging neighboring regions if CALLABLE or LOW_COVERAGE
   export MOSDEPTH_Q0=LOW_COVERAGE
   export MOSDEPTH_Q1=CALLABLE
   mosdepth -t ~{threads} -n --quantize 0:~{normalMinCoverage - 1}: normal ~{normalBam}
   mosdepth -t ~{threads} -n --quantize 0:~{tumorMinCoverage - 1}: tumor ~{tumorBam}
   zcat normal.quantized.bed.gz | awk '$4 == "CALLABLE"' | bedtools intersect -a stdin -b ~{intervalFile} > normal.callable
   zcat tumor.quantized.bed.gz | awk '$4 == "CALLABLE"' | bedtools intersect -a stdin -b ~{intervalFile} > tumor.callable
 
   PASS="$(bedtools intersect -a normal.callable -b tumor.callable -wao | awk '{sum+=$9} END{print sum}')"
   TOTAL="$(zcat -f ~{intervalFile} | awk -F'\t' 'BEGIN{SUM=0}{SUM+=$3-$2} END{print SUM}')"
 
   python3 <<CODE
   import json
 
   total_count = int(float("${TOTAL}"))
   pass_count = int(float("${PASS}"))
   fail_count = total_count - pass_count
   if pass_count == 0 and fail_count == 0:
       callability = 0
   else:
       callability = pass_count / (pass_count + fail_count)
 
   metrics = {
       "pass": pass_count,
       "fail": fail_count,
       "callability": round(callability, 6),
       "normal_min_coverage": ~{normalMinCoverage},
       "tumor_min_coverage": ~{tumorMinCoverage}
   }
   with open('~{outputFileNamePrefix}~{outputFileName}', 'w') as json_file:
       json.dump(metrics, json_file)
   CODE
   >>>
 ## Support

For support, please file an issue on the [Github project](https://github.com/oicr-gsi) or send an email to gsi@oicr.on.ca .

_Generated with generate-markdown-readme (https://github.com/oicr-gsi/gsi-wdl-tools/)_
