# 题目：128 个 `u32` 无符号升序排序

从复位地址 `0x1c000000` 开始执行你的 `user-sample.s`。将 ExtRAM 输入数组 `A` 的 128 个 32 位无符号整数，按**无符号升序**排序，写入输出数组 `B`。

## 固定内存布局

| 内容 | 地址范围 | 字节数 |
| --- | --- | ---: |
| 输入 `A[0..127]` | `0x1c400000`–`0x1c4001ff` | 512 |
| 输出 `B[0..127]` | `0x1c401000`–`0x1c4011ff` | 512 |

输入由 `extram_init.bin` 初始化，输出区初始全为零。不得修改 `A`。测试数据含重复值、`0x00000000`、`0x7fffffff`、`0x80000000` 与 `0xffffffff`；因此比较必须是**无符号**比较。

## 本地构建（macOS Docker / WSL 同一套参数）

在 WSL 中已将工具链加入 `PATH` 后：

```bash
make -f Makefile_la all FLAGS='-march=loongarch32r'
```

在 macOS Docker 中：

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

产生的 `user-sample.bin` 加载到 BaseRAM；`extram_init.bin` 加载到 ExtRAM。官方线上平台的编译和评测结果始终为准。

## 验证输出

从仿真导出 ExtRAM 为 `extram_dump.bin` 后：

```bash
python3 answer/check_output.py extram_dump.bin
```

## 建议

先写插入排序：每次从 `A[i]` 取出 `key`，在已排序的 `B[0..i-1]` 中从后向前搬移比 `key` 大的元素，最后写入 `key`。核心条件是 `key < B[j-1]`，应使用 `bltu`、`bgeu` 或 `sltu`，不能使用有符号比较。

这是正确性练习，规模特意定为 128，便于先掌握双层循环、反向搬移、边界 `j == 0` 和无符号比较。若追求性能，可再尝试选择排序、Shell 排序或针对固定数据范围的专用算法。

`answer/selection_sort.s` 提供不使用额外存储的选择排序；`answer/merge_sort.s` 提供自底向上的归并排序，并把 `0x1c402000–0x1c4021ff` 当作 512 B 临时区。具体思路见 [`answer/排序算法对比.md`](answer/排序算法对比.md)。
