    .section .text
    .globl _start

# 自底向上归并排序（unsigned ascending）。
# A=0x1c400000（只读）；B=0x1c401000（最终输出）；TMP=0x1c402000（512 B 临时区）。
# 先将 A 复制到 B。每轮合并后交换 src/dst，段宽依次为 1,2,4,...,64。
# 时间 O(N log N)，额外空间 512 B；N 固定为 128。
#
# s0=width, s1=src base, s2=dst base, s3=group start index,
# s4=src end, s5=left end, s6=B base, s7=TMP base.
_start:
    lu12i.w $a0, 0x1c400       # A
    lu12i.w $a1, 0x1c401       # B
    lu12i.w $a2, 0x1c402       # TMP
    addi.w  $a3, $r0, 128      # N
    addi.w  $s6, $a1, 0
    addi.w  $s7, $a2, 0

    # A -> B，随后 B 是第一轮的 src。
    addi.w  $t0, $r0, 0
.Lcopy_input:
    ld.w    $t1, $a0, 0
    st.w    $t1, $a1, 0
    addi.w  $a0, $a0, 4
    addi.w  $a1, $a1, 4
    addi.w  $t0, $t0, 1
    bne     $t0, $a3, .Lcopy_input

    addi.w  $s0, $r0, 1        # width = 1
    addi.w  $s1, $s6, 0        # src = B
    addi.w  $s2, $s7, 0        # dst = TMP

.Lpass:
    slli.w  $t6, $a3, 2
    add.w   $s4, $s1, $t6      # src_end = src + N*4
    addi.w  $s3, $r0, 0        # group start i = 0

.Lgroup:
    bgeu    $s3, $a3, .Lpass_done
    # left=t0 = src+i*4; mid=t1=min(left+width*4,src_end)
    slli.w  $t6, $s3, 2
    add.w   $t0, $s1, $t6
    slli.w  $t6, $s0, 2
    add.w   $t1, $t0, $t6
    bltu    $s4, $t1, .Lcap_mid
    b       .Lmid_ready
.Lcap_mid:
    addi.w  $t1, $s4, 0
.Lmid_ready:
    addi.w  $s5, $t1, 0         # keep left end; t1 becomes the right cursor
    # right_end=t2=min(mid+width*4,src_end); out=t3 = dst+i*4
    add.w   $t2, $t1, $t6
    bltu    $s4, $t2, .Lcap_right
    b       .Lright_ready
.Lcap_right:
    addi.w  $t2, $s4, 0
.Lright_ready:
    slli.w  $t6, $s3, 2
    add.w   $t3, $s2, $t6

    # t0=left cursor, t1=right cursor, t2=right end, t3=out cursor.
.Lmerge:
    beq     $t0, $s5, .Lcopy_right
    beq     $t1, $t2, .Lcopy_left
    ld.w    $t4, $t0, 0
    ld.w    $t5, $t1, 0
    bltu    $t5, $t4, .Ltake_right
    st.w    $t4, $t3, 0         # left <= right: take left (stable)
    addi.w  $t0, $t0, 4
    addi.w  $t3, $t3, 4
    b       .Lmerge
.Ltake_right:
    st.w    $t5, $t3, 0
    addi.w  $t1, $t1, 4
    addi.w  $t3, $t3, 4
    b       .Lmerge

.Lcopy_left:
    beq     $t0, $s5, .Lnext_group
    ld.w    $t4, $t0, 0
    st.w    $t4, $t3, 0
    addi.w  $t0, $t0, 4
    addi.w  $t3, $t3, 4
    b       .Lcopy_left
.Lcopy_right:
    beq     $t1, $t2, .Lnext_group
    ld.w    $t4, $t1, 0
    st.w    $t4, $t3, 0
    addi.w  $t1, $t1, 4
    addi.w  $t3, $t3, 4
    b       .Lcopy_right

.Lnext_group:
    add.w   $s3, $s3, $s0       # i += 2*width
    add.w   $s3, $s3, $s0
    b       .Lgroup

.Lpass_done:
    # swap src and dst
    addi.w  $t0, $s1, 0
    addi.w  $s1, $s2, 0
    addi.w  $s2, $t0, 0
    slli.w  $s0, $s0, 1
    bltu    $s0, $a3, .Lpass

    # N=128 has seven passes, so final src is TMP. General form copies only if needed.
    beq     $s1, $s6, .Lhalt
    addi.w  $t0, $r0, 0
    addi.w  $t1, $s1, 0
    addi.w  $t2, $s6, 0
.Lcopy_result:
    ld.w    $t3, $t1, 0
    st.w    $t3, $t2, 0
    addi.w  $t1, $t1, 4
    addi.w  $t2, $t2, 4
    addi.w  $t0, $t0, 1
    bne     $t0, $a3, .Lcopy_result

.Lhalt:
    b .Lhalt
