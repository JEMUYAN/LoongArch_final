    .section .text
    .globl _start

# 正确性基线。除数由测试数据保证非 0。
# 外层：s0=input ptr, s1=Q ptr, s2=R ptr, s3=limit, s4=index.
_start:
    lu12i.w $s0, 0x1c400
    lu12i.w $s1, 0x1c401
    lu12i.w $s2, 0x1c402
    addi.w  $s3, $zero, 128
    addi.w  $s4, $zero, 0

.Louter:
    ld.w    $a0, $s0, 0       # a0 = dividend
    ld.w    $a1, $s0, 4       # a1 = divisor
    addi.w  $s0, $s0, 8       # independent work before entering routine
    bl      .Ludivmod
    st.w    $a0, $s1, 0       # Q[i]
    st.w    $a1, $s2, 0       # R[i]
    addi.w  $s1, $s1, 4
    addi.w  $s2, $s2, 4
    addi.w  $s4, $s4, 1
    bne     $s4, $s3, .Louter
.Lhalt:
    b .Lhalt

# unsigned divmod(a0=dividend, a1=divisor)
# return a0=quotient, a1=remainder.
# rem uses 33 bits, represented as t2: t1 (high bit : low word).
.Ludivmod:
    addi.w  $t0, $zero, 0     # quotient = 0
    addi.w  $t1, $zero, 0     # rem_lo = 0
    addi.w  $t2, $zero, 0     # rem_hi = 0
    lu12i.w $t3, -524288      # mask = 0x80000000

.Lbit:
    and     $t4, $a0, $t3
    sltu    $t4, $zero, $t4   # current dividend bit: 0 or 1

    srli.w  $t2, $t1, 31      # rem_hi = old rem_lo bit 31
    slli.w  $t1, $t1, 1
    or      $t1, $t1, $t4     # rem = (rem << 1) | bit

    # [rem_hi:rem_lo] >= divisor?
    # rem_hi=1 means it is larger than every 32-bit divisor.
    bne     $t2, $zero, .Lsubtract
    sltu    $t5, $t1, $a1
    bne     $t5, $zero, .Lnext

.Lsubtract:
    sub.w   $t1, $t1, $a1
    addi.w  $t2, $zero, 0
    or      $t0, $t0, $t3

.Lnext:
    srli.w  $t3, $t3, 1
    bne     $t3, $zero, .Lbit

    addi.w  $a0, $t0, 0
    addi.w  $a1, $t1, 0
    jirl    $zero, $ra, 0
