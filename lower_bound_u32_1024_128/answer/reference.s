    .section .text
    .globl _start

# Outer state: s0=query ptr, s1=output ptr, s2=128, s3=index, s4=A base.
_start:
    lu12i.w $s0, 0x1c401
    lu12i.w $s1, 0x1c402
    lu12i.w $s4, 0x1c400
    addi.w  $s2, $zero, 128
    addi.w  $s3, $zero, 0

.Louter:
    ld.w    $a1, $s0, 0       # target
    addi.w  $s0, $s0, 4
    addi.w  $a0, $s4, 0       # a0 = A base
    bl      .Llower_bound
    st.w    $a0, $s1, 0       # returned index
    addi.w  $s1, $s1, 4
    addi.w  $s3, $s3, 1
    bne     $s3, $s2, .Louter
.Lhalt:
    b .Lhalt

# lower_bound(a0=A base, a1=target) -> a0=index in [0,1024]
# t0=lo, t1=hi, t2=half/span, t3=mid, t4=&A[mid], t5=value/flag, t6=mid+1.
.Llower_bound:
    addi.w  $t0, $zero, 0     # lo = 0
    addi.w  $t1, $zero, 1024  # hi = N (exclusive)

.Lbinary:
    sltu    $t2, $t0, $t1
    beq     $t2, $zero, .Ldone

    sub.w   $t2, $t1, $t0
    srli.w  $t2, $t2, 1
    add.w   $t3, $t0, $t2     # mid = lo + ((hi-lo) >> 1)
    slli.w  $t4, $t3, 2
    add.w   $t4, $a0, $t4
    ld.w    $t5, $t4, 0       # value = A[mid]
    addi.w  $t6, $t3, 1       # independent slot after load
    sltu    $t5, $t5, $a1     # value < target ?
    beq     $t5, $zero, .Lset_hi
    addi.w  $t0, $t6, 0       # lo = mid + 1
    b       .Lbinary

.Lset_hi:
    addi.w  $t1, $t3, 0       # hi = mid
    b       .Lbinary

.Ldone:
    addi.w  $a0, $t0, 0
    jirl    $zero, $ra, 0
