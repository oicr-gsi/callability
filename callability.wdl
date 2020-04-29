version 1.0

workflow callability {

  input {
    File normalBam
    File tumorBam
    Int normalMinCoverage
    Int tumorMinCoverage
    String referenceFile
    String? intervalFile
  }

  call bedtoolsCoverage {
    input:
      normalBam=normalBam,
      tumorBam=tumorBam,
      normalMinCoverage=normalMinCoverage,
      tumorMinCoverage=tumorMinCoverage,
      referenceFile=referenceFile,
      intervalFile=intervalFile
  }

  output {
    File callabilityMetrics = bedtoolsCoverage.callabilityMetrics
  }
}

task bedtoolsCoverage {
  input {
    File normalBam
    File tumorBam
    Int normalMinCoverage
    Int tumorMinCoverage
    String referenceFile
    String? intervalFile
    String outputFileName = "callability_metrics.json"
    Int jobMemory = 8
    Int cores = 1
    Int timeout = 12
    String modules = "bedtools/2.27 python/3.7"
  }

  command <<<
  set -euo pipefail

  python3 <<CODE
  import subprocess
  import sys

  normal_min_cov = ~{normalMinCoverage}
  tumor_min_cov = ~{tumorMinCoverage}

  x = subprocess.Popen(
    "paste <(bedtools genomecov ~{"-i " + intervalFile} -g ~{referenceFile} -ibam ~{normalBam} -d) <(bedtools genomecov ~{"-i " + intervalFile} -g ~{referenceFile} -ibam ~{tumorBam} -d | awk '{print \$NF}')",
    stdout=subprocess.PIPE,
    shell=True,
    executable='/bin/bash',
    encoding='utf-8'
  )

  pass_count=0
  fail_count=0
  for l in x.stdout:
    _, _, normal, tumor = l.strip().split('\t')
    if int(normal) >= normal_min_cov and int(tumor) >= tumor_min_cov:
      pass_count = pass_count + 1
    else:
      fail_count = fail_count + 1

  if pass_count == 0 and fail_count == 0:
    callability = 0
  else:
    callability = pass_count / (pass_count + fail_count)

  with open('~{outputFileName}', 'w') as json_file:
    json_file.write(f"{{\"pass\":{pass_count},\"fail\":{fail_count},\"callability\":{callability:.6f}}}")
  CODE
  >>>

  output {
    File callabilityMetrics = outputFileName
  }

  runtime {
    memory: "~{jobMemory} GB"
    cpu: "~{cores}"
    timeout: "~{timeout}"
    modules: "~{modules}"
  }

  parameter_meta {

  }

  meta {
    output_meta: {

    }
  }
}
