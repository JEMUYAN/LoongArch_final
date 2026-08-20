
user-sample.elf:     file format elf32-loongarch


Disassembly of section .text:

1c000000 <_start>:
1c000000:	14388004 	lu12i.w	$r4,115712(0x1c400)
1c000004:	14388025 	lu12i.w	$r5,115713(0x1c401)
1c000008:	14388046 	lu12i.w	$r6,115714(0x1c402)
1c00000c:	02820007 	addi.w	$r7,$r0,128(0x80)
1c000010:	02800008 	addi.w	$r8,$r0,0
1c000014:	02800508 	addi.w	$r8,$r8,1(0x1)
1c000018:	288000ac 	ld.w	$r12,$r5,0
1c00001c:	028010a5 	addi.w	$r5,$r5,4(0x4)
1c000020:	54001400 	bl	20(0x14) # 1c000034 <_start+0x34>
1c000024:	298000d7 	st.w	$r23,$r6,0
1c000028:	028010c6 	addi.w	$r6,$r6,4(0x4)
1c00002c:	5fffe907 	bne	$r8,$r7,-24(0x3ffe8) # 1c000014 <_start+0x14>
1c000030:	50000000 	b	0 # 1c000030 <_start+0x30>
1c000034:	0280000d 	addi.w	$r13,$r0,0
1c000038:	0290000e 	addi.w	$r14,$r0,1024(0x400)
1c00003c:	6c0031ae 	bgeu	$r13,$r14,48(0x30) # 1c00006c <_start+0x6c>
1c000040:	001135cf 	sub.w	$r15,$r14,$r13
1c000044:	004485ef 	srli.w	$r15,$r15,0x1
1c000048:	001035ef 	add.w	$r15,$r15,$r13
1c00004c:	004089f0 	slli.w	$r16,$r15,0x2
1c000050:	00104090 	add.w	$r16,$r4,$r16
1c000054:	28800211 	ld.w	$r17,$r16,0
1c000058:	68000e2c 	bltu	$r17,$r12,12(0xc) # 1c000064 <_start+0x64>
1c00005c:	001501ee 	move	$r14,$r15
1c000060:	53ffdfff 	b	-36(0xfffffdc) # 1c00003c <_start+0x3c>
1c000064:	028005ed 	addi.w	$r13,$r15,1(0x1)
1c000068:	53ffd7ff 	b	-44(0xfffffd4) # 1c00003c <_start+0x3c>
1c00006c:	028001b7 	addi.w	$r23,$r13,0
1c000070:	4c000020 	jirl	$r0,$r1,0
