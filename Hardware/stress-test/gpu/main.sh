#!/bin/bash

# function for testing GPU
start_gpu_test() {
    python3 stress.py $TOTAL_DURATION &
    echo $!
}

# Create dir
OUTPUT_DIR=./output
if [[ ! -d $OUTPUT_DIR ]]; then
    mkdir -p $OUTPUT_DIR
fi

# in second
TOTAL_DURATION=${1:-3600}

# starting time
START_TIME=$(date +%s)

# begin testing GPU
echo "Starting GPU stress test for a total duration of ${TOTAL_DURATION} seconds..."
TEST_PID=$(start_gpu_test $TOTAL_DURATION)

# Loop until the specified time is reached
while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED_TIME=$((CURRENT_TIME - START_TIME))

    if [ $ELAPSED_TIME -ge $TOTAL_DURATION ]; then
        echo "Completed the total duration of ${TOTAL_DURATION} seconds. Exiting..."
        break
    fi

    if ! ps -p $TEST_PID > /dev/null; then
        echo "Process $TEST_PID has stopped. Restarting the test..."
        TEST_PID=$(start_gpu_test $TOTAL_DURATION)
    fi

    sleep 5
done