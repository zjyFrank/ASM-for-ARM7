.arm
.text
@方法1
@.extern myRandom  @调用c,用来生成伪随机数(1-m)
@--------------------------------
@   #include "stdlib.h"
@   int myRandom(int m)
@   {
@      return 1 + rand() % m ;
@   }
@--------------------------------
@ cmd : arm-uclinuxeabi-gcc.exe -Wall -S -mcpu=arm7tdmi myRandom.c

@方法2
@调用SWI SWI_GetTicks获取当前时间，作为伪随机数，然后取模

@ 常量声明
.equ column,40
.equ row,15
.equ edge,'*'
.equ head,'H'
.equ body,'O'
.equ blank,' '  @ 置为blank
.equ food,'$'
.equ up   ,1    @up键按下
.equ down ,2    @down键按下
.equ left ,3    @left键按下
.equ right,4    @right键按下
.equ BLUE_KEY_01, 0x02      @button(1)
.equ BLUE_KEY_04, 0x10      @button(4)
.equ BLUE_KEY_05, 0x20      @button(5)
.equ BLUE_KEY_06, 0x40      @button(6)
.equ SWI_GetTicks, 0x6d     @获取当前时间

@ clear screen
    SWI 0x206

@打印地图
@------------------------------------------------
Draw_map:
    @ top
    Draw_1st_line:
        MOV r3,#column
        BL Draw_row
    @ bottom
    Draw_end_line:
        MOV r3,#column
        MOV r0,#0
        MOV r1,#14
        BL Draw_row
    @ left
    Draw_left_side:
        MOV r0,#0
        MOV r1,#0
        MOV r3,#row
        BL Draw_column
    @ right
    Draw_right_side:
        MOV r0,#39
        MOV r1,#0
        MOV r3,#row
        BL Draw_column

    B Init
    @ 画行子函数
    Draw_row:
        MOV r2,#edge
        SWI 0x207
        ADD r0,r0,#1
        SUBS r3,r3,#1
        BNE Draw_row
    MOV pc,lr
    @ 画列子函数
    Draw_column:
        SWI 0x207
        ADD r1,r1,#1
        SUBS r3,r3,#1
        BNE Draw_column
    MOV pc,lr
@------------------------------------------------

@初始化
@------------------------------------------------
Init:
    MOV r4,#right   @ r4:direction
    MOV r5,#10      @ r5:sheadx
    MOV r6,#7       @ r6:sheady
    LDR r7,=sbodyx  @ r7:sbodyx 
    LDR r8,=sbodyy  @ r8:sbodyy
    MOV r9,#3       @ r9:length of snake
        
    Init_head:
        MOV r0,r5
        MOV r1,r6
        MOV r2,#head
        SWI 0x207

    Init_body:
        LDR r0,[r7],#4
        LDR r1,[r8],#4
        MOV r2,#body
        SWI 0x207
        SUBS r9,r9,#1
        BNE Init_body 
    @打印head坐标
    MOV r0,#2
    MOV r1,#14
    LDR r2,=Message2
    SWI 0x204   
    MOV r0,#10
    MOV r1,#14
    MOV r2,r5
    SWI 0x205
    MOV r0,#12
    MOV r1,#14
    MOV r2,#','
    SWI 0x207
    MOV r0,#13
    MOV r1,#14
    MOV r2,r6
    SWI 0x205

    @打印score
    MOV r0,#15
    MOV r1,#14
    LDR r2,=Message4
    SWI 0x204

    MOV r9,#3
    MOV r0,#26
    MOV r1,#14
    SUB r2,r9,#3
    SWI 0x205
    
    @打印用户
    MOV r0,#28
    MOV r1,#14
    LDR r2,=Message5
    SWI 0x204

    BL Creat_food
@---------------------------------------------------------------

@主循环
@---------------------------------------------------------------    
    MOV r9,#3
Main_loop:
    LDR r7,=sbodyx
    LDR r8,=sbodyy

    @延时
    BL Delay

    @更新尾巴
    Update_tail:
        MOV r1,#4
        MUL r0,r9,r1        @ r0 = r9 * 4
        ADD r7,r7,r0        @ r7 指向前一蛇尾x坐标
        ADD r8,r8,r0        @ r8 指向前一蛇尾y坐标
        LDR r0,[r7,#-4]     @ r0 = 当前蛇尾x坐标
        LDR r1,[r8,#-4]     @ r1 = 当前蛇尾y坐标
        STR r0,[r7]         @ 更新前一蛇尾x坐标 = 当前蛇尾x坐标
        STR r1,[r8]         @ 更新前一蛇尾y坐标 = 当前蛇尾y坐标
        
        @若未吃到食物,delete当前蛇尾
        @否则, not delete(等效于伸长)
        MOV r2,#blank       
        SWI 0x207

        SUB r7,r7,#4        @ r7 指向更新后当前蛇尾x坐标
        SUB r8,r8,#4        @ r8 指向更新后当前蛇尾y坐标
        
    @旧头 H 更换为身体 O
    Oldhead_to_body:
        MOV r0,r5
        MOV r1,r6
        MOV r2,#body
        SWI 0x207

    @更新body数组
    STMFD sp!,{r9}
    SUB r9,r9,#1
    Update_body:
        LDR r0,[r7,#-4]
        STR r0,[r7],#-4
        LDR r0,[r8,#-4]
        STR r0,[r8],#-4
        SUBS r9,r9,#1
        BNE Update_body
    LDMFD sp!,{r9}
        @ 更新body数组的第一个元素 = 旧头坐标
        STR r5,[r7] 
        STR r6,[r8]

    @添加新头
    Draw_new_head:
        CMP r4,#up
        BEQ key_up
        CMP r4,#down
        BEQ key_down
        CMP r4,#left
        BEQ key_left
        CMP r4,#right
        BEQ key_right
        Draw:
            MOV r0,r5
            MOV r1,r6
            MOV r2,#head
            SWI 0x207

    @吃食物判断
    LDR r0,=foodx
    LDR r1,=foody
    Judge_foodX:
        LDR r0,[r0]
        CMP r5,r0
        BEQ Judge_foody
        B next1
    Judge_foody:
        LDR r1,[r1]
        CMP r6,r1
        ADDEQ r9,r9,#1      @蛇长+1
        BLEQ Creat_food     @产生新的食物
    next1:

    @更新显示shead坐标
    MOV r0,#10
    MOV r1,#14
    LDR r2,=Message3
    SWI 0x204

    MOV r0,#13
    MOV r1,#14
    LDR r2,=Message3
    SWI 0x204  

    MOV r0,#10
    MOV r1,#14
    MOV r2,r5
    SWI 0x205   @sheadx

    MOV r0,#13
    MOV r1,#14
    MOV r2,r6
    SWI 0x205   @sheady

    @更新显示分数
    MOV r0,#26
    MOV r1,#14
    LDR r2,=Message3
    SWI 0x204 

    MOV r0,#26
    MOV r1,#14
    SUB r2,r9,#3
    SWI 0x205

    @撞身体判断(sheadx==sbodyx && sheady==sbodyy)
    MOV r2,r9
    SUB r2,r2,#1    @ r2 循环次数
    Touch_body:
            LDR r0,[r7]
            CMP r5,r0
            BEQ Judge_y
            B next
        Judge_y:
            LDR r1,[r8]
            CMP r6,r1
            BEQ Game_over
            
        next:
            ADD r7,r7,#4
            ADD r8,r8,#4
            SUBS r2,r2,#1
        BNE Touch_body

    @撞墙判断
    CMP r5,#0
    BEQ Game_over
    CMP r5,#39
    BEQ Game_over
    CMP r6,#0
    BEQ Game_over
    CMP r6,#14
    BEQ Game_over

B Main_loop
@--------------------------------MAIN END---------------------------

@--------------------------------FUNCTION---------------------------
@生成食物 Func
Creat_food:
    @生成伪随机数
    Creat_rand:
        SWI SWI_GetTicks    @获取当前时间，作为伪随机数
        AND r0,r0,#0xFF
        MOV r1,r0
        @ 取模
        Modx:
            CMP r1,#37
            BLS Randx
            SUBHI r1,r1,#38
            B Modx
        
        Randx:
            ADD r1,r1,#1
            STMFD sp!,{r1}

        SWI SWI_GetTicks    @获取当前时间，作为伪随机数
        AND r0,r0,#0xFF
        MOV r1,r0
        @ 取模
        Mody:
            CMP r1,#12
            BLS Randy
            SUBHI r1,r1,#13
            B Mody
        Randy:
            ADD r1,r1,#1    @ r1
            LDMFD sp!,{r0}  @ r0

    LDR r2,=foodx
    STR r0,[r2]     @ r0 : 1-38的随机数

    LDR r2,=foody
    STR r1,[r2]     @ r1 : 1-13的随机数

    MOV r2,#food
    SWI 0x207
MOV pc,lr

    
@延时 Func
Delay:
    MOV r3,#0x1  @时长
Delay_loop:
    SWI 0x203       @轮询(查询)
    @判断按键
    CMP r0,#BLUE_KEY_01
    MOVEQ r4,#up      @up键按下
    CMP r0,#BLUE_KEY_05
    MOVEQ r4,#down    @down键按下
    CMP r0,#BLUE_KEY_04
    MOVEQ r4,#left    @left键按下
    CMP r0,#BLUE_KEY_06
    MOVEQ r4,#right   @right键按下

    @如果r0被更改，立即触发改变direction
    CMP r0,#0
    BNE Update_tail

    SUBS r3,r3,#1
    BNE Delay_loop
MOV pc,lr

@按键判断
Key:
    @up键按下
    key_up:
        SUB r6,r6,#1    @ y-1
        B Draw

    @down键按下
    key_down:
        ADD r6,r6,#1    @ y+1
        B Draw

    @left键按下
    key_left:
        SUB r5,r5,#1    @ x-1
        B Draw

    @right键按下
    key_right:
        ADD r5,r5,#1    @ x+1
        B Draw

@游戏结束
Game_over:
    MOV r0,#15
    MOV r1,#7
    LDR r2,=Message1
    SWI 0x204   @ display GAME OVER

.data
sbodyx: .word  9, 8, 7 
        .space 100
sbodyy: .word  7, 7, 7
        .space 100
foodx:  .word 0
foody:  .word 0
Message1:.asciz "GAME OVER !"
Message2:.asciz " head = "
Message3:.asciz "  "
Message4:.asciz " / SCORE = "
Message5:.asciz "/ usr:ZJY "

.end