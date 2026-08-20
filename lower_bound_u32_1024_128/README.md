# 练习 4：ExtRAM unsigned lower_bound

给定已按 **unsigned `uint32_t`** 升序排列的 `A[1024]`（含重复值），对每个 `query[128]` 返回最小下标 `i`：

```c
A[i] >= query
```

若没有这样的元素，返回 `1024`。这就是 C++ `lower_bound` 的语义；重复值必须返回其第一次出现的位置。

## 地址

| 内容 | 地址范围 | ExtRAM 镜像偏移 |
|---|---:|---:|
| 有序 `A[1024]` | `0x1c400000 - 0x1c400fff` | `0x0000` |
| `query[128]` | `0x1c401000 - 0x1c4011ff` | `0x1000` |
| 输出 `index[128]` | `0x1c402000 - 0x1c4021ff` | `0x2000` |
| 程序入口 | BaseRAM `0x1c000000` | - |

一次性将 `extram_init.bin` 挂载到 ExtRAM `0x1c400000`，将 `user-sample.bin` 挂载到 BaseRAM `0x1c000000`，然后复位。

## 固定二分不变量

始终保持答案在半开区间 `[lo, hi)` 内：

```c
lo = 0; hi = 1024;
while (lo < hi) {
    mid = lo + ((hi - lo) >> 1);
    if (A[mid] < query) lo = mid + 1;
    else hi = mid;
}
return lo;
```

注意：下标、数组元素和 query 都应使用 `sltu`；不能用 signed `slt`。`mid` 不要写成 `(lo+hi)>>1`。

## Docker + Makefile

在当前目录首次创建：

```dockerfile
FROM ubuntu:22.04
RUN apt-get update && DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends make && \
    rm -rf /var/lib/apt/lists/*
```

```bash
docker build --platform linux/amd64 -t la32r-make .
```

每次构建：

```bash
docker run --rm --platform linux/amd64 \
  --user "$(id -u):$(id -g)" \
  -v "$PWD":/work \
  -v /Users/sagm/workspace/nscscc2026个人赛发布包_loongarch_v1.0/loongarch32r-linux-gnusf-2022-05-20:/toolchain:ro \
  -w /work la32r-make \
  make -f Makefile_la all \
    GCCPREFIX=/toolchain/bin/loongarch32r-linux-gnusf- \
    FLAGS='-march=loongarch32r'
```

仿真结束后 dump 至少 12 KiB ExtRAM，并验证：

```bash
python3 answer/check_output.py your_extram_after_run.bin
```

`answer/` 中提供标准汇编、期望镜像和校验器，建议完成后再查看。
