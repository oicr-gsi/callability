version 1.0

workflow callability {

  input {
    File normalBam
    File normalBamIndex
    File tumorBam
    File tumorBamIndex
    Int normalMinCoverage
    Int tumorMinCoverage
    String intervalFile
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
}

task calculateCallability {
  input {
    File normalBam
    File normalBamIndex
    File tumorBam
    File tumorBamIndex
    Int normalMinCoverage
    Int tumorMinCoverage
    String intervalFile
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
  mosdepth -t 4 -n --quantize 0:~{normalMinCoverage - 1}: normal ~{normalBam}
  mosdepth -t 4 -n --quantize 0:~{tumorMinCoverage - 1}: tumor ~{tumorBam}
  zcat normal.quantized.bed.gz | awk '$4 == "CALLABLE"' | bedtools intersect -a stdin -b ~{intervalFile} > normal.callable
  zcat tumor.quantized.bed.gz | awk '$4 == "CALLABLE"' | bedtools intersect -a stdin -b ~{intervalFile} > tumor.callable

  PASS="$(bedtools intersect -a normal.callable -b tumor.callable -wao | awk '{sum+=$9} END{print sum}')"
  TOTAL="$(zcat -f ~{intervalFile} | awk -F'\t' 'BEGIN{SUM=0}{SUM+=$3-$2} END{print SUM}')"

  python3 <<CODE
  total_count = int("${TOTAL}")
  pass_count = int("${PASS}")
  fail_count = total_count - pass_count
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
