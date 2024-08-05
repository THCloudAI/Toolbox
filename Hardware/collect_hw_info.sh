#!/bin/bash

# Function to get brand and model server
get_brand_model_info() {
    echo "$(sudo dmidecode -t system |grep -iE "product name" |awk -F ':' '{print $2}' |sed 's/ //g')_$(sudo dmidecode -t system |grep -iE "Manufacturer" |awk -F ':' '{print $2}' |sed 's/ //g')"
}

# Function to get brand and model server
get_serial_number() {
    echo "$(sudo dmidecode -t system | grep Serial | awk -F ':' '{print $2}' |sed 's/ //g')"
}

# Function to get CPU information
get_cpu_info() {
    local model=$(lscpu | grep 'Model name:' | awk -F: '{print $2}' | xargs)
    local cores=$(lscpu | grep '^CPU(s):' | awk -F: '{print $2}' | xargs)
    local threads_per_core=$(lscpu | grep 'Thread(s) per core:' | awk -F: '{print $2}' | xargs)
    local cores_per_socket=$(lscpu | grep 'Core(s) per socket:' | awk -F: '{print $2}' | xargs)
    echo "\"$model\",\"$cores\",\"$threads_per_core\",\"$cores_per_socket\""
}

# Function to get motherboard information
get_motherboard_info() {
    local manufacturer=$(cat /sys/class/dmi/id/board_vendor)
    local product=$(cat /sys/class/dmi/id/board_name)
    local version=$(cat /sys/class/dmi/id/board_version)
    echo "\"$manufacturer\",\"$product\",\"$version\""
}

# Function to get memory information
get_memory_info() {
    local total_mem=$(free -m | awk '/Mem:/ {print $2 " MB"}')
    echo "\"$total_mem\""
}


# Function to get disk and SMART information
get_disk_and_smart_info() {
    local disk_info=$(lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep -E 'disk' 2>&1)
    local disk_info_str=""
    local smart_info_str=""
    for disk in $(lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep -E 'disk'|awk '{print "/dev/"$1}'); do
        echo $disk
        echo lsblk -o SIZE /dev/$disk
        smart_info=$(sudo smartctl -A "$disk" |tail +4 2>&1)
        if `echo $smart_info | grep -q "DELL or MegaRaid controller"`; then        
            # Attempt to find the correct device number for MegaRaid
            for i in {0..24}; do
                smart_info=$(sudo smartctl -d megaraid,$i -i $disk 2>&1)
                if ! echo "$smart_info" | grep -q "No such device"; then
                    echo "$smart_info" | grep -E 'Device Model|Serial Number|Firmware Version'
                    sudo smartctl -d megaraid,$i -A /dev/$disk | grep -E '(Power_On_Hours|Reallocated_Sector_Ct|Temperature_Celsius|SMART overall-health self-assessment test result)'
                    break
                fi
            done
        fi
        smart_info_str+="Device: $disk\n"
        smart_info_str+="$smart_info\n"
        smart_info_str+="\n"

    done
    while IFS= read -r line; do
        disk_info_str+=$(echo "$line" | awk '{print $1 " " $2 " " $3 " " $4}')
        disk_info_str+="; "
    done <<< "$disk_info"
    echo "\"$disk_info_str\"|\"$smart_info_str\""
}

get_pcie_info() {
    local pcie_info=$(lspci -nn -v | sort)
    local pcie_info_str=""
    while IFS= read -r line; do
        if [[ "$line" =~ ^[0-9a-fA-F]{2}:[0-9a-fA-F]{2}\.[0-9a-fA-F] ]]; then
            bus_id=$(echo $line | awk '{print $1}')
            device_info=$(lspci -nn -v -s $bus_id)
            device_part_number=$(echo "$device_info" | grep -i "Subsystem:" | sed 's/^[[:space:]]*//')
            device_type=""

            if [[ "$line" == *"VGA"* || "$line" == *"3D controller"* ]]; then
                device_type="Graphics Card (GPU)"
            elif [[ "$line" == *"USB"* ]]; then
                device_type="USB Controller"
            elif [[ "$line" == *"SATA"* || "$line" == *"IDE"* || "$line" == *"RAID"* || "$line" == *"Mass storage"* ]]; then
                device_type="Disk Controller"
            elif [[ "$line" == *"Ethernet controller"* ]]; then
                device_type="Network Controller"
            elif [[ "$line" == *"Non-Volatile memory controller"* ]]; then
                device_type="NVMe Controller"
            else
                device_type="Other Device"
            fi

            pcie_info_str+="$device_type: $line; "
            if [ -n "$device_part_number" ]; then
                pcie_info_str+="$device_part_number; "
            else
                pcie_info_str+="Part Number: Not available; "
            fi
            pcie_info_str+="\n"
        fi
    done <<< "$pcie_info"
    echo -e "$pcie_info_str"
}

# Function to get power supply information
get_power_supply_info() {
    local power_supply_info=$(sudo dmidecode -t 39)
    local power_supply_str=""
    if [ -n "$power_supply_info" ]; then
        while IFS= read -r line; do
            power_supply_str+=$(echo "$line" | awk -F: '{print $1 "," $2}')
            power_supply_str+="; "
        done <<< "$power_supply_info"
    else
        power_supply_str="Not available"
    fi
    echo "\"$power_supply_str\""
}

SERVER_BRAND_MODEL_SERIAL=`echo $(get_brand_model_info)_$(get_serial_number) |sed 's/ //g'`

# Define the output CSV file
OUTPUT_FILE="$(date +%Y-%m-%d-%H%M)_${SERVER_BRAND_MODEL_SERIAL}_hardware_info.csv"

# Write header to the CSV file
echo "servers,serial_numbers,cpu_models,cpu(s),threads_per_core,cores_per_socket,motherboard_manufacturers,motherboard_products,motherboard_versions,total_memorys,disk_informations,pcie_card_informations,power_supply_informations" >> $OUTPUT_FILE

# Collect hardware information and append to the CSV file
server=$(get_brand_model_info)
serial_number=$(get_serial_number)
cpu_info=$(get_cpu_info)
motherboard_info=$(get_motherboard_info)
memory_info=$(get_memory_info)
disk_info=$(get_disk_and_smart_info)
pcie_info=$(get_pcie_info)
power_supply_info=$(get_power_supply_info)

echo "Server : $server"
echo ""

echo "Serial Number : $serial_number"
echo ""

echo "CPU Info:"
echo ${cpu_info} |sed 's/"//g'|awk -F ',' '{print "Model: "$1 " \nTotal of Threads: "$2 " \nthreads per Core: " $3 " \ncores_per_socket: " $4}'
echo ""

echo "Mainboard Info:"
echo ${motherboard_info} |sed 's/"//g'|awk -F ',' '{print "manufacturer: "$1 " \nproduct: "$2 " \nversion: " $3}'
echo ""

echo "Total of Memory: ${memory_info}" |sed 's/"//g'
echo ""

echo "Disk Info: $(lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep -E 'disk'|wc -l ) disk(s)"
for disk in $(lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep -E 'disk'|awk '{print "/dev/"$1}'); do

    echo "Disk: $(sudo lsblk -o NAME,SIZE,TYPE |grep -i disk |grep -i $(echo ${disk} |sed 's/(\/dev\/)//g'))"
    echo "Size: $(sudo lsblk -o NAME,SIZE,TYPE |grep -i disk |grep -i $(echo ${disk} |sed 's/\/dev\///g'))"
    smart_info=$(sudo smartctl -A "$disk" |tail +4 2>&1)
    if `echo $smart_info | grep -q "DELL or MegaRaid controller"`; then        
        # Attempt to find the correct device number for MegaRaid
        for i in {0..24}; do
            smart_info=$(sudo smartctl -d megaraid,$i -i $disk 2>&1)
            if ! echo "$smart_info" | grep -q "No such device"; then
                echo "$smart_info" | grep -E 'Device Model|Serial Number|Firmware Version'
                sudo smartctl -d megaraid,$i -A $disk | grep -ie 'Power_On_Hours|Power On Hours' |awk '{print $2": "$10}'
                break
            fi
        done
    else
        smart_disk_info=$(sudo smartctl -i $disk)
        echo "$smart_disk_info" | grep -E 'Model Number|Serial Number|Firmware Version'
        echo "$smart_info" | grep -E 'Power On Hours'
    fi
    echo ""
done
echo ""

echo "PCIE Info:"
sudo lspci -nn -v | while IFS= read -r line; do
    if [[ "$line" =~ ^[0-9a-fA-F]{2}:[0-9a-fA-F]{2}\.[0-9a-fA-F] ]]; then
        bus_id=$(echo $line | awk '{print $1}')
        device_info=$(lspci -nn -v -s $bus_id)
        device_part_number=$(echo "$device_info" | grep -i "Subsystem:" | sed 's/^[[:space:]]*//')
        device_type=""

        if [[ "$line" == *"VGA"* || "$line" == *"3D controller"* ]]; then
            device_type="Graphics Card (GPU)"
        elif [[ "$line" == *"USB"* ]]; then
            device_type="USB Controller"
        elif [[ "$line" == *"SATA"* || "$line" == *"IDE"* || "$line" == *"RAID"* || "$line" == *"Mass storage"* ]]; then
            device_type="Disk Controller"
        elif [[ "$line" == *"Ethernet controller"* ]]; then
            device_type="Network Controller"
        elif [[ "$line" == *"Non-Volatile memory controller"* ]]; then
            device_type="NVMe Controller"
        else
            device_type="Other Device"
        fi

        echo "$device_type: $line"
        if [ -n "$device_part_number" ]; then
            echo "$device_part_number"
        else
            echo "Part Number: Not available"
        fi
        echo ""
    fi
done
echo ""

echo "PSU Info:"
sudo dmidecode -t 39
echo ""

# Combine all collected information into a single row and append to the CSV file
echo "$server,$serial_number,$cpu_info,$motherboard_info,$memory_info,$disk_info,$pcie_info,$power_supply_info" >> $OUTPUT_FILE

echo "Hardware information saved to $OUTPUT_FILE"

