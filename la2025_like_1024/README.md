# LA32R 复位直启练习：2025 同款数组计数题（1024 元素）

这是按当前 2026 地址图改写的 2025 决赛题缩小版。CPU 复位后从 BaseRAM 的 `0x1c000000` 取指，数组和结果位于独立的 ExtRAM，**不使用 supervisor**。

## 题目

给定位于 `0x1c400000` 的无符号 32 位数组 `A`，共 `1024` 个元素。求第一个元素 `A[0]` 在整个数组中出现的次数，将 32 位无符号结果写入 `0x1c401000`。

- `A` 的地址范围：`0x1c400000 - 0x1c400fff`，恰好 4096 B，属于 ExtRAM。
- 输出地址：`0x1c401000`，属于 ExtRAM，且不与输入重叠。
- 数组和结果均为 **little-endian** `uint32_t`。
- 可以假定 CPU 具备本题参考解使用的 `lu12i.w`、`ld.w`、`st.w`、`addi.w`、`bne`、`b`。
- 程序写出结果后可死循环，测试平台只检查结果地址。

## 文件与装载方式

| 文件 | 内容 | 要装载到的地址 |
|---|---|---|
| `input_1024_u32_le.bin` | 1024 个输入元素，4096 B | ExtRAM `0x1c400000` |
| `expected_count_u32_le.bin` | 期望答案，4 B | 仅用于比对 |
| `reference_program.bin` | 标准解机器码 | BaseRAM `0x1c000000` |
| `extram_image.bin` | 输入 + 4 B 清零结果槽，4100 B | ExtRAM 基址 `0x1c400000` |
| `reference.s` | 标准答案汇编 | 链接起点 `0x1c000000` |
| `answer.txt` | 答案、基准值和命中下标 | - |

将 `reference_program.bin` 写入 BaseRAM 基址 `0x1c000000`，将 `extram_image.bin` 写入 ExtRAM 基址 `0x1c400000`，并令 PC 复位到 `0x1c000000`。其余 BaseRAM/ExtRAM 空间补零即可。

## 标准答案

输入首元素为 `0xf2345678`，它在数组中恰好出现 **19** 次。因此结果地址 `0x1c401000` 的四字节应为：

```text
13 00 00 00
```

即 little-endian `uint32_t(19)`。

参考汇编见 `reference.s`。它的寄存器约定：

| 寄存器 | 含义 |
|---|---|
| `a0` | 当前数组指针 |
| `a1` | 终止地址（首地址 + 4096） |
| `a2` | 结果地址 |
| `a3` | `A[0]`，比较基准 |
| `s0` | 累计次数 |
| `t0` | 当前元素 |

每轮先 `ld.w`，随后执行无关的 `ptr += 4`，再使用已加载元素比较，避免把 `ld.w` 与比较分支紧贴。该版本是正确性基线；你可在确认结果为 19 后，改成无分支计数或 4/8 路循环展开。

## 重新生成 / 验证

`generate_assets.py` 用固定 LCG 与固定命中位置生成数据，因此可重复运行，内容不会变化。它断言首元素和总命中数，且输出 `answer.txt`。

参考程序的构建命令（Linux/WSL，工具链在 `PATH`）：

```bash
loongarch32r-linux-gnusf-gcc -c -march=loongarch32r -mabi=ilp32s -o reference.o reference.s
loongarch32r-linux-gnusf-gcc -nostdlib -march=loongarch32r -mabi=ilp32s \
  -Wl,-T,link.ld -o reference.elf reference.o
loongarch32r-linux-gnusf-objcopy -O binary reference.elf reference_program.bin
python3 generate_assets.py
```

构建顺序为：先生成 `reference_program.bin`，再运行脚本生成 ExtRAM 数据镜像 `extram_image.bin`。
