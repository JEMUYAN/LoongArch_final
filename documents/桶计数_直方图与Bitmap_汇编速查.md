# 桶计数、直方图与 Bitmap 汇编速查

适用场景：输入值域较小（例如 `0..255` 或 `0..1023`）的数组，要求统计频率、找众数、判断是否出现、去重计数或计数排序。

## 1. 先选数据结构

| 需求 | 使用 | 每个值占用 |
| --- | --- | ---: |
| `x` 出现了多少次、众数、计数排序 | 直方图 `H[x]` | 4 B (`u32`) |
| `x` 是否出现过、不同值个数、集合交并 | bitmap | 1 bit |

值域 `0..255` 时：直方图为 `256×4=1024 B`；bitmap 仅为 `256 bit=32 B`（8 个 `u32`）。

## 2. 直方图

题目模型：`A[1024]` 是 `u8`，输出 `H[256]`，其中 `H[x]` 是 `x` 出现的次数。

```c
for (int x = 0; x < 256; x++) H[x] = 0;
for (int i = 0; i < 1024; i++) H[A[i]]++;
```

关键地址公式：

```text
输入 A[i] 地址 = A_base + i                 （u8 数组）
桶 H[x] 地址  = H_base + (x << 2)            （u32 桶）
```

### 清零 256 个桶

```asm
# a0 = H 当前地址；a1 = H 结束地址（H_base + 1024）
.Lclear:
    st.w    $r0, $a0, 0
    addi.w  $a0, $a0, 4
    bne     $a0, $a1, .Lclear
```

### 更新一个桶

```asm
# a0 = A 当前指针；a1 = A 结束地址；a2 = H_base
# t0=x, t1=&H[x], t2=H[x]
.Lcount:
    ld.bu   $t0, $a0, 0       # x = A[i]；0..255 必须用无符号读取
    slli.w  $t1, $t0, 2       # x * 4
    add.w   $t1, $a2, $t1
    ld.w    $t2, $t1, 0
    addi.w  $t2, $t2, 1
    st.w    $t2, $t1, 0

    addi.w  $a0, $a0, 1       # A 是字节数组
    bne     $a0, $a1, .Lcount
```

若输入是 `u32 A[]`，只改两处：读取用 `ld.w`，输入指针每轮 `+4`。桶地址仍为 `H_base + (x<<2)`。

### 找众数

```c
best_value = 0; best_count = H[0];
for (int x = 1; x < 256; x++)
    if (H[x] > best_count) {
        best_count = H[x]; best_value = x;
    }
```

```asm
# $best_count < $cur_count 时更新
bltu    $best_count, $cur_count, .Lupdate
```

题目若规定“出现次数相同时取较小值”，只能在严格大于时更新；相等时不更新，自然保留较小下标。

### 直方图可做的题

- 众数、最小未出现值、出现次数是否至少为 `K`；
- 两数组交集：每个值输出 `min(Ha[x], Hb[x])` 次；
- 计数排序：按 `x=0..255`，连续输出 `H[x]` 个 `x`。

## 3. Bitmap

对值 `x`（范围 `0..255`）：

```text
word_index = x >> 5             # x / 32
bit_index  = x & 31             # x % 32
mask       = 1 << bit_index
bitmap[word_index] |= mask
```

地址公式：

```text
bitmap word 地址 = bitmap_base + ((x >> 5) << 2)
```

### 置位一个值

```asm
# a0=A 当前指针；a1=A 结束地址；a2=bitmap 基址
# t0=x, t1=word 地址, t2=bit_index, t3=mask, t4=旧 word
.Lset:
    ld.bu   $t0, $a0, 0
    srli.w  $t1, $t0, 5
    andi    $t2, $t0, 31
    slli.w  $t1, $t1, 2
    add.w   $t1, $a2, $t1

    addi.w  $t3, $r0, 1
    sll.w   $t3, $t3, $t2     # 运行时位号，必须用 sll.w，不能用 slli.w
    ld.w    $t4, $t1, 0
    or      $t4, $t4, $t3
    st.w    $t4, $t1, 0

    addi.w  $a0, $a0, 1
    bne     $a0, $a1, .Lset
```

### 求不同元素个数：首次置位时累加

```asm
ld.w    $t4, $t1, 0
and     $t5, $t4, $t3
bne     $t5, $r0, .Lseen      # 原来已有该位，不增加 distinct
or      $t4, $t4, $t3
st.w    $t4, $t1, 0
addi.w  $distinct, $distinct, 1
.Lseen:
```

此方法比“最终对全部 bitmap word 做 popcount”更直接。若还需 bitmap 本身，初始化时应先把全部 word 清零。

## 4. 取模分桶

桶数为 2 的幂时不需要 `div/mod`：

```text
bucket_count = 256: bucket = x & 255
bucket_count = 16 : bucket = x & 15
bucket_count = 32 : bucket = x & 31
```

非 2 的幂桶数才需要余数算法；不要把 `x & (B-1)` 用在非 2 的幂 `B` 上。

## 5. 易错点与优化边界

- `ld.bu` 与 `ld.b`：前者把 `0xff` 读为 `255`，后者读为 `-1`；值域是无符号字节时用 `ld.bu`。
- 输入数组的元素大小决定输入指针步长；桶的 `u32` 计数器始终是 `+4` 和 `x<<2`。
- 输出区未必预先清零，直方图与 bitmap 最稳妥的做法是自己清零。
- `sll.w` 用于寄存器给出的可变移位位数；`slli.w` 只用于汇编期常数。
- 直方图更新是 `ld.w → +1 → st.w` 的读改写依赖。可以一次读取 4 个输入值，但不能随意先读取 4 个桶再统一回写：若多个输入落入同一桶，会把多次加一错误地合并成一次。
- 使用 bitmap 时，只有值域受题目约束时才可直接下标；完整 `u32` 值域不能直接分配 `2^32` 个桶或位。
