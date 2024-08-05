#!/bin/bash

# Set the filename for the results
RUNTIME="3600"   # Duration of the test run (seconds)
TIMESTAMP=$(date +%Y%m%d_%H%M%S) # Add timestamp to ensure unique results
OUTPUT_DIR=./output
OUTPUT_FILE=${TIMESTAMP}_$(uname -n | sed 's/[^a-zA-Z0-9]/-/g')"_network_test_result.txt"

# Set the IP address of the iperf3 server
SERVER_IP="speedtest.hkg12.hk.leaseweb.net"

# Function to start the testing process
start_iperf3() {
    # Test download (client sends data to the server)
    iperf3 --client $SERVER_IP -p 5201-5210 --time 60 --reverse > $OUTPUT_DIR/download_$OUTPUT_FILE &
    local download_pid=$!
    
    # Wait for download to finish
    wait $download_pid
    
    # Test upload (client receives data from the server)
    iperf3 --client $SERVER_IP -p 5201-5210 --time 60 > $OUTPUT_DIR/upload_$OUTPUT_FILE &
    local upload_pid=$!
    
    # Wait for upload to finish
    wait $upload_pid
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

    echo "Network Test Results:" >> $OUTPUT_DIR/$FINAL_OUTPUT_FILE
    echo "Download Test Results:" >> $OUTPUT_DIR/$FINAL_OUTPUT_FILE
    cat $OUTPUT_DIR/download_$OUTPUT_FILE >> $OUTPUT_DIR/$FINAL_OUTPUT_FILE
    echo "Upload Test Results:" >> $OUTPUT_DIR/$FINAL_OUTPUT_FILE
    cat $OUTPUT_DIR/upload_$OUTPUT_FILE >> $OUTPUT_DIR/$FINAL_OUTPUT_FILE

    echo "Results saved to $OUTPUT_DIR/$FINAL_OUTPUT_FILE"
}

# Start the testing process
create_output_dir

# Convert RUNTIME to seconds
RUNTIME_SECONDS=$(echo $RUNTIME | sed 's/s$//')

# Start time
START_TIME=$(date +%s)

# Loop to check if the `iperf3` process is killed and restart if necessary
while true; do
    # Start the iperf3 test
    start_iperf3

    # Check the current time
    CURRENT_TIME=$(date +%s)
    ELAPSED_TIME=$((CURRENT_TIME - START_TIME))

    # If the elapsed time is equal to or greater than RUNTIME, stop the loop
    if [ $ELAPSED_TIME -ge $RUNTIME_SECONDS ]; then
        echo "Test completed after $RUNTIME seconds."
        sleep 5
        collect_results
        break
    fi

    sleep 5  # Check every 5 seconds
done
