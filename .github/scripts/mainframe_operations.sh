#!/bin/bash
# mainframe_operations.sh

# Set up environment
export PATH=$PATH:/usr/lpp/java/J8.0_64/bin
export JAVA_HOME=/usr/lpp/java/J8.0_64
export PATH=$PATH:/usr/lpp/zowe/cli/node/bin

# Check Java availability
java -version

# Change to the cobolcheck directory
if [ -d "cobolcheck" ]; then
  cd cobolcheck
  echo "Changed to $(pwd)"
  ls -al
else
  echo "Current directory: $(pwd)"
  ls -al
fi

# Function to run cobolcheck and copy files
run_cobolcheck() {
  local program=$1
  echo "Running cobolcheck for $program"
  
  # Run cobolcheck
  java -jar cobol-check-0.2.9.jar -p $program
  
  # Check if CC##99.CBL was created
  if [ -f "CC##99.CBL" ]; then
    cp CC##99.CBL "//'${ZOWE_USERNAME}.CBL($program)'"
    echo "Copied CC##99.CBL to ${ZOWE_USERNAME}.CBL($program)"
  else
    echo "CC##99.CBL not found for $program"
  fi
  
  # Check if JCL file exists and copy it
  if [ -f "${program}.JCL" ]; then
    cp ${program}.JCL "//'${ZOWE_USERNAME}.JCL($program)'"
    echo "Copied ${program}.JCL to ${ZOWE_USERNAME}.JCL($program)"
  else
    echo "${program}.JCL not found"
  fi
}

# Run for each program
for program in NUMBERS EMPPAY DEPTPAY; do
  run_cobolcheck $program
done

echo "Mainframe operations completed"
