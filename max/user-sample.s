	.file	"test.c"
	.text
	.align	2
	.align	4
	.globl	_start
	.type	_start, @function
_start:
    lu12i.w $a0, 0x1c010       # begin
    lu12i.w $a1, 0x1c011       # end
    ori     $a0, $a0, 0x000
    ld.w    $a3, $a0, 0       # reference
    ori     $a0, $a0, 4
    ori     $a1, $a1, 0x000
    addi.w  $a2, $r0, 255     # top
    addi.w  $a4, $r0, 1       # count
    addi.w  $a5, $r0, 0       # ptr
    .p2align 5
.L1:
    ld.w    $t0, $a0, 0
    ld.w    $t1, $a0, 4
    ld.w    $t2, $a0, 8
    ld.w    $t3, $a0, 12
    xor     $t0, $t0, $a3
    xor     $t1, $t1, $a3
    sltui   $t0, $t0, 1
    sltui   $t1, $t1, 1
    add.w   $a4, $a4, $t0
    xor     $t2, $t2, $a3
    add.w   $a4, $a4, $t1
    xor     $t3, $t3, $a3
    sltui   $t2, $t2, 1
    add.w   $a4, $a4, $t2
    sltui   $t3, $t3, 1
    addi.w   $a5, $a5, 1
    add.w   $a4, $a4, $t3
    addi.w  $a0, $a0, 16
    bne     $a2, $a5, .L1
.L2: 
    ld.w    $t0, $a0, 0
    ld.w    $t1, $a0, 4
    ld.w    $t2, $a0, 8  
    xor     $t0, $t0, $a3
    xor     $t1, $t1, $a3
    sltui   $t0, $t0, 1
    sltui   $t1, $t1, 1
    add.w   $a4, $a4, $t0
    xor     $t2, $t2, $a3
    sltui   $t2, $t2, 1
    add.w   $a4, $a4, $t1
    add.w   $a4, $a4, $t2
    st.w    $a4, $a1, 0
    b       0

