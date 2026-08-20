    .section .text
    .globl udivmod_u32

# udivmod_u32: full-range unsigned 32-bit division without div/mod.
#
# Input : $a0 = dividend (uint32_t), $a1 = divisor (uint32_t, nonzero)
# Output: $a0 = quotient,              $a1 = remainder
# Clobbers: $t0-$t5
# Return: jirl $zero, $ra, 0
#
# Conceptual algorithm, from bit31 down to bit0:
#   rem = (rem << 1) | current_dividend_bit
#   if (rem >= divisor) { rem -= divisor; quotient_bit = 1; }
#
# rem needs 33 bits after its left shift.  Store it as:
#   $t2:$t1 = rem_hi:rem_lo
# where rem_hi is always 0 or 1.  This is essential for divisors whose
# high bit is set; a 32-bit-only remainder silently fails on such inputs.

udivmod_u32:
    addi.w  $t0, $zero, 0     # quotient = 0
    addi.w  $t1, $zero, 0     # rem_lo = 0
    addi.w  $t2, $zero, 0     # rem_hi = 0
    lu12i.w $t3, -524288      # mask = 0x80000000; imm20 is signed

.Lbit:
    # bit = ((dividend & mask) != 0)
    and     $t4, $a0, $t3
    sltu    $t4, $zero, $t4   # normalize bit to 0/1

    # rem = (rem << 1) | bit
    srli.w  $t2, $t1, 31      # carry from old rem_lo bit31
    slli.w  $t1, $t1, 1
    or      $t1, $t1, $t4

    # If rem_hi=1 then rem is definitely >= any 32-bit divisor.
    bne     $t2, $zero, .Lsubtract
    sltu    $t5, $t1, $a1     # rem_lo < divisor ?
    bne     $t5, $zero, .Lnext

.Lsubtract:
    sub.w   $t1, $t1, $a1
    addi.w  $t2, $zero, 0
    or      $t0, $t0, $t3     # quotient |= mask

.Lnext:
    srli.w  $t3, $t3, 1       # next bit
    bne     $t3, $zero, .Lbit

    addi.w  $a0, $t0, 0
    addi.w  $a1, $t1, 0
    jirl    $zero, $ra, 0
