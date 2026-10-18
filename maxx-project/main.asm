.data

sS:
.word 0x00000000
.word 0xfffffc00
.word 0xfffffe00
.word 0xffffff00

Lo:
.word 0x0000000f
.word 0xffffffec

Li:
.word 0x0000001f

.text
.globl __start

__start:  
auipc gp,0x1fc18 
addi gp,gp,16 
auipc sp,0x7fbff 
addi sp,sp,-12 
add s0,sp,zero 
jal ra,main

el:  
j el
nop 
nop 

main:  
lui a5,0x10010 
lw a0,24(a5) 
lui a3,0x10010 
lui a2,0x10010 
lui a1,0x10010 
addi sp,sp,-16 
addi a3,a3,28 
mv a2,a2 
addi a1,a1,16 
sw ra,12(sp) 
jal ra,maxx
lw ra,12(sp) 
li a0,0 
addi sp,sp,16 
ret 

maxx:  
lw a4,0(a1) 
lw a5,4(a1) 
add a0,a0,a4 
lw a4,4(a2) 
add a6,a0,a5 
lw a1,0(a2) 
add a4,a6,a4 
mv a7,a1 
ble a4,a1,maxx28
mv a7,a4 

maxx28:
sub a1,a1,a4 
addi a1,a1,15 
li a4,30 
bltu a4,a1,maxx3c 
addi a7,a7,3

maxx3c:
sw a7,0(a3) 
lw a4,12(a2) 
lw a1,8(a2) 
add a4,a5,a4 
add a1,a0,a1 
mv a7,a4 
ble a1,a4,maxx5c
mv a7,a1 

maxx5c:
sub a4,a4,a1 
addi a4,a4,15 
li a1,30 
bltu a1,a4,maxx70 
addi a7,a7,3 

maxx70:
sw a7,4(a3) 
lw a1,0(a2) 
lw a4,4(a2) 
add a1,a6,a1 
mv a6,a4 
ble a1,a4,maxx8c
mv a6,a1

maxx8c:
sub a4,a4,a1 
addi a4,a4,15 
li a1,30 
bltu a1,a4,maxxa0 
addi a6,a6,3

maxxa0:
sw a6,8(a3) 
lw a4,12(a2) 
lw a1,8(a2) 
add a0,a0,a4 
add a5,a5,a1 
mv a4,a5 
ble a0,a5,maxxc0
mv a4,a0

maxxc0:
sub a5,a5,a0 
addi a5,a5,15 
li a2,30 
bltu a2,a5,maxxd4 
addi a4,a4,3

maxxd4:
sw a4,12(a3) 
ret 
