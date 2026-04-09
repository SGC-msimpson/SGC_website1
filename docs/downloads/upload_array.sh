#!/bin/bash -l
#SBATCH -p cpu
#SBATCH --job-name=gwas_upload
#SBATCH --output=logs/upload_%A_%a.out  # Separate log for every file
#SBATCH --time=00:15:00                # Short timeout per file
#SBATCH --mem=512M
#SBATCH --ntasks=1
#SBATCH --array=1-115%10               # Adjust 115 to your file count. 
                                       # %10 limits to 10 simultaneous uploads.

# 1. Get the specific filename for this array index
LIST_FILE=${1:-upload_list.txt} # Defaults to upload_list.txt if no arg provided
FILE_PATH=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $LIST_FILE)


# 2. Skip if the line is empty (end of file)
if [ -z "$FILE_PATH" ]; then exit 0; fi

echo "Processing task ${SLURM_ARRAY_TASK_ID}: $FILE_PATH"

# 3. Run with a internal timeout (e.g., 14 mins) 
# This is slightly SHORTER than your #SBATCH --time
# Replace "GEL_batch" with a descriptor for your data
# Here, I've named my metadata JSONs the same as my GWAS files, adding ".json" to the end
timeout 14m python upload_gwas_presigned_prod.py --dataset GEL_batch --metadata "${FILE_PATH}.json" "$FILE_PATH"

# 4. Capture the exit code
EXIT_STATUS=$?

if [ $EXIT_STATUS -eq 0 ]; then
    echo "$FILE_PATH" >> upload_success.log
elif [ $EXIT_STATUS -eq 124 ]; then
    echo "$FILE_PATH - TIMED OUT" >> upload_failed.log
else
    echo "$FILE_PATH - CRASHED (Exit $EXIT_STATUS)" >> upload_failed.log
fi

