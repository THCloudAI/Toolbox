#!/bin/bash

# Set the filename for the results
RUNTIME=${1:-3600}   # Duration of the test run in seconds
TIMESTAMP=$(date +%Y%m%d_%H%M%S) # Add timestamp to ensure unique results
OUTPUT_DIR=./output
OUTPUT_FILE=${TIMESTAMP}_$(uname -n | sed 's/[^a-zA-Z0-9]/-/g')"_memory_test_result.txt"

# Calculate the total memory (in KB)
TOTAL_MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
# Calculate the available memory (in KB)
AVAILABLE_MEM=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
# Calculate 90% of the total memory (in KB)
MEMORY_TO_USE=$(echo "$TOTAL_MEM * 0.9" | bc | awk '{printf "%.0f", $0}')
# Calculate the memory to be stressed (in KB) by subtracting the available memory from MEMORY_TO_USE
MEMORY_TO_STRESS=$(($MEMORY_TO_USE - ($TOTAL_MEM - $AVAILABLE_MEM)))

# Ensure MEMORY_TO_STRESS is not negative
if [ $MEMORY_TO_STRESS -le 0 ]; then
    MEMORY_TO_STRESS=0
fi

echo "Total memory (KB): $TOTAL_MEM"
echo "Available memory (KB): $AVAILABLE_MEM"
echo "Memory to use (90% of total, KB): $MEMORY_TO_USE"
echo "Memory to stress (KB): $MEMORY_TO_STRESS"

# Function to start the testing process
start_stress() {
    # Memory stress test
    stress-ng --vm 1 --vm-bytes ${MEMORY_TO_STRESS}K --timeout 60 --metrics-brief > $OUTPUT_DIR/memory_$OUTPUT_FILE &
    echo $! # Return the process ID of the stress-ng command
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

    echo "Memory Test Results:" >> $OUTPUT_DIR/$FINAL_OUTPUT_FILE
    cat $OUTPUT_DIR/memory_$OUTPUT_FILE >> $OUTPUT_DIR/$FINAL_OUTPUT_FILE

    echo "Results saved to $OUTPUT_DIR/$FINAL_OUTPUT_FILE"
}

# Start the testing process
create_output_dir
STRESS_PID=$(start_stress)

# Start time
START_TIME=$(date +%s)

# Loop to check if the `stress` process is killed and restart if necessary
while true; do
    # Check if the `stress` process is running
    if ! kill -0 $STRESS_PID 2>/dev/null; then
        echo "stress process stopped. Restarting..."
        collect_results
        STRESS_PID=$(start_stress)
    fi

    # Check the current time
    CURRENT_TIME=$(date +%s)
    ELAPSED_TIME=$((CURRENT_TIME - START_TIME))

    # If the elapsed time is equal to or greater than RUNTIME, stop the loop
    if [ $ELAPSED_TIME -ge $RUNTIME ]; then
        echo "Test completed after $RUNTIME seconds."
        sleep 5
        collect_results
        break
    fi

    sleep 5  # Check every 5 seconds
done 