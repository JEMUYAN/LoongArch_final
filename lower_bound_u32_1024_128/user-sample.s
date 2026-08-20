    .section .text
    .globl _start

# Outer state: s0=query ptr, s1=output ptr, s2=128, s3=index, s4=A base.
_start:
    lu12i.w     $a0, 0x1c400
    lu12i.w     $a1, 0x1c401
    lu12i.w     $a2, 0x1c402
    addi.w      $a3, $r0, 128
    addi.w      $a4, $r0, 0

.Lmain:
    addi.w      $a4, $a4, 1
    ld.w        $t0, $a1, 0
    addi.w      $a1, $a1, 4
    bl          .Lsearch
    st.w        $s0, $a2, 0
    addi.w      $a2, $a2, 4
    bne         $a4, $a3, .Lmain
.Lhalt:
    b .Lhalt

.Lsearch:
    addi.w      $t1, $r0, 0         # low
    addi.w      $t2, $r0, 0x400     # high
.Lsearchbody:
    bgeu        $t1, $t2, .Ldone
    sub.w       $t3, $t2, $t1
    srli.w      $t3, $t3, 1         
    add.w       $t3, $t3, $t1       # mid
    slli.w      $t4, $t3, 2         
    add.w       $t4, $a0, $t4       # mid-addr
    ld.w        $t5, $t4, 0         # mid-data
    bltu        $t5, $t0, .Llarger
.Llesser:
    move        $t2, $t3
    b           .Lsearchbody
.Llarger:
    addi.w      $t1, $t3, 1
    b           .Lsearchbody
.Ldone:
    addi.w  $s0, $t1, 0
    jirl    $zero, $ra, 0
