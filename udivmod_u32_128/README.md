# 练习 3：只用 C3 整数指令实现 unsigned div/mod

实现 128 组无符号 32 位除法和取模，不得使用 `div` 或 `mod` 指令。`mul` 虽已实现，但本题标准做法不依赖它。

```c
for (uint32_t i = 0; i < 128; i++) {
    Q[i] = input[i].dividend / input[i].divisor;
    R[i] = input[i].dividend % input[i].divisor;
}
```

保证每个 `divisor != 0`。所有运算均为 `uint32_t`；不要按 signed 解释 `0x80000000` 以上的数据。

## 地址布局

| 内容 | 地址范围 | ExtRAM 镜像偏移 |
|---|---:|---:|
| 输入 `{dividend, divisor}[128]` | `0x1c400000 - 0x1c4003ff` | `0x0000` |
| 商 `Q[128]` | `0x1c401000 - 0x1c4011ff` | `0x1000` |
| 余数 `R[128]` | `0x1c402000 - 0x1c4021ff` | `0x2000` |
| 程序复位入口 | BaseRAM `0x1c000000` | - |

将 `extram_init.bin` 一次性加载至 ExtRAM 基址 `0x1c400000`，将 `user-sample.bin` 加载至 BaseRAM 基址 `0x1c000000`，再复位 CPU。

## 推荐算法：恢复除法 / 移位减法

从 dividend 的 bit31 到 bit0 依次处理：

```c
rem = 0;
q = 0;
for (int bit = 31; bit >= 0; bit--) {
    rem = (rem << 1) | ((dividend >> bit) & 1);
    if (rem >= divisor) {
        rem -= divisor;
        q |= 1u << bit;
    }
}
```

关键：概念上的 `rem` 需要 **33 位**。推荐用 `rem_hi`（0/1）和 `rem_lo` 两个寄存器表示 `[rem_hi:rem_lo]`；如果 `rem_hi=1`，该余数必然大于任何 32 位 divisor。

## Docker + Makefile 构建

官方工具链为 Linux x86-64；macOS 上用 Docker。

首次在当前目录写入 `Dockerfile`：

```dockerfile
FROM ubuntu:22.04
RUN apt-get update && DEBIAN_FRONTEND=noninteractive \\
    apt-get install -y --no-install-recommends make && \\
    rm -rf /var/lib/apt/lists/*
```

构建一次镜像：

```bash
docker build --platform linux/amd64 -t la32r-make .
```

以后编译你的 `user-sample.s`：

```bash
docker run --rm --platform linux/amd64 \\
  --user "$(id -u):$(id -g)" \\
  -v "$PWD":/work \\
  -v /Users/sagm/workspace/nscscc2026个人赛发布包_loongarch_v1.0/loongarch32r-linux-gnusf-2022-05-20:/toolchain:ro \\
  -w /work la32r-make \\
  make -f Makefile_la all \\
    GCCPREFIX=/toolchain/bin/loongarch32r-linux-gnusf- \\
    FLAGS='-march=loongarch32r'
```

## 验证

完成后，dump 从 `0x1c400000` 开始的至少 12 KiB ExtRAM 内容：

```bash
python3 answer/check_output.py your_extram_after_run.bin
```

标准参考汇编、期望输出和校验器在 `answer/`；建议完成后再查看。
