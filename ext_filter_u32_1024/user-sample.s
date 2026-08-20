    .section .text
    .globl _start

# 练习：无符号阈值稳定过滤。
# A[1024]  : ExtRAM 0x1c400000 .. 0x1c400fff
# count    : ExtRAM 0x1c401000
# B[0..]   : ExtRAM 0x1c402000 起；容量 1024 个 word
# threshold: 0x80000000，无符号比较。
#
# 要求：将所有 A[i] >= threshold 的元素，按原有顺序写入 B；
#      将写入元素个数写入 count。复位入口为 0x1c000000。

_start:
    lu12i.w $a0, 0x1c400
    lu12i.w $a1, 0x1c401
    lu12i.w $a2, 0x1c402
    lu12i.w $a3, -0x80000
    addi.w  $a4, $r0, 0
    addi.w  $a5, $r0, 256
    addi.w  $a6, $r0, 0
    .p2align 5
.L1:
    ld.w    $t0, $a0, 0
    ld.w    $t1, $a0, 4
    sltu    $s0, $t0, $a3
    sltu    $s1, $t1, $a3
    sltui   $s0, $s0, 1
    ld.w    $t2, $a0, 8
    sltui   $s1, $s1, 1
    beq     $s0, $r0, 12
    st.w    $t0, $a2, 0
    addi.w  $a2, $a2, 4
    sltu    $s2, $t2, $a3
    beq     $s1, $r0, 12
    st.w    $t1, $a2, 0
    addi.w  $a2, $a2, 4
    add.w   $s4, $s0, $s1
    ld.w    $t3, $a0, 12
    sltu    $s3, $t3, $a3
    sltui   $s2, $s2, 1
    sltui   $s3, $s3, 1
    beq     $s2, $r0, 12
    st.w    $t2, $a2, 0
    addi.w  $a2, $a2, 4
    beq     $s3, $r0, 12
    st.w    $t3, $a2, 0
    addi.w  $a2, $a2, 4
    add.w   $s5, $s2, $s3
    addi.w  $a6, $a6, 1
    add.w   $a4, $a4, $s4
    addi.w  $a0, $a0, 16
    add.w   $a4, $a4, $s5
    bne     $a6, $a5, .L1
.END:
    st.w    $a4, $a1, 0
.Lhalt:
    b .Lhalt
