    .section .text
    .globl _start

# BaseRAM-only variant for memory-interface bring-up.
# Reset PC / program: 0x1c000000 (BaseRAM)
# Input A[1024]:     0x1c010000 .. 0x1c010fff (BaseRAM)
# Result:            0x1c011000 (BaseRAM)
#
# count = number of A[i] equal to A[0].

_start:
    lu12i.w $a0, 0x1c010      # a0 = A base
    lu12i.w $a1, 0x1c011      # a1 = end = A base + 4096
    lu12i.w $a2, 0x1c011      # a2 = result address
    ld.w    $a3, $a0, 0       # a3 = reference = A[0]
    addi.w  $s0, $zero, 0     # s0 = count

.Lloop:
    ld.w    $t0, $a0, 0
    addi.w  $a0, $a0, 4       # independent instruction between load and use
    bne     $t0, $a3, .Lnext
    addi.w  $s0, $s0, 1
.Lnext:
    bne     $a0, $a1, .Lloop

    st.w    $s0, $a2, 0
.Lhalt:
    b       .Lhalt
