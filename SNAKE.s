.arm
.text

.equ column,40
.equ row,15
.equ edge,'*'
.equ head,'H'
.equ body,'O'
.equ blank,' '      @ 置为blank
.equ up   ,1    @up键按下
.equ down ,2    @down键按下
.equ left ,3    @left键按下
.equ right,4    @right键按下
.equ BLUE_KEY_01, 0x02 @button(1)
.equ BLUE_KEY_04, 0x10 @button(4)
.equ BLUE_KEY_05, 0x20 @button(5)
.equ BLUE_KEY_06, 0x40 @button(6)


@ clear screen
    SWI 0x206

@@打印地图
@---------------------------
@Draw_map:
@    @ top
@    Draw_1st_line:
@        MOV r3,#column
@        BL Draw_row
@    @ bottom
@    Draw_end_line:
@        MOV r3,#column
@        MOV r0,#0
@        MOV r1,#14
@        BL Draw_row
@    @ left
@    Draw_left_side:
@        MOV r0,#0
@        MOV r1,#0
@        MOV r3,#row
@        BL Draw_column
@    @ right
@    Draw_right_side:
@        MOV r0,#39
@        MOV r1,#0
@        MOV r3,#row
@        BL Draw_column
@
@    B Init
@    @ 画行子函数
@    Draw_row:
@        MOV r2,#edge
@        SWI 0x207
@        ADD r0,r0,#1
@        SUBS r3,r3,#1
@        BNE Draw_row
@    MOV pc,lr
@    @ 画列子函数
@    Draw_column:
@        SWI 0x207
@        ADD r1,r1,#1
@        SUBS r3,r3,#1
@        BNE Draw_column
@    MOV pc,lr
@@-----------------------------

@初始化
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
    @打印shead坐标
    MOV r0,#2
    MOV r1,#13
    LDR r2,=Message2
    SWI 0x204   
    MOV r0,#10
    MOV r1,#13
    MOV r2,r5
    SWI 0x205
    MOV r0,#12
    MOV r1,#13
    MOV r2,#','
    SWI 0x207
    MOV r0,#13
    MOV r1,#13
    MOV r2,r6
    SWI 0x205

    
@主循环    
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
        ADD r7,r7,r0        @ r7 指向待伸长的蛇尾坐标x
        ADD r8,r8,r0        @ r7 指向待伸长的蛇尾坐标y
        @STMFD sp!,{r7,r8}   @ r7,r8入栈
        LDR r0,[r7,#-4]     @ r0 = 当前蛇尾坐标x
        LDR r1,[r8,#-4]     @ r1 = 当前蛇尾坐标y
        STR r0,[r7]         @ 更新待伸长的蛇尾坐标x = 当前蛇尾坐标x
        STR r1,[r8]         @ 更新待伸长的蛇尾坐标y = 当前蛇尾坐标y
        SUB r7,r7,#4        @ r7 指向当前蛇尾坐标x
        SUB r8,r8,#4        @ r8 指向当前蛇尾坐标y
        MOV r2,#blank       @ 删除当前蛇尾
        SWI 0x207
        
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

    @更新shead坐标
    MOV r0,#10
    MOV r1,#13
    LDR r2,=Message3
    SWI 0x204

    MOV r0,#13
    MOV r1,#13
    LDR r2,=Message3
    SWI 0x204  

    MOV r0,#10
    MOV r1,#13
    MOV r2,r5
    SWI 0x205   @sheadx

    MOV r0,#13
    MOV r1,#13
    MOV r2,r6
    SWI 0x205   @sheady

    @撞身体判断(sheadx==sbodyx && sheady==sbodyy)
    MOV r2,r9
    SUB r2,r2,#1    @ R2 循环次数
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

B Game_over

@延时子函数
Delay:
    @MOV r3,#0x5000  @时长
    MOV r3,#1  @时长
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

    SWI 0x202
    CMP r0,#0x02
    ADDEQ r9,r9,#1

    SUBS r3,r3,#1
    BNE Delay_loop
MOV pc,lr

@按键判断
Key:
    @up键按下
    key_up:
        SUB r6,r6,#1    @ sheady-1
        B Draw

    @down键按下
    key_down:
        ADD r6,r6,#1
        B Draw

    @left键按下
    key_left:
        SUB r5,r5,#1
        B Draw

    @right键按下
    key_right:
        ADD r5,r5,#1
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
Message1:.asciz "GAME OVER !"
Message2:.asciz "shead = "
Message3:.asciz "  "



.end