## Hardware


### Check executable files exist or not

Check if executable files exist. If not , Install it

```bash
./check_binary.sh
```

### Collect hardware details

```bash
./collect_hw_info.sh
```

### stress test on devices

```bash
cd  stress-test
```

#### CPU

TOTAL-DURATION-TIME-IN-SECONDS is 3600 second

```bash
cd cpu
./test_cpu.sh <TOTAL-DURATION-TIME-IN-SECONDS>
```

#### GPU

TOTAL-DURATION-TIME-IN-SECONDS is 3600 second

```bash
cd GPU
python3 -m venv gpu-venv
pip3 install -r requirements.txt
./main.sh <TOTAL-DURATION-TIME-IN-SECONDS>
```

#### HDD

TOTAL-DURATION-TIME-IN-SECONDS is 3600s

```bash
cd hdd
./test_hdd.sh <TOTAL-DURATION-TIME-IN-SECONDS>s
```

#### Memory

TOTAL-DURATION-TIME-IN-SECONDS is 3600 second

```bash
cd cpu
./test_mem.sh <TOTAL-DURATION-TIME-IN-SECONDS>
```

#### Network

TOTAL-DURATION-TIME-IN-SECONDS is 3600 second

```bash
cd network
./test_network.sh <TOTAL-DURATION-TIME-IN-SECONDS>
```