    .section .text
    .globl _start

# 128 个 unsigned u32 的插入排序（升序）。
# A: 0x1c400000, B: 0x1c401000
# a0=A, a1=B, a2=i, a4=N
_start:
    lu12i.w $a0, 0x1c400
    lu12i.w $a1, 0x1c401
    addi.w  $a2, $r0, 0
    addi.w  $a4, $r0, 128

.Louter:
    # key = A[i]; j = i
    slli.w  $t0, $a2, 2
    add.w   $t0, $a0, $t0
    ld.w    $t1, $t0, 0          # key
    addi.w  $t2, $a2, 0          # j

.Linner:
    beq     $t2, $r0, .Lplace
    addi.w  $t3, $t2, -1         # j - 1
    slli.w  $t4, $t3, 2
    add.w   $t4, $a1, $t4
    ld.w    $t5, $t4, 0          # B[j - 1]
    bltu    $t1, $t5, .Lshift    # key < B[j-1]（无符号）
    b       .Lplace

.Lshift:
    # B[j] = B[j-1]; --j
    slli.w  $t6, $t2, 2
    add.w   $t6, $a1, $t6
    st.w    $t5, $t6, 0
    addi.w  $t2, $t2, -1
    b       .Linner

.Lplace:
    slli.w  $t4, $t2, 2
    add.w   $t4, $a1, $t4
    st.w    $t1, $t4, 0
    addi.w  $a2, $a2, 1
    bne     $a2, $a4, .Louter

.Lhalt:
    b .Lhalt
