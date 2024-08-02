#!/bin/bash

# กำหนดชื่อไฟล์สำหรับผลลัพธ์
RUNTIME="30s"   # ระยะเวลาการรันทดสอบ
SIZE="1G"       # ขนาดไฟล์ที่ใช้ในการทดสอบ
TEST_FILE="./testfile"
TIMESTAMP=$(date +%Y%m%d_%H%M%S) # เพิ่ม timestamp เพื่อเก็บผลลัพธ์ที่ไม่ซ้ำกัน
OUTPUT_DIR=./output
OUTPUT_FILE=${TIMESTAMP}_$(uname -n |sed 's/[^a-zA-Z0-9]/-/g')"_$(echo $TEST_FILE| sed 's/[(\/\.)\/\.]//g')_hdd_test_result.txt"

# ฟังก์ชันในการเริ่มกระบวนการทดสอบ
start_fio() {
    # ทดสอบการเขียน
    fio --name=write_test --filename=$TEST_FILE --size=$SIZE --time_based --runtime=$RUNTIME --ioengine=libaio --direct=1 --bs=4k --rw=write --output=$OUTPUT_DIR/write_$OUTPUT_FILE &
    # FIO_WRITE_PID=$!  # เก็บ PID ของกระบวนการ `fio`
    # ทดสอบการอ่าน
    fio --name=read_test --filename=$TEST_FILE --size=$SIZE --time_based --runtime=$RUNTIME --ioengine=libaio --direct=1 --bs=4k --rw=read --output=$OUTPUT_DIR/read_$OUTPUT_FILE &
    # FIO_READ_PID=$!  # เก็บ PID ของกระบวนการ `fio`
}

create_output_dir() {
    if [[ ! -d $output ]]; then
        mkdir -p ./output
    fi
}

# ฟังก์ชันในการรวมผลลัพธ์
collect_results() {
    # สร้างชื่อไฟล์สำหรับผลลัพธ์ด้วย timestamp
    FINAL_OUTPUT_FILE="${OUTPUT_FILE%.*}.txt"
    
    sudo df -h > $OUTPUT_DIR/$FINAL_OUTPUT_FILE
    sudo lsblk >> $OUTPUT_DIR/$FINAL_OUTPUT_FILE
    echo "Write Test Results:" >> $OUTPUT_DIR/$FINAL_OUTPUT_FILE
    cat $OUTPUT_DIR/write_$OUTPUT_FILE >> $OUTPUT_DIR/$FINAL_OUTPUT_FILE
    echo "Read Test Results:" >> $OUTPUT_DIR/$FINAL_OUTPUT_FILE
    cat $OUTPUT_DIR/read_$OUTPUT_FILE >> $OUTPUT_DIR/$FINAL_OUTPUT_FILE

    echo "Results saved to $OUTPUT_DIR/$FINAL_OUTPUT_FILE"
}

# เริ่มกระบวนการทดสอบ
create_output_dir
start_fio

# แปลงค่า RUNTIME เป็นวินาที
RUNTIME_SECONDS=$(echo $RUNTIME | sed 's/s$//')

# เวลาเริ่มต้น
START_TIME=$(date +%s)

# วนรอเพื่อดูว่ากระบวนการ `fio` ถูก kill หรือไม่ และเริ่มใหม่ถ้าจำเป็น
while true; do
    # เช็คว่ามีการทำงานของ `fio` หรือไม่
    if ! pgrep -x "fio" > /dev/null; then
        echo "fio process stopped. Restarting..."
        collect_results
        start_fio
    fi

    # ตรวจสอบเวลาปัจจุบัน
    CURRENT_TIME=$(date +%s)
    ELAPSED_TIME=$((CURRENT_TIME - START_TIME))

    # ถ้าผ่านไปเท่ากับหรือเกินกว่า RUNTIME ให้หยุดการทำงานของ loop
    if [ $ELAPSED_TIME -ge $RUNTIME_SECONDS ]; then
        echo "Test completed after $RUNTIME."
        sleep 5
        # (sleep $RUNTIME_SECONDS && kill -INT $FIO_WRITE_PID)
        # (sleep $RUNTIME_SECONDS && kill -INT $FIO_READ_PID)
        collect_results
        rm -f $TEST_FILE
        break
    fi

    sleep 5  # ตรวจสอบทุกๆ 10 วินาที
done