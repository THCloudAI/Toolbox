#!/bin/bash

# กำหนดชื่อไฟล์สำหรับผลลัพธ์
RUNTIME="30"   # ระยะเวลาการรันทดสอบ (วินาที)
TIMESTAMP=$(date +%Y%m%d_%H%M%S) # เพิ่ม timestamp เพื่อเก็บผลลัพธ์ที่ไม่ซ้ำกัน
OUTPUT_DIR=./output
OUTPUT_FILE=${TIMESTAMP}_$(uname -n | sed 's/[^a-zA-Z0-9]/-/g')"_network_test_result.txt"

# กำหนดที่อยู่ IP ของเซิร์ฟเวอร์ iperf3
SERVER_IP="speedtest.hkg12.hk.leaseweb.net"

# ฟังก์ชันในการเริ่มกระบวนการทดสอบ
start_iperf3() {
    # ทดสอบการดาวน์โหลด (ไคลเอนต์ส่งข้อมูลไปยังเซิร์ฟเวอร์)
    #iperf3 --client $SERVER_IP -p 5201-5210 --time $RUNTIME --reverse > $OUTPUT_DIR/download_$OUTPUT_FILE &
    # ทดสอบการอัพโหลด (ไคลเอนต์รับข้อมูลจากเซิร์ฟเวอร์)
    iperf3 --client $SERVER_IP -p 5201-5210 --time $RUNTIME > $OUTPUT_DIR/upload_$OUTPUT_FILE &
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

    echo "Network Test Results:" >> $OUTPUT_DIR/$FINAL_OUTPUT_FILE
    echo "Download Test Results:" >> $OUTPUT_DIR/$FINAL_OUTPUT_FILE
    cat $OUTPUT_DIR/download_$OUTPUT_FILE >> $OUTPUT_DIR/$FINAL_OUTPUT_FILE
    echo "Upload Test Results:" >> $OUTPUT_DIR/$FINAL_OUTPUT_FILE
    cat $OUTPUT_DIR/upload_$OUTPUT_FILE >> $OUTPUT_DIR/$FINAL_OUTPUT_FILE

    echo "Results saved to $OUTPUT_DIR/$FINAL_OUTPUT_FILE"
}

# เริ่มกระบวนการทดสอบ
create_output_dir
start_iperf3

# แปลงค่า RUNTIME เป็นวินาที
RUNTIME_SECONDS=$(echo $RUNTIME | sed 's/s$//')

# เวลาเริ่มต้น
START_TIME=$(date +%s)

# วนรอเพื่อดูว่ากระบวนการ `iperf3` ถูก kill หรือไม่ และเริ่มใหม่ถ้าจำเป็น
while true; do
    # เช็คว่ามีการทำงานของ `iperf3` หรือไม่
    if ! pgrep -x "iperf3" > /dev/null; then
        echo "iperf3 process stopped. Restarting..."
        collect_results
        start_iperf3
    fi

    # ตรวจสอบเวลาปัจจุบัน
    CURRENT_TIME=$(date +%s)
    ELAPSED_TIME=$((CURRENT_TIME - START_TIME))

    # ถ้าผ่านไปเท่ากับหรือเกินกว่า RUNTIME ให้หยุดการทำงานของ loop
    if [ $ELAPSED_TIME -ge $RUNTIME_SECONDS ]; then
        echo "Test completed after $RUNTIME seconds."
        sleep 5
        collect_results
        break
    fi

    sleep 5  # ตรวจสอบทุกๆ 5 วินาที
done
