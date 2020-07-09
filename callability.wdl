version 1.0

workflow callability {

  input {
    File normalBam
    File normalBamIndex
    File tumorBam
    File tumorBamIndex
    Int normalMinCoverage
    Int tumorMinCoverage
    File intervalFile
  }

  call calculateCallability {
    input:
      normalBam=normalBam,
      normalBamIndex=normalBamIndex,
      tumorBam=tumorBam,
      tumorBamIndex=tumorBamIndex,
      normalMinCoverage=normalMinCoverage,
      tumorMinCoverage=tumorMinCoverage,
      intervalFile=intervalFile
  }

  output {
    File callabilityMetrics = calculateCallability.callabilityMetrics
  }

  parameter_meta {
    normalBam: "Normal bam input file."
    normalBamIndex: "Normal bam index input file."
    tumorBam: "Tumor bam input file."
    tumorBamIndex: "Tumor bam index input file."
    normalMinCoverage: "Normal must have at least this coverage to be considered callable."
    tumorMinCoverage: "Tumor must have at least this coverage to be considered callable."
    intervalFile: "The interval file of regions to calculate callability on."
  }

  meta {
    author: "Alexander Fortuna, Michael Laszloffy"
    email: "alexander.fortuna@oicr.on.ca, michael.laszloffy@oicr.on.ca"
    description: "Workflow to calculate the callability of a matched tumour sample, where callability is defined as the percentage of genomic regions where a normal and a tumor bam coverage is greater than a threshold(s)."
    dependencies: [
      {
        name: "mosdepth/0.2.9",
        url: "https://github.com/brentp/mosdepth"
      },
      {
        name: "bedtools/2.27",
        url: "https://bedtools.readthedocs.io/en/latest/"
      },
      {
        name: "python/3.7",
        url: "https://www.python.org"
      }
    ]
    output_meta: {
      callabilityMetrics: "Json file with pass, fail and callability percent (# of pass bases / # total bases)"
    }
  }

}

task calculateCallability {
  input {
    File normalBam
    File normalBamIndex
    File tumorBam
    File tumorBamIndex
    Int normalMinCoverage
    Int tumorMinCoverage
    File intervalFile
    Int threads = 4
    String? outputFileNamePrefix
    String outputFileName = "callability_metrics.json"
    Int jobMemory = 8
    Int cores = 1
    Int timeout = 12
    String modules = "mosdepth/0.2.9 bedtools/2.27 python/3.7"
  }

  command <<<
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
    normalBam: "Normal bam input file."
    normalBamIndex: "Normal bam index input file."
    tumorBam: "Tumor bam input file."
    tumorBamIndex: "Tumor bam index input file."
    normalMinCoverage: "Normal must have at least this coverage to be considered callable."
    tumorMinCoverage: "Tumor must have at least this coverage to be considered callable."
    intervalFile: "The interval file of regions to calculate callability on."
    threads: "The number of threads to run mosdepth with."
    outputFileNamePrefix: "Output files will be prefixed with this."
    outputFileName: "Output callability metrics file name."
    jobMemory: "Memory allocated to job (in GB)."
    cores: "The number of cores to allocate to the job."
    timeout: "Maximum amount of time (in hours) the task can run for."
    modules: "Environment module name and version to load (space separated) before command execution."
  }
}
