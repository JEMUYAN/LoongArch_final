    .section .text
    .globl _start

# 选择排序：先 A -> B，再原地把 B 排成无符号升序。
# 时间 O(N^2)，额外空间 O(1)。A 不被修改。
# a0=A, a1=B, a2=N; s0=i, s1=j, s2=min_index
_start:
    lu12i.w $a0, 0x1c400
    lu12i.w $a1, 0x1c401
    addi.w  $a2, $r0, 128

    # copy A[0..127] to B[0..127]
    addi.w  $t0, $r0, 0
.Lcopy:
    ld.w    $t1, $a0, 0
    st.w    $t1, $a1, 0
    addi.w  $a0, $a0, 4
    addi.w  $a1, $a1, 4
    addi.w  $t0, $t0, 1
    bne     $t0, $a2, .Lcopy

    lu12i.w $a1, 0x1c401       # restore B base
    addi.w  $s0, $r0, 0         # i
    addi.w  $s3, $a2, -1        # last index = 127

.Louter:
    # min_index = i; j = i + 1
    addi.w  $s2, $s0, 0
    addi.w  $s1, $s0, 1

.Lscan:
    bgeu    $s1, $a2, .Lswap
    slli.w  $t0, $s1, 2
    add.w   $t0, $a1, $t0
    ld.w    $t1, $t0, 0         # B[j]
    slli.w  $t2, $s2, 2
    add.w   $t2, $a1, $t2
    ld.w    $t3, $t2, 0         # B[min_index]
    bltu    $t1, $t3, .Lnew_min # unsigned B[j] < B[min]
    b       .Lnext_j

.Lnew_min:
    addi.w  $s2, $s1, 0
.Lnext_j:
    addi.w  $s1, $s1, 1
    b       .Lscan

.Lswap:
    # Swap B[i] and B[min_index].  Even if equal, the two stores are safe.
    slli.w  $t0, $s0, 2
    add.w   $t0, $a1, $t0
    ld.w    $t1, $t0, 0
    slli.w  $t2, $s2, 2
    add.w   $t2, $a1, $t2
    ld.w    $t3, $t2, 0
    st.w    $t3, $t0, 0
    st.w    $t1, $t2, 0
    addi.w  $s0, $s0, 1
    bne     $s0, $s3, .Louter

.Lhalt:
    b .Lhalt
