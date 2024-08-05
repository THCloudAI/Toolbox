#!/bin/bash

# Define an array of required programs
programs=("smartctl" "sysbench" "python3" "fio" "stress-ng" "iperf3")

# Function to check and install a program
check_and_install() {
    local program=$1
    if ! command -v $program >/dev/null 2>&1; then
        echo "$program is not installed. Installing..."
        if [[ $program == "smartctl" ]]; then
            sudo apt-get install -y smartmontools
        else
            sudo apt-get install -y $program
        fi
    else
        echo "$program is already installed."
    fi
}

# Loop through the programs and check/install each one
for program in "${programs[@]}"; do
    check_and_install $program
done