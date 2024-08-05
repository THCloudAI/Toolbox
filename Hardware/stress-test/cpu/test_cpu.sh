#!/bin/bash

# Set the filename for the results
RUNTIME="30"   # Duration of the test run
TIMESTAMP=$(date +%Y%m%d_%H%M%S) # Add timestamp to ensure unique results
OUTPUT_DIR=./output
OUTPUT_FILE=${TIMESTAMP}_$(uname -n | sed 's/[^a-zA-Z0-9]/-/g')"_cpu_test_result.txt"

# Calculate the total number of cores
TOTAL_CORES=$(nproc)
# Calculate 80% of the total number of cores
THREADS=$(echo "($TOTAL_CORES * 0.8)/1" | bc)

# Function to start the testing process
start_sysbench() {
    # Test CPU
    sysbench cpu --cpu-max-prime=20000 --time=$RUNTIME --threads=$THREADS run > $OUTPUT_DIR/cpu_$OUTPUT_FILE &
}

create_output_dir() {
    if [[ ! -d $OUTPUT_DIR ]]; then
        mkdir -p $OUTPUT_DIR
    fi
}

# Function to collect the results
collect_results() {
    # Create a filename for the final results with timestamp
    FINAL_OUTPUT_FILE="${OUTPUT_FILE%.*}.txt"

    echo "CPU Test Results:" >> $OUTPUT_DIR/$FINAL_OUTPUT_FILE
    cat $OUTPUT_DIR/cpu_$OUTPUT_FILE >> $OUTPUT_DIR/$FINAL_OUTPUT_FILE

    echo "Results saved to $OUTPUT_DIR/$FINAL_OUTPUT_FILE"
}

# Start the testing process
create_output_dir
start_sysbench

# Convert RUNTIME to seconds
RUNTIME_SECONDS=$(echo $RUNTIME | sed 's/s$//')

# Start time
START_TIME=$(date +%s)

# Loop to check if the `sysbench` process is killed and restart if necessary
while true; do
    # Check if the `sysbench` process is running
    if ! pgrep -x "sysbench" > /dev/null; then
        echo "sysbench process stopped. Restarting..."
        collect_results
        start_sysbench
    fi

    # Check the current time
    CURRENT_TIME=$(date +%s)
    ELAPSED_TIME=$((CURRENT_TIME - START_TIME))

    # If the elapsed time is equal to or greater than RUNTIME, stop the loop
    if [ $ELAPSED_TIME -ge $RUNTIME_SECONDS ]; then
        echo "Test completed after $RUNTIME."
        sleep 5
        collect_results
        break
    fi

    sleep 5  # Check every 5 seconds
done