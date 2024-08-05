import torch
import time
import socket
from datetime import datetime
import os
import sys



def get_gpu_memory_info():
    total_memory = []
    for i in range(torch.cuda.device_count()):
        total_memory.append(torch.cuda.get_device_properties(i).total_memory)
    return total_memory

def gpu_stress_test(duration_sec):
    # check amount of exsiting GPUs in server
    num_gpus = torch.cuda.device_count()
    print(f"Found {num_gpus} GPU(s).")

    if num_gpus == 0:
        print("No GPU found. Exiting.")
        return

    # get total of memory gpu
    gpu_memories = get_gpu_memory_info()
    print(f"GPU Memory (bytes): {gpu_memories}")

    # create log files
    hostname = socket.gethostname()
    current_date = datetime.now().strftime('%Y-%m-%d-%s')
    log_filename = f"./output/{current_date}-{hostname}-gpu-testing-result.txt"

    if os.path.exists("output") is False:
        os.mkdir("output")

    with open(log_filename, 'w') as log_file:
        log_file.write(f"Found {num_gpus} GPU(s).\n")
        log_file.write(f"GPU Memory (bytes): {gpu_memories}\n")
        log_file.write(f"Starting GPU stress test on {num_gpus} GPU(s) for {duration_sec} seconds...\n")

        start_time = time.time()
        performance_data = {i: [] for i in range(num_gpus)}
        
        while time.time() - start_time < duration_sec:
            for i in range(num_gpus):
                device = torch.device(f'cuda:{i}')
                memory_in_gb = gpu_memories[i] / (1024 ** 3)
                size = int((memory_in_gb * 0.5) ** 0.5 * 10000)  # ใช้ประมาณ 80% ของหน่วยความจำ
                log_file.write(f"Allocating tensors of size: {size}x{size} on GPU {i}\n")
                print(f"Allocating tensors of size: {size}x{size} on GPU {i}")

                start_event = torch.cuda.Event(enable_timing=True)
                end_event = torch.cuda.Event(enable_timing=True)

                start_event.record()
                a = torch.randn(size, size, device=device)
                b = torch.randn(size, size, device=device)
                c = torch.matmul(a, b)
                d = torch.sum(c)
                end_event.record()

                torch.cuda.synchronize(device)

                elapsed_time_ms = start_event.elapsed_time(end_event) / 1000  # Convert to seconds
                gflops = (2 * size ** 3) / (elapsed_time_ms * 1e9)  # Convert to GFLOPS
                memory_allocated = torch.cuda.memory_allocated(device)
                memory_reserved = torch.cuda.memory_reserved(device)
                memory_free = torch.cuda.memory_reserved(device) - torch.cuda.memory_allocated(device)

                performance_data[i].append({
                    'elapsed_time_ms': elapsed_time_ms,
                    'gflops': gflops,
                    'memory_allocated': memory_allocated,
                    'memory_reserved': memory_reserved,
                    'memory_free': memory_free,
                    'sum_of_elements': d.item()
                })
                log_file.write(f"GPU {i} - Sum of elements: {d.item()}, Time taken: {elapsed_time_ms} s, "
                               f"GFLOPS: {gflops}, Memory allocated: {memory_allocated}, Memory reserved: {memory_reserved}, Memory free: {memory_free}\n")
                print(f"GPU {i} - Sum of elements: {d.item()}, Time taken: {elapsed_time_ms} s, "
                      f"GFLOPS: {gflops}, Memory allocated: {memory_allocated}, Memory reserved: {memory_reserved}, Memory free: {memory_free}")

        log_file.write("GPU stress test completed.\n")
        print("GPU stress test completed.")
        
        # result
        for i in range(num_gpus):
            avg_time = sum(d['elapsed_time_ms'] for d in performance_data[i]) / len(performance_data[i])
            avg_gflops = sum(d['gflops'] for d in performance_data[i]) / len(performance_data[i])
            avg_memory_allocated = sum(d['memory_allocated'] for d in performance_data[i]) / len(performance_data[i])
            avg_memory_reserved = sum(d['memory_reserved'] for d in performance_data[i]) / len(performance_data[i])
            avg_memory_free = sum(d['memory_free'] for d in performance_data[i]) / len(performance_data[i])
            log_file.write(f"GPU {i} - Average time per iteration: {avg_time} s, "
                           f"Average GFLOPS: {avg_gflops}, Average memory allocated: {avg_memory_allocated}, "
                           f"Average memory reserved: {avg_memory_reserved}, Average memory free: {avg_memory_free}\n")
            print(f"GPU {i} - Average time per iteration: {avg_time} s, "
                  f"Average GFLOPS: {avg_gflops}, Average memory allocated: {avg_memory_allocated}, "
                  f"Average memory reserved: {avg_memory_reserved}, Average memory free: {avg_memory_free}")

# duration time in second
duration_sec = int(sys.argv[1])
gpu_stress_test(duration_sec)
