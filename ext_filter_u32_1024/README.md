# 练习 2：ExtRAM 无符号阈值稳定过滤

这是一个比“数组计数”更完整的决赛风格练习：它同时覆盖 ExtRAM 连续读取、无符号比较、条件写回、输出指针推进和结果计数。

## 题目

输入为 ExtRAM 中的无符号数组 `A[1024]`，阈值为 `0x80000000`。

```c
uint32_t count = 0;
for (uint32_t i = 0; i < 1024; i++) {
    uint32_t x = A[i];
    if (x >= 0x80000000u)
        B[count++] = x;
}
*result_count = count;
```

要求 `B` 保持原数组中的相对顺序（稳定过滤）。比较是 **unsigned**：`0x80000000` 必须被保留，`0x7fffffff` 必须被丢弃。

## 固定地址

| 项目 | 地址范围 | ExtRAM 镜像偏移 |
|---|---:|---:|
| 输入 `A[1024]` | `0x1c400000 - 0x1c400fff` | `0x0000` |
| 输出计数 | `0x1c401000` | `0x1000` |
| 输出 `B[1024]` 容量 | `0x1c402000 - 0x1c402fff` | `0x2000` |
| 程序复位入口 | BaseRAM `0x1c000000` | - |

## 直接挂载

- 将 `extram_init.bin` 一次性加载到 ExtRAM 基址 `0x1c400000`。
- 将你的 `user-sample.bin` 加载到 BaseRAM 基址 `0x1c000000`。
- CPU 从 `0x1c000000` 复位；写完答案后应停在死循环。

`extram_init.bin` 是 12 KiB 原始二进制镜像，已含输入和清零的输出区域。不要用 `$readmemh` 直接读取原始 `.bin`；若 testbench 仅支持 `$readmemh`，需要先转为文本 `.mem`。

## Docker + Makefile 构建

官方工具链是 Linux x86-64。macOS（尤其 Apple Silicon）使用 Docker 构建。

先在本目录创建一次 `Dockerfile`：

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

随后每次生成你的程序：

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

生成产物为 `user-sample.elf`、`user-sample.bin` 与 `user-sample.asm`。

## 自测

答案和校验器位于 `answer/`，建议自己完成后再使用。将仿真结束后的 ExtRAM 内容从 `0x1c400000` 起 dump 成二进制，再执行：

```bash
python3 answer/check_output.py your_extram_after_run.bin
```

校验器会检查 count 与有效 `B` 区间是否都完全匹配，并验证稳定顺序。
