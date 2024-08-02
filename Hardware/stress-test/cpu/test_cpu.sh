#!/bin/bash

# กำหนดชื่อไฟล์สำหรับผลลัพธ์
RUNTIME="30"   # ระยะเวลาการรันทดสอบ
TIMESTAMP=$(date +%Y%m%d_%H%M%S) # เพิ่ม timestamp เพื่อเก็บผลลัพธ์ที่ไม่ซ้ำกัน
OUTPUT_DIR=./output
OUTPUT_FILE=${TIMESTAMP}_$(uname -n |sed 's/[^a-zA-Z0-9]/-/g')"_cpu_test_result.txt"

# คำนวณจำนวนคอร์ทั้งหมด
TOTAL_CORES=$(nproc)
# คำนวณ 80% ของจำนวนคอร์ทั้งหมด
THREADS=$(echo "($TOTAL_CORES * 0.8)/1" | bc)


# ฟังก์ชันในการเริ่มกระบวนการทดสอบ
start_sysbench() {
    # ทดสอบ CPU
    sysbench cpu --cpu-max-prime=20000 --time=$RUNTIME --threads=$THREADS run > $OUTPUT_DIR/cpu_$OUTPUT_FILE &
}

create_output_dir() {
    if [[ ! -d $OUTPUT_DIR ]]; then
        mkdir -p $OUTPUT_DIR
    fi
}

# ฟังก์ชันในการรวมผลลัพธ์
collect_results() {
    # สร้างชื่อไฟล์สำหรับผลลัพธ์ด้วย timestamp
    FINAL_OUTPUT_FILE="${OUTPUT_FILE%.*}.txt"

    echo "CPU Test Results:" >> $OUTPUT_DIR/$FINAL_OUTPUT_FILE
    cat $OUTPUT_DIR/cpu_$OUTPUT_FILE >> $OUTPUT_DIR/$FINAL_OUTPUT_FILE

    echo "Results saved to $OUTPUT_DIR/$FINAL_OUTPUT_FILE"
}

# เริ่มกระบวนการทดสอบ
create_output_dir
start_sysbench

# แปลงค่า RUNTIME เป็นวินาที
RUNTIME_SECONDS=$(echo $RUNTIME | sed 's/s$//')

# เวลาเริ่มต้น
START_TIME=$(date +%s)

# วนรอเพื่อดูว่ากระบวนการ `sysbench` ถูก kill หรือไม่ และเริ่มใหม่ถ้าจำเป็น
while true; do
    # เช็คว่ามีการทำงานของ `sysbench` หรือไม่
    if ! pgrep -x "sysbench" > /dev/null; then
        echo "sysbench process stopped. Restarting..."
        collect_results
        start_sysbench
    fi

    # ตรวจสอบเวลาปัจจุบัน
    CURRENT_TIME=$(date +%s)
    ELAPSED_TIME=$((CURRENT_TIME - START_TIME))

    # ถ้าผ่านไปเท่ากับหรือเกินกว่า RUNTIME ให้หยุดการทำงานของ loop
    if [ $ELAPSED_TIME -ge $RUNTIME_SECONDS ]; then
        echo "Test completed after $RUNTIME."
        sleep 5
        collect_results
        break
    fi

    sleep 5  # ตรวจสอบทุกๆ 5 วินาที
done