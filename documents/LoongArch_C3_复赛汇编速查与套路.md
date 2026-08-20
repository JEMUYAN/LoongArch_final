# LoongArch C3 复赛汇编速查与固定套路

适用原则：**先写一版可验证的朴素循环，再做调度、展开和特定 CPU 优化。** 只用已在自己的 C3 上验证过的指令；不要默认 `mul/div/mod`、伪指令或运行时库一定可用。

## 1. 从 C 伪代码落到汇编的固定流程

写之前先在纸上填五项：

1. 输入/输出的**地址、字节长度、元素宽度、符号性**；
2. 循环不变量：`ptr`、`end`、输出指针、累加器/答案；
3. 每轮读几个元素、指针走多少字节；
4. `N=0`、`N=1`、尾数等边界；
5. 程序返回方式（当前监控程序通常是 `jirl zero, ra, 0`）。

把 C 循环机械翻译为以下骨架：

```c
for (p = begin; p != end; p += 4) {
    x = *(uint32_t *)p;
    body(x);
}
```

```asm
# a0=ptr, a1=end；每个元素 4 B
.Loop:
    ld.w    t0, a0, 0
    addi.w  a0, a0, 4        # 给 ld→use 留一个独立槽
    # body(t0)
    bne     a0, a1, .Loop

jirl    zero, ra, 0
```

对 word 数组，`end = begin + 4*N`；绝不能把 `N`（元素数）和字节数混淆。

## 2. 寄存器分工与常量

建议一题固定一张寄存器表，不要在循环中临时改变含义：

| 用途 | 推荐 | 例子 |
|---|---|---|
| 常零、返回 | `zero(r0)`、`ra(r1)` | `jirl zero, ra, 0` |
| 长生命周期地址 | `a0–a7` | `a0=ptr, a1=end, a2=out, a3=reference` |
| 展开 lane/临时值 | `t0–t8` | `t0–t3` 存 4 次 load 的结果 |
| 累加器/基准值 | `s0–s8` | `s0=count/sum/max` |

### 常量/地址构造

```asm
# 例：构造 0x80400000（高 20 位 + 低 12 位）
lu12i.w  a0, 0x80400
ori      a0, a0, 0x000

# 小偏移只在完整基址上使用
addi.w   a1, a0, 32
ld.w     t0, a0, 12
```

`ld/st` 的偏移是有限宽度立即数。大数组必须先把基址置入寄存器；循环内只放 `0/4/8/...` 小偏移。

## 3. 基础指令：按“数据含义”选，而不是按习惯选

| 需求 | 常用指令 | 要点 |
|---|---|---|
| 读/写 32 位 word | `ld.w` / `st.w` | 偏移单位是**字节**，下一元素 `+4` |
| 读 signed / unsigned byte | `ld.b` / `ld.bu` | `ld.b` 会符号扩展，`ld.bu` 是 `0..255` |
| 写 byte | `st.b` | 常用于 byte 数组/掩码 |
| 加减 | `add.w/sub.w/addi.w` | `.w` 按 32 位结果工作 |
| 移位 | `slli.w/srli.w/srai.w` | `srli` 逻辑右移；`srai` 保留符号位 |
| 位操作 | `and/or/xor/andi/ori/nor` | 相等测试最常用 `xor` |
| signed 比较 | `slt/slti` | `x<y`（有符号）得到 0/1 |
| unsigned 比较 | `sltu/sltui` | 地址、无符号数据、范围通常用它 |
| 分支/跳转 | `beq/bne/blt/bge/jirl` | LoongArch 没有 MIPS delay slot；不要人为塞 `nop` |

### 固定的条件构造

```asm
# eq = (x == y)；结果是 0 或 1，适合直接累加
xor     t0, x, y
sltui   eq, t0, 1

# signed: flag = (x < y)；unsigned 则换 sltu
slt     flag, x, y

# if (x < y) goto .less；unsigned 时使用 sltu
slt     t0, x, y
bne     t0, zero, .less
```

若你只需要“是否相等”而不是 0/1，`xor t0,x,y; bne t0,zero,.not_equal` 更直接。

## 4. load-use：先消除空等，再谈展开

坏例子：

```asm
ld.w    t0, a0, 0
xor     t0, t0, a3          # 紧邻使用：可能触发 load-use 停顿
```

至少插入一个独立工作：

```asm
ld.w    t0, a0, 0
addi.w  a0, a0, 4           # 与 t0 无关
xor     t0, t0, a3
```

若你的 CPU 的实际 load 延迟超过一个周期，必须按波形/仿真测到的距离继续拉开；不要照搬别人的“隔一条就够”。最稳定的方法是：**先连续发射多条 load，再依次处理先发出的 lane。**

```asm
# a0=ptr, a1=main_end, a3=reference, s0=count
.Lmain4:
    ld.w    t0, a0, 0
    ld.w    t1, a0, 4
    ld.w    t2, a0, 8
    ld.w    t3, a0, 12
    xor     t0, t0, a3
    xor     t1, t1, a3
    xor     t2, t2, a3
    xor     t3, t3, a3
    sltui   t0, t0, 1
    sltui   t1, t1, 1
    sltui   t2, t2, 1
    sltui   t3, t3, 1
    add.w   t0, t0, t1
    add.w   t2, t2, t3
    add.w   t0, t0, t2
    add.w   s0, s0, t0
    addi.w  a0, a0, 16
    bne     a0, a1, .Lmain4
```

展开前先求 `main_end = begin + (N/4)*16`，再用一个单元素尾循环处理 `N%4`。可以从 4 路开始；确认寄存器够、代码体积和 ICache 不恶化后，再试 8 路。

## 5. 四类固定套路

### 5.1 数组 max/min/sum/count

**sum**：`sum=0`，每轮 `sum += x`。若可能超过 32 位，须定义题目要求的溢出语义，必要时拆高低位或用可用的 64 位路径。

**count(predicate)**：把 predicate 变成 0/1，再 `add.w`，避免每个元素都分支。

```asm
# count += (x == reference)
xor     t0, x, a3
sltui   t0, t0, 1
add.w   s0, s0, t0
```

**unsigned max**：先拿首元素初始化 `max`，之后比较“旧 max < 新值”。有符号数据将 `sltu` 改为 `slt`；min 的比较方向反过来。

```asm
# a0 已指向剩余元素，s0=max
.Lmax:
    ld.w    t0, a0, 0
    addi.w  a0, a0, 4
    sltu    t1, s0, t0       # old_max < value ?
    beq     t1, zero, .Lkeep
    addi.w  s0, t0, 0        # max = value
.Lkeep:
    bne     a0, a1, .Lmax
```

### 5.2 条件过滤和复制

`dst` 只在命中时前进；`src` 无条件前进。题意若要求稳定顺序，必须保持原遍历顺序。

```asm
# if (x == reference) *out++ = x;
ld.w    t0, a0, 0
addi.w  a0, a0, 4
xor     t1, t0, a3
bne     t1, zero, .Lskip
st.w    t0, a2, 0
addi.w  a2, a2, 4
.Lskip:
```

复制无条件时就是 `ld; st; src+=width; dst+=width`。源和目的可能重叠时，要先判断方向：`dst > src` 且区间重叠则从尾部倒着复制，避免覆盖未读数据。

### 5.3 逐元素变换：abs、sqrt、mod

**绝对值（补码分支消除版）**：

```asm
# y = abs(x)；INT_MIN 的结果仍是 INT_MIN，需按题意单独处理
srai.w  t0, x, 31           # x>=0: 0；x<0: 0xffffffff
xor     y, x, t0
sub.w   y, y, t0
```

**整数平方根** `floor(sqrt(x))`：优先二分答案 `lo..hi`。中点避免 `lo+hi` 溢出：`mid = lo + ((hi-lo)>>1)`。若有乘法，比较 `mid*mid <= x`；如果乘法也不可信，比较 `mid <= x/mid`，但又需要除法，通常不如位试探法实用。二分每轮都要保证 `lo/hi` 严格收缩。

**取模**：若除法/取模指令没实现，用下节的无符号移位减法。负数 `%` 的符号规则需先按题目确定；最简单可靠的路线是先处理符号、对绝对值做 unsigned 核心，再恢复 C 所要求的余数符号。

### 5.4 二分、长除法/移位减法

**二分模板**（寻找最小满足 `predicate(mid)` 的位置）：

```c
while (lo < hi) {
    mid = lo + ((hi - lo) >> 1);
    if (predicate(mid)) hi = mid;
    else lo = mid + 1;
}
```

汇编中先把 `hi-lo` 放到临时寄存器，再 `srli.w 1`，最后加回 `lo`。若 `predicate` 访问数组，先算 `base + mid*4`（`slli.w offset, mid, 2`），再 load；中点值要与下一轮更新之间留出足够 load-use 距离。

**无符号 32 位长除法** `a / b`（要求 `b != 0`）：

```c
rem = 0; q = 0;
for (bit = 31; bit >= 0; --bit) {
    rem = (rem << 1) | ((a >> bit) & 1);
    if (rem >= b) { rem -= b; q |= 1u << bit; }
}
```

汇编映射：`slli.w rem,rem,1`；从 `a` 取当前 bit 后 `or` 进 `rem`；用 `sltu tmp,rem,b` 得到 `rem<b`，据此分支；满足时 `sub.w rem,rem,b`，并用左移得到的掩码 `or` 进商。循环固定 32 次，`rem` 最多接近 `2*b`，在 32 位无符号语义下要谨慎验证边界。`a % b` 的答案就是最终 `rem`。

## 6. 赛场检查单

- 用 `objdump -d` 检查真实发出的指令，确认没有未实现的 `div/mod`、库调用或意外伪指令展开。
- 明确本届地址图；不要把旧届 `0x80...` 与当前 supervisor 的 `0x1c...` 地址段混用。
- 单测至少覆盖：`N=0/1`、全相等、全不等、最大/最小值、末尾恰好命中、`N mod 展开因子 != 0`。
- 保留“朴素正确版”和“优化版”；优化后结果必须逐字节与朴素版比对。
- 调度优化必须基于自己的流水线波形或性能计数/仿真结果；展开并非越大越快，还受寄存器、分支、I/D Cache 和取指带宽影响。

## 7. 最短练习序列

1. word 数组求和、最大值、等于首元素的个数；
2. 复制全部偶数到另一数组并返回输出长度；
3. 对 byte 数组做绝对值/阈值截断；
4. 对有序数组写 lower_bound；
5. 不用 `div/mod` 写 unsigned `a/b` 与 `a%b`；
6. 将第 1 题从单元素循环改为 4 路展开，验证尾循环和 load-use 间隔。
