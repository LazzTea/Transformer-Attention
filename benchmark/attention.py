
import math
import torch
from torch.utils import benchmark

DEVICE = "cuda"
RUNS = 1000
B = 1
N = 512
D = 64
SEED = 42

def attention(Q, K, V):
    scores = Q @ K.transpose(-2, -1) / math.sqrt(D)
    weights = torch.softmax(scores, dim=-1)
    return weights @ V

# actual benchmark
torch.manual_seed(SEED)

Q = torch.randn(B, N, D).to(DEVICE)
K = torch.randn(B, N, D).to(DEVICE)
V = torch.randn(B, N, D).to(DEVICE)

if DEVICE == "cuda":
    attention(Q, K, V)
    torch.cuda.synchronize()
    graph = torch.cuda.CUDAGraph()
    with torch.cuda.graph(graph):
        output = attention(Q, K, V)
    run = graph.replay
else:
    run = lambda: attention(Q, K, V)

timer = benchmark.Timer(stmt="run()", globals={"run": run}, num_threads=torch.get_num_threads())
timer.timeit(RUNS) # warmup
result = timer.timeit(RUNS)

# measurements
latency = result.mean
matmul_flops = 4 * B * N * N * D
scaling_flops = B * N * N
softmax_flops = 3 * B * N * N
flops = matmul_flops + scaling_flops + softmax_flops

print(f"Device:           {DEVICE}")
print(f"Latency:          {latency * 1e6:.2f} us")
print(f"Token throughput: {B * N / latency:,.2f} tokens/s")
print(f"FLOPs:            {flops:,}")
print(f"Compute:          {flops / latency / 1e9:.2f} GFLOP/s")
print(f"Accuracy:         {100}%") # this is the reference
