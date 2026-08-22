    .section .text
    .globl _start

# 选择排序：先 A -> B，再原地把 B 排成无符号升序。
# 时间 O(N^2)，额外空间 O(1)。A 不被修改。
# a0=A, a1=B, a2=N; s0=i, s1=j, s2=min_index
_start:
    lu12i.w     $a0, 0x1c400
    lu12i.w     $a1, 0x1c401
    addi.w      $a2, $r0, 9   # N
    addi.w      $a3, $s0, 8   # selection N
    addi.w      $s0, $r0, 0       

.Lcopy:
    addi.w      $s0, $s0, 1
    ld.w        $t0, $a0, 0
    st.w        $t0, $a1, 0
    addi.w      $a0, $a0, 4
    addi.w      $a1, $a1, 4
    bne         $s0, $a2, .Lcopy

    lu12i.w     $a1, 0x1c401
    addi.w      $s0, $r0, 0  

.Louter:
    addi.w      $s1, $s0, 1     # j = i + 1
    addi.w      $s2, $s0, 0     # min_index = i

.Lscan:
    bgeu        $s1, $a2, .Lswap
    slli.w      $s3, $s1, 2
    slli.w      $s4, $s2, 2
    add.w       $s3, $a1, $s3
    add.w       $s4, $a1, $s4
    ld.w        $t0, $s3, 0     # B[j]
    ld.w        $t1, $s4, 0     # B[min]
    bltu        $t0, $t1, .Lnew_min
    b           .Lnext_j

.Lnew_min:
    addi.w      $s2, $s1, 0

.Lnext_j:
    addi.w      $s1, $s1, 1
    b           .Lscan

.Lswap:
    slli.w      $s3, $s0, 2
    slli.w      $s4, $s2, 2
    add.w       $s3, $s3, $a1
    add.w       $s4, $s4, $a1
    ld.w        $t0, $s3, 0     # t0 = B[i]
    ld.w        $t1, $s4, 0     # t1 = B[min]
    st.w        $t1, $s3, 0     # B[i] = B[min]
    st.w        $t0, $s4, 0     # B[min] = t0
    beq         $s0, $a3, .Ldone
    addi.w      $s0, $s0, 1
    b           .Louter

.Ldone:
    b .Ldone
