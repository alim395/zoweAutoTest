#!/bin/bash
# mainframe_operations.sh

# Set up environment
export PATH=$PATH:/usr/lpp/java/J8.0_64/bin
export JAVA_HOME=/usr/lpp/java/J8.0_64
export PATH=$PATH:/usr/lpp/zowe/cli/node/bin

# Check Java availability
java -version

# Change to the appropriate directory
cd /z/$ZOWE_USERNAME/cobolcheck
ls -al
chmod +x cobolcheck
ls -al
cd scripts
ls -al
chmod +x linux_gnucobol_run_tests
cd ..
pwd

# Run COBOL check on NUMBERS
./cobolcheck -p NUMBERS

# Copy NUMBERS files to datasets
cp CC##99.CBL "//'${ZOWE_USERNAME}.CBL(NUMBERS)'"
cp NUMBERS.JCL "//'${ZOWE_USERNAME}.JCL(NUMBERS)'"

# Run COBOL check on EMPPAY
./cobolcheck -p EMPPAY

# Copy EMPPAY files to datasets
cp CC##99.CBL "//'${ZOWE_USERNAME}.CBL(EMPPAY)'"
cp EMPPAY.JCL "//'${ZOWE_USERNAME}.JCL(EMPPAY)'"

# Run COBOL check on DEPTPAY
./cobolcheck -p DEPTPAY

# Copy DEPTPAY files to datasets
cp CC##99.CBL "//'${ZOWE_USERNAME}.CBL(DEPTPAY)'"
cp DEPTPAY.JCL "//'${ZOWE_USERNAME}.JCL(DEPTPAY)'"


echo "Mainframe operations completed"
