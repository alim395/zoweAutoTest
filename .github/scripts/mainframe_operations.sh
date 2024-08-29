#!/bin/bash
# mainframe_operations.sh

# Set up environment
export PATH=$PATH:/usr/lpp/java/J8.0_64/bin
export JAVA_HOME=/usr/lpp/java/J8.0_64
export PATH=$PATH:/usr/lpp/zowe/cli/node/bin

# Check Java availability
java -version

# Set ZOWE_USERNAME
ZOWE_USERNAME="Z36963"  # Replace with the actual username or dataset prefix

# Change to the cobolcheck directory
cd cobolcheck
echo "Changed to $(pwd)"
ls -al

# Make cobolcheck executable
chmod +x cobolcheck
echo "Made cobolcheck executable"

# Make script in scripts directory executable
cd scripts
chmod +x linux_gnucobol_run_tests
echo "Made linux_gnucobol_run_tests executable"
cd ..

# Function to run cobolcheck and copy files
run_cobolcheck() {
  program=$1
  echo "Running cobolcheck for $program"
  
  # Run cobolcheck, but don't exit if it fails
  ./cobolcheck -p $program
  echo "Cobolcheck execution completed for $program (exceptions may have occurred)"
  
  # Check if CC##99.CBL was created, regardless of cobolcheck exit status
  if [ -f "CC##99.CBL" ]; then
    # Copy to the MVS dataset
    if cp CC##99.CBL "//'${ZOWE_USERNAME}.CBL($program)'"; then
      echo "Copied CC##99.CBL to ${ZOWE_USERNAME}.CBL($program)"
    else
      echo "Failed to copy CC##99.CBL to ${ZOWE_USERNAME}.CBL($program)"
    fi
  else
    echo "CC##99.CBL not found for $program"
  fi
  
  # Copy the JCL file if it exists
  if [ -f "${program}.JCL" ]; then
    if cp ${program}.JCL "//'${ZOWE_USERNAME}.JCL($program)'"; then
      echo "Copied ${program}.JCL to ${ZOWE_USERNAME}.JCL($program)"
    else
      echo "Failed to copy ${program}.JCL to ${ZOWE_USERNAME}.JCL($program)"
    fi
  else
    echo "${program}.JCL not found"
  fi
   # Submit job
    if [ -f "${program}.JCL" ]; then
      echo "Submitting job for $program"
      job_id=$(zowe jobs submit data-set "${ZOWE_USERNAME}.JCL($program)" --rff jobid --rft string)
      if [ $? -eq 0 ]; then
        echo "Job submitted successfully. Job ID: $job_id"
        
        # Check job status
        echo "Checking job status..."
        for i in {1..10}; do  # Try 10 times, waiting 5 seconds between each attempt
          status=$(zowe jobs view job-status-by-jobid "$job_id" --rff status --rft string)
          echo "Current status: $status"
          if [[ "$status" == "OUTPUT" ]]; then
            echo "Job completed. Fetching output..."
            zowe jobs view sfbi "$job_id" 2
            break
          elif [[ "$status" == "ABEND" || "$status" == "CANCELED" ]]; then
            echo "Job failed with status: $status"
            break
          fi
          sleep 5
        done
        
        if [[ "$status" != "OUTPUT" && "$status" != "ABEND" && "$status" != "CANCELED" ]]; then
          echo "Job did not complete within the expected time. Last known status: $status"
        fi
      else
        echo "Failed to submit job for $program"
      fi
    else
      echo "JCL file for $program not found. Job not submitted."
    fi
}

# Run for each program
for program in NUMBERS EMPPAY DEPTPAY; do
  run_cobolcheck $program
done

echo "Mainframe operations completed"
