#!/bin/bash
cd $1

ls -1

module load jq
jq -c . *callability_metrics.json
