    .section .text
    .globl _start

# 2025-style final task, adapted to the 2026 LA32R address map.
# Reset PC / code: 0x1c000000
# Input A[1024]:   0x1c400000 .. 0x1c400fff (uint32_t, little-endian, ExtRAM)
# Result:          0x1c401000 (uint32_t, ExtRAM)
#
# Compute: count = number of A[i] equal to A[0].
# The program deliberately stays resident after the result store, because it
# runs directly after reset and has no supervisor to return to.

_start:
    lu12i.w     $a0, 0x1c400
    lu12i.w     $a1, 0x1c401
    ld.w        $a3, $a0, 0         # reference
    addi.w      $a0, $a0, 4
    addi.w      $a4, $r0, 0         # ptr
    addi.w      $a5, $r0, 255       
    addi.w      $a6, $r0, 1         # count

.Lmain:
    ld.w        $t0, $a0, 0
    ld.w        $t1, $a0, 4
    ld.w        $t2, $a0, 8
    ld.w        $t3, $a0, 12
    xor         $s0, $t0, $a3
    xor         $s1, $t1, $a3
    xor         $s2, $t2, $a3
    xor         $s3, $t3, $a3
    sltui       $s0, $s0, 1
    sltui       $s1, $s1, 1
    sltui       $s2, $s2, 1
    sltui       $s3, $s3, 1
    add.w       $s4, $s0, $s1
    add.w       $s5, $s2, $s3
    addi.w      $a4, $a4, 1
    add.w       $a6, $a6, $s4
    add.w       $a6, $a6, $s5
    addi.w      $a0, $a0, 16
    bne         $a4, $a5, .Lmain

.Lend:
    ld.w        $t0, $a0, 0
    ld.w        $t1, $a0, 4
    ld.w        $t2, $a0, 8
    xor         $s0, $t0, $a3
    xor         $s1, $t1, $a3
    xor         $s2, $t2, $a3
    sltui       $s0, $s0, 1
    sltui       $s1, $s1, 1
    sltui       $s2, $s2, 1
    add.w       $s4, $s0, $s1
    add.w       $s5, $s4, $s2
    add.w       $a6, $a6, $s5
    st.w        $a6, $a1, 0

.Lhalt:
    b       .Lhalt
