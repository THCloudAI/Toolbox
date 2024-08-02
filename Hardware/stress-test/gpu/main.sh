#!/bin/bash

# ฟังก์ชันในการรันการทดสอบ GPU
start_gpu_test() {
    python3 stress.py
}

# สร้างไดเรกทอรีผลลัพธ์
OUTPUT_DIR=./output
if [[ ! -d $OUTPUT_DIR ]]; then
    mkdir -p $OUTPUT_DIR
fi

# ระยะเวลาทั้งหมดที่ต้องการรันการทดสอบ (วินาที)
TOTAL_TESTING_DURATION_TIME_IN_MINUTE=20
TOTAL_DURATION=$((${TOTAL_TESTING_DURATION_TIME_IN_MINUTE} * 60))  # 15 นาที = 900 วินาที
# ระยะเวลาการทดสอบในแต่ละรอบ (วินาที)
TEST_DURATION=300  # 5 นาที = 300 วินาที
# ระยะเวลาพักในแต่ละรอบ (วินาที)
PAUSE_DURATION=60  # 1 นาที = 60 วินาที

# เวลาเริ่มต้น
START_TIME=$(date +%s)

# วนลูปการทดสอบและพักตามเวลาที่กำหนดจนครบ 15 นาที
while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED_TIME=$((CURRENT_TIME - START_TIME))

    if [ $ELAPSED_TIME -ge $TOTAL_DURATION ]; then
        echo "Completed the total duration of 15 minutes. Exiting..."
        break
    fi

    echo "Starting GPU stress test..."
    start_gpu_test

    echo "Pausing for 1 minute before the next test..."
    sleep $PAUSE_DURATION  # พัก 1 นาที
done