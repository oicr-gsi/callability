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
`intervalFile`|File|The interval file of regions to calculate callability on.


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


## Niassa + Cromwell

This WDL workflow is wrapped in a Niassa workflow (https://github.com/oicr-gsi/pipedev/tree/master/pipedev-niassa-cromwell-workflow) so that it can used with the Niassa metadata tracking system (https://github.com/oicr-gsi/niassa).

* Building
```
mvn clean install
```

* Testing
```
mvn clean verify \
-Djava_opts="-Xmx1g -XX:+UseG1GC -XX:+UseStringDeduplication" \
-DrunTestThreads=2 \
-DskipITs=false \
-DskipRunITs=false \
-DworkingDirectory=/path/to/tmp/ \
-DschedulingHost=niassa_oozie_host \
-DwebserviceUrl=http://niassa-url:8080 \
-DwebserviceUser=niassa_user \
-DwebservicePassword=niassa_user_password \
-Dcromwell-host=http://cromwell-url:8000
```

## Support

For support, please file an issue on the [Github project](https://github.com/oicr-gsi) or send an email to gsi@oicr.on.ca .

_Generated with generate-markdown-readme (https://github.com/oicr-gsi/gsi-wdl-tools/)_
