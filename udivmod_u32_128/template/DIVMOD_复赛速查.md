# LoongArch C3：可复用 unsigned `div/mod` 模板

文件 `divmod_u32_template.s` 提供完整 `uint32_t` 无符号除法和取模子程序，不使用 `div`、`mod` 或 `mul`。

## 调用约定

```text
调用前：a0 = dividend，a1 = divisor（必须非 0）
调用：  bl udivmod_u32
返回后：a0 = dividend / divisor
          a1 = dividend % divisor
破坏：  t0-t5、a0、a1、ra
```

例如：

```asm
ld.w    $a0, $s0, 0       # dividend
ld.w    $a1, $s0, 4       # divisor, must be nonzero
addi.w  $s0, $s0, 8       # 给 load 与函数使用留独立工作
bl      udivmod_u32
st.w    $a0, $s1, 0       # quotient
st.w    $a1, $s2, 0       # remainder
```

## 必须记住的四点

1. 全部是 **unsigned** 语义：比较使用 `sltu`，不能改成 `slt`。
2. 余数必须用 33 位 `rem_hi:rem_lo` 表示。只用 32 位余数，会在 divisor 高位为 1 的输入上出错。
3. `0x80000000` 的 mask 用旧工具链构造时写为：

   ```asm
   lu12i.w $t3, -524288     # 即 -0x80000，寄存器值为 0x80000000
   ```

4. 模板前提是 `divisor != 0`。题目允许除数为 0 时，调用前必须单独分支定义行为。

## 算法骨架

```c
q = 0; rem = 0;
for (bit = 31; bit >= 0; bit--) {
    rem = (rem << 1) | ((a >> bit) & 1);
    if (rem >= b) {
        rem -= b;
        q |= 1u << bit;
    }
}
```

固定执行 32 轮，因此复杂度是 `O(32)`，与被除数大小无关。`a % b` 就是最终余数；只要余数时忽略返回的 `$a0` 即可。

## 不要误改的部分

- 不能把 `rem_hi` 删除；
- 不能把 `sltu $t5, $t1, $a1` 改为 signed `slt`；
- 不能把 `srli.w $t2, $t1, 31` 改为对 `$t2` 本身移位；它必须取旧的 `rem_lo` 最高位；
- 输入地址与输出地址重叠时，应先确认是否会覆盖尚未读取的下一组输入。
