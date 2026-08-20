    .section .text
    .globl _start

# 正确性基线：不做循环展开，优先便于验证。
_start:
    lu12i.w $a0, 0x1c400      # in_ptr = A
    lu12i.w $a1, 0x1c401      # end = A + 4096
    lu12i.w $a2, 0x1c402      # out_ptr = B
    lu12i.w $a3, -524288      # threshold = 0x80000000 (signed 20-bit imm)
    addi.w  $a4, $zero, 0     # count = 0

.Lloop:
    ld.w    $t0, $a0, 0
    addi.w  $a0, $a0, 4       # independent work between load and compare
    sltu    $t1, $t0, $a3     # t1 = (value < threshold), unsigned
    bne     $t1, $zero, .Lskip
    st.w    $t0, $a2, 0
    addi.w  $a2, $a2, 4
    addi.w  $a4, $a4, 1
.Lskip:
    bne     $a0, $a1, .Lloop

    lu12i.w $a2, 0x1c401
    st.w    $a4, $a2, 0
.Lhalt:
    b .Lhalt
