#!/bin/bash

devbox=$1
s=$2
e=$3
cycle=$4

for i in $(seq $s $e); do
  batch_code=$(printf "%02d" $i)
  name="batch${devbox}${batch_code}"
  command="srun -J \"$name\" -p gpu -w \"$devbox\" --gres=gpu:1 -t 15-0 /home/livinit/localcolabfold/colabfold-conda/bin/colabfold_batch msa_batch00_2000/batch00_r02_msa_filenames_batch${batch_code}_dir preds_batch00_2000/batch00_r02_preds_filenames_batch${batch_code}_dir --stop-at-score 85 --num-models 1 > preds_batch00_2000/log_batch${batch_code}"

  # Check if the number of running jobs with names starting with "batch" is at the limit
  while [ "$(squeue -h -o "%j" | grep -c "^batch${devbox}")" -ge "$cycle" ]; do
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Waiting for running jobs with names starting with 'batch' to drop below $cycle..."
    sleep 600  # Wait for 10 seconds before checking again
  done

  # Echo the command being run
  echo "Running: $command"

  # Execute the command in the background
  eval $command &
done

# Wait for all background jobs to complete
wait
