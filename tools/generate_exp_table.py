import math

DEPTH = 64
FRACTIONAL_BITS = 16

scale = 2 ** FRACTIONAL_BITS
score_gap = 0

while True:
    value = int(scale * math.exp(-score_gap / math.sqrt(DEPTH)))
    if value == 0:
        break

    print(f"{score_gap}: {value}")
    score_gap += 1

print("default: 0")
