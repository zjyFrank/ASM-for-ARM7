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

@打印地图
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

Main_loop:
    MOV r9,#3
    @延时
    BL Delay

    @删除尾巴
    Delete_tail:
        STMFD sp!,{r7,r8}   @ r7,r8入栈
        LDR r0,[r7,#-4]!    @ r0为尾部坐标x
        LDR r1,[r8,#-4]!    @ r1为尾部坐标y
        MOV r2,#blank
        SWI 0x207
        
    @旧头作为身体
    Oldhead_to_body:
        MOV r0,r5
        MOV r1,r6
        MOV r2,#body
        SWI 0x207

    @更新body数组
    SUB r9,r9,#1
    Update_body:
        LDR r0,[r7,#-4]
        STR r0,[r7],#-4
        LDR r0,[r8,#-4]
        STR r0,[r8],#-4
        SUBS r9,r9,#1
        BNE Update_body

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
        
        CMP r5,#0
        BEQ Game_over
        CMP r5,#39
        BEQ Game_over
        CMP r6,#0
        BEQ Game_over
        CMP r6,#14
        BEQ Game_over

    LDMFD sp!,{r7,r8}   @ r7,r8出栈
    
    B Main_loop

B Game_over

@延时子函数
Delay:
    MOV r3,#0x5000  @时长
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
    BNE Delete_tail

    SUBS r3,r3,#1
    BNE Delay_loop
MOV pc,lr

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

Game_over:
    MOV r0,#15
    MOV r1,#7
    LDR r2,=Message
    SWI 0x204   @ display GAME OVER


.data
sbodyx: .word  9, 8, 7 
        .space 100
sbodyy: .word  7, 7, 7
        .space 100
Message:.asciz "GAME OVER !"



.end