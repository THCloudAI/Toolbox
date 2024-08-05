#!/bin/bash

# Set the filename for the results
RUNTIME="3600s"   # Duration of the test run
TARGET_DIR=${1:-.}  # Directory to run the test in, default is current directory
TEST_FILE="$TARGET_DIR/testfile"
TIMESTAMP=$(date +%Y%m%d_%H%M%S) # Add timestamp to ensure unique results
OUTPUT_DIR="./output"
OUTPUT_FILE="${TIMESTAMP}_$(uname -n | sed 's/[^a-zA-Z0-9]/-/g')_$(basename $TEST_FILE)_hdd_test_result.txt"

# Function to calculate the size of the test file (95% of available space)
calculate_size() {
    AVAILABLE_SPACE=$(df --output=avail "$TARGET_DIR" | tail -n 1)
    SIZE=$(echo "$AVAILABLE_SPACE*0.95/1" | bc)K
}

# Function to start the testing process
start_fio() {
    # Write test
    fio --name=write_test --filename=$TEST_FILE --size=$SIZE --time_based --runtime=$RUNTIME --ioengine=libaio --direct=1 --bs=4k --rw=write --output=$OUTPUT_DIR/write_$OUTPUT_FILE &
    # Read test
    fio --name=read_test --filename=$TEST_FILE --size=$SIZE --time_based --runtime=$RUNTIME --ioengine=libaio --direct=1 --bs=4k --rw=read --output=$OUTPUT_DIR/read_$OUTPUT_FILE &
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

    sudo df -h > $OUTPUT_DIR/$FINAL_OUTPUT_FILE
    sudo lsblk >> $OUTPUT_DIR/$FINAL_OUTPUT_FILE
    echo "Write Test Results:" >> $OUTPUT_DIR/$FINAL_OUTPUT_FILE
    cat $OUTPUT_DIR/write_$OUTPUT_FILE >> $OUTPUT_DIR/$FINAL_OUTPUT_FILE
    echo "Read Test Results:" >> $OUTPUT_DIR/$FINAL_OUTPUT_FILE
    cat $OUTPUT_DIR/read_$OUTPUT_FILE >> $OUTPUT_DIR/$FINAL_OUTPUT_FILE

    echo "Results saved to $OUTPUT_DIR/$FINAL_OUTPUT_FILE"
}

# Start the testing process
create_output_dir
calculate_size
start_fio

# Convert RUNTIME to seconds
RUNTIME_SECONDS=$(echo $RUNTIME | sed 's/s$//')

# Start time
START_TIME=$(date +%s)

# Loop to check if the fio process is killed and restart if necessary
while true; do
    # Check if the fio process is running
    if ! pgrep -x "fio" > /dev/null; then
        echo "fio process stopped. Restarting..."
        collect_results
        start_fio
    fi

    # Check the current time
    CURRENT_TIME=$(date +%s)
    ELAPSED_TIME=$((CURRENT_TIME - START_TIME))

    # If the elapsed time is equal to or greater than RUNTIME, stop the loop
    if [ $ELAPSED_TIME -ge $RUNTIME_SECONDS ]; then
        echo "Test completed after $RUNTIME."
        sleep 5
        collect_results
        rm -f $TEST_FILE
        break
    fi

    sleep 5  # Check every 5 seconds
done