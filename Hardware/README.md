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

TOTAL-DURATION-TIME-IN-SECONDS is 3600 second by default

```bash
cd  stress-test
```

#### CPU

```bash
cd cpu
./test_cpu.sh <TOTAL-DURATION-TIME-IN-SECONDS>
```

#### GPU

```bash
cd GPU
python3 -m venv gpu-venv
pip3 install -r requirements.txt
./main.sh <TOTAL-DURATION-TIME-IN-SECONDS>
```

#### HDD

```bash
cd hdd
./test_hdd.sh <TOTAL-DURATION-TIME-IN-SECONDS>s
```

#### Memory

```bash
cd cpu
./test_mem.sh <TOTAL-DURATION-TIME-IN-SECONDS>
```

#### Network

```bash
cd network
./test_network.sh <TOTAL-DURATION-TIME-IN-SECONDS>
```