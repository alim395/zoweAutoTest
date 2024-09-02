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

# Function to run cobolcheck and submit job
run_cobolcheck() {
  program=$1
  echo "Running cobolcheck for $program"
  
  # Run cobolcheck
  ./cobolcheck -p $program
  echo "Cobolcheck execution completed for $program (exceptions may have occurred)"
  
  # Copy files
  if [ -f "CC##99.CBL" ]; then
    cp CC##99.CBL "//'${ZOWE_USERNAME}.CBL($program)'"
    echo "Copied CC##99.CBL to ${ZOWE_USERNAME}.CBL($program)"
  else
    echo "CC##99.CBL not found for $program"
  fi
  
  if [ -f "${program}.JCL" ]; then
    cp ${program}.JCL "//'${ZOWE_USERNAME}.JCL($program)'"
    echo "Copied ${program}.JCL to ${ZOWE_USERNAME}.JCL($program)"
  else
    echo "${program}.JCL not found"
  fi

  # Submit job
  if [ -f "${program}.JCL" ]; then
    echo "Submitting job for $program"
    job_output=$(submit "${program}.JCL" 2>&1)
    echo "Job submission output: $job_output"
    
    # Extract job ID
    job_id=$(echo "$job_output" | awk '{print $2}')
    
    if [ -n "$job_id" ]; then
      echo "Job submitted successfully. Job ID: $job_id"
      
      # Check job status using operator display command
      echo "Checking job status..."
      for i in $(seq 1 12); do  # Try for 1 minute (5 seconds * 12)
        status_output=$(tso -t "d j,${job_id}" 2>&1)
        echo "Job status: $status_output"
        
        if echo "$status_output" | grep -q "NOT FOUND"; then
          echo "Job not found. It may have completed quickly."
          break
        elif echo "$status_output" | grep -q "ON OUTPUT QUEUE"; then
          echo "Job completed. Attempting to fetch output..."
          break
        elif echo "$status_output" | grep -q "EXECUTING"; then
          echo "Job is still running."
        else
          echo "Unexpected job status. Please check manually."
          break
        fi
        
        sleep 5
      done
      
      # Try to fetch output
      if tso -t "RECEIVE USERID() INDSN('${ZOWE_USERNAME}.${job_id}.JESMSGLG')" > "${program}_output.txt" 2>/dev/null; then
        echo "Job output retrieved and saved to ${program}_output.txt"
        cat "${program}_output.txt"
      else
        echo "Unable to fetch job output. The job may have failed or output may not be available."
      fi
      
      if [ $i -eq 12 ]; then
        echo "Job status check timed out. Last known status: $status_output"
      fi
    else
      echo "Failed to extract job ID. Job may not have been submitted successfully."
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
