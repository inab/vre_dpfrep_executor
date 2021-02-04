#!/bin/bash

###
### Testing in a local installation
### the VRE server CMD
###
### * Automatically created by VRE *
###


# Local installation - EDIT IF REQUIRED

WORKING_DIR=/test/execution/directory
TOOL_EXECUTABLE=/main/mg-tool/executable.py

# Test input files

CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TEST_DATA_DIR=$CWD/json/0_RunDpFrEPpipeline


# Running DpFrEP tool ...

if [ -d  $WORKING_DIR ]; then rm -r $WORKING_DIR/; mkdir -p $WORKING_DIR; else mkdir -p $WORKING_DIR; fi
cd $WORKING_DIR

echo "--- Test execution: $WORKING_DIR"
echo "--- Start time: `date`"

time $TOOL_EXECUTABLE --config $TEST_DATA_DIR/config.json --in_metadata $TEST_DATA_DIR/in_metadata.json --out_metadata $WORKING_DIR/out_metadata.json > $WORKING_DIR/tool.log
