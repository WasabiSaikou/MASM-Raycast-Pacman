TITLE pathFinding

.MODEL FLAT, STDCALL

INCLUDE Irvine32.inc
INCLUDE AIDataStruct.inc ; <--- 引入常數 (EQU)

; =======================================================
; 外部變數宣告 (EXTERN)
; =======================================================
EXTERN N:DWORD, MazeMap:BYTE
EXTERN PATH_LENGTH:DWORD, CURRENT_PATH_STEP:DWORD
EXTERN ghostX:DWORD, ghostY:DWORD, targetX:DWORD, targetY:DWORD
EXTERN OPEN_LIST_COUNT:WORD
EXTERN NODE_MAP:BYTE, GHOST_PATH:WORD 
EXTERN OPEN_LIST_BUFFER:WORD ; <--- 修正: 必須宣告為 WORD 陣列

; =======================================================
; 程序宣告
; =======================================================
PUBLIC Absolute_Value, Calculate_Manhattan_H, Get_Node_Offset
PUBLIC Heap_Insert, Heap_Extract_Min, Reset_A_Star, A_Star_Search, Reconstruct_Path

.CODE

; -------------------------------------------------------
; Check_Wall
; -------------------------------------------------------
Check_Wall PROC NEAR
    PUSH EAX
    PUSH EBX
    PUSH EDX
    PUSH ECX
    
    DEC ECX
    DEC EDX
    
    MOV EAX, EDX    
    MOV EBX, N      
    MUL EBX         
    ADD EAX, ECX    
    
    MOV BL, BYTE PTR MazeMap[EAX]
    
    CMP BL, 1
    JE Is_Wall
    
    CLC 
    JMP Check_Wall_Done
    
Is_Wall:
    STC 

Check_Wall_Done:
    POP ECX
    POP EDX
    POP EBX
    POP EAX
    RET
Check_Wall ENDP

; -------------------------------------------------------
; Absolute_Value
; -------------------------------------------------------
Absolute_Value PROC NEAR
    CMP EAX, 0
    JGE Abs_Done
    NEG EAX
Abs_Done:
    RET
Absolute_Value ENDP

; -------------------------------------------------------
; Calculate_Manhattan_H
; -------------------------------------------------------
Calculate_Manhattan_H PROC NEAR
    PUSH EBX
    PUSH EDX
    PUSH ESI
    PUSH EDI
    
    MOV EAX, ECX
    SUB EAX, ESI
    CALL Absolute_Value 
    MOV EBX, EAX

    MOV EAX, EDX
    SUB EAX, EDI
    CALL Absolute_Value 
    
    ADD EAX, EBX
    
    POP EDI
    POP ESI
    POP EDX
    POP EBX
    RET
Calculate_Manhattan_H ENDP

; -------------------------------------------------------
; Get_Node_Offset
; -------------------------------------------------------
Get_Node_Offset PROC NEAR
    PUSH EBX
    PUSH EDX
    
    DEC ECX 
    DEC EDX

    MOV EAX, EDX  
    MOV EBX, N 
    MUL EBX        
    ADD EAX, ECX
    
    MOV EBX, NODE_SIZE_BYTES
    MUL EBX 
    
    INC ECX
    INC EDX

    POP EDX
    POP EBX
    RET
Get_Node_Offset ENDP

; -------------------------------------------------------
; Compare_Nodes_F
; -------------------------------------------------------
Compare_Nodes_F PROC NEAR
    PUSH ESI
    PUSH EDI
    PUSH EDX
    
    ; Index A -> Offset A
    MOV ESI, EAX
    MOV EDI, NODE_SIZE_BYTES
    PUSH EAX
    MOV EAX, ESI
    MUL EDI
    MOV ESI, EAX ; ESI = Offset A
    POP EAX 
    ADD ESI, NODE_F_COST

    ; 讀取 F_A (16-bit 讀入 32-bit 暫存器)
    MOV EDI, OFFSET NODE_MAP
    MOVZX EDI, WORD PTR [EDI + ESI] ; <--- 修正: WORD PTR + MOVZX

    ; Index B -> Offset B
    MOV EAX, EBX
    PUSH EDX
    MOV ESI, NODE_SIZE_BYTES
    MUL ESI 
    POP EDX
    ADD EAX, NODE_F_COST
    
    ; 讀取 F_B
    MOV ESI, OFFSET NODE_MAP 
    MOVZX ECX, WORD PTR [ESI + EAX] ; <--- 修正: WORD PTR + MOVZX

    CMP EDI, ECX 
    
    POP EDX
    POP EDI
    POP ESI
    RET
Compare_Nodes_F ENDP

; -------------------------------------------------------
; Swap_Open_List_Elements
; -------------------------------------------------------
Swap_Open_List_Elements PROC NEAR
    PUSH EAX
    PUSH EBX

    ; OPEN_LIST_BUFFER 是 WORD 陣列，必須用 16-bit 暫存器 (AX/BX) 存取
    MOV AX, WORD PTR [OPEN_LIST_BUFFER + ESI*2] 
    MOV BX, WORD PTR [OPEN_LIST_BUFFER + EDI*2] 
    MOV WORD PTR [OPEN_LIST_BUFFER + ESI*2], BX 
    MOV WORD PTR [OPEN_LIST_BUFFER + EDI*2], AX 

    POP EBX
    POP EAX
    RET
Swap_Open_List_Elements ENDP

; -------------------------------------------------------
; Heap_Insert
; -------------------------------------------------------
Heap_Insert PROC NEAR
    PUSH EBX
    PUSH ECX
    PUSH EDX
    PUSH ESI
    PUSH EDI
    
    MOVZX ECX, OPEN_LIST_COUNT ; <--- 修正: WORD to DWORD
    MOV WORD PTR [OPEN_LIST_BUFFER + ECX*2], AX ; <--- 修正: AX 是 Index (16-bit)
    INC OPEN_LIST_COUNT 
    
Swim_Loop:
    CMP ECX, 0
    JE Insert_Done

    MOV EAX, ECX
    DEC EAX
    SHR EAX, 1
    MOV EBX, EAX 
    
    MOVZX ESI, WORD PTR [OPEN_LIST_BUFFER + ECX*2] ; <--- 修正: 讀取 16-bit Index
    MOVZX EDI, WORD PTR [OPEN_LIST_BUFFER + EBX*2] ; <--- 修正: 讀取 16-bit Index
    
    PUSH ECX
    MOV EAX, ESI
    MOV EBX, EDI
    CALL Compare_Nodes_F 
    POP ECX
    
    JNC Insert_Done 
    
    PUSH EAX 
    PUSH EBX

    MOV ESI, ECX
    MOV EDI, EBX
    CALL Swap_Open_List_Elements 

    POP EBX
    POP EAX

    MOV ECX, EBX 
    JMP Swim_Loop

Insert_Done:
    POP EDI
    POP ESI
    POP EDX
    POP ECX
    POP EBX
    RET
Heap_Insert ENDP

; -------------------------------------------------------
; Heap_Extract_Min
; -------------------------------------------------------
Heap_Extract_Min PROC NEAR
    PUSH EBX
    PUSH ECX
    PUSH EDX
    PUSH ESI
    PUSH EDI
    
    CMP OPEN_LIST_COUNT, 0
    JE Extract_Empty
    
    MOVZX EAX, WORD PTR [OPEN_LIST_BUFFER + 0] ; <--- 修正: WORD to DWORD
    
    DEC OPEN_LIST_COUNT
    MOVZX ECX, OPEN_LIST_COUNT
    MOVZX ESI, WORD PTR [OPEN_LIST_BUFFER + ECX*2] 
    MOV WORD PTR [OPEN_LIST_BUFFER + 0], SI    ; <--- 修正: 寫入 16-bit
    
    MOV ECX, 0 
Sink_Loop:
    MOV EDX, ECX 
    SHL EDX, 1
    INC EDX
    
    MOVZX EBX, OPEN_LIST_COUNT ; <--- 修正: 比較前擴展 Count
    CMP EDX, EBX
    JGE Sink_Done 

    MOV ESI, EDX 
    MOV EDI, EDX
    INC EDI      

    CMP EDI, EBX
    JGE Compare_Only_Left 

    PUSH ECX
    PUSH EDX
    
    MOVZX EAX, WORD PTR [OPEN_LIST_BUFFER + ESI*2] 
    MOVZX EBX, WORD PTR [OPEN_LIST_BUFFER + EDI*2] 
    CALL Compare_Nodes_F
    
    POP EDX
    POP ECX

    JC Left_Is_Smaller
    MOV ESI, EDI

Left_Is_Smaller:    
Compare_Only_Left:
    MOVZX EDI, WORD PTR [OPEN_LIST_BUFFER + ECX*2]
    MOVZX EBX, WORD PTR [OPEN_LIST_BUFFER + ESI*2]
    
    PUSH ECX
    PUSH EDX
    
    MOV EAX, EDI
    CALL Compare_Nodes_F
    
    POP EDX
    POP ECX
    
    JNC Sink_Done 
    
    PUSH EAX
    PUSH EBX
    
    MOV EDI, ESI
    CALL Swap_Open_List_Elements 
    
    POP EBX
    POP EAX
    
    MOV ECX, ESI
    JMP Sink_Loop

Extract_Empty:
    MOV EAX, 0FFFFh

Sink_Done:
    POP EDI
    POP ESI
    POP EDX
    POP ECX
    POP EBX
    RET
Heap_Extract_Min ENDP

; -------------------------------------------------------
; Reset_A_Star
; -------------------------------------------------------
Reset_A_Star PROC NEAR
    PUSH EAX
    PUSH ECX
    PUSH ESI
    
    MOV OPEN_LIST_COUNT, 0

    MOV ECX, TOTAL_NODES
    MOV ESI, 0
    
Reset_Loop:
    MOV WORD PTR [NODE_MAP + ESI + NODE_G_COST], 0FFFFh
    MOV WORD PTR [NODE_MAP + ESI + NODE_H_COST], 0
    MOV WORD PTR [NODE_MAP + ESI + NODE_F_COST], 0FFFFh
    MOV WORD PTR [NODE_MAP + ESI + NODE_PARENT], 0FFFFh
    MOV BYTE PTR [NODE_MAP + ESI + NODE_FLAG], 0
    
    ADD ESI, NODE_SIZE_BYTES
    LOOP Reset_Loop
    
    MOV PATH_LENGTH, 0
    MOV CURRENT_PATH_STEP, 0

    POP ESI
    POP ECX
    POP EAX
    RET
Reset_A_Star ENDP

; -------------------------------------------------------
; A_Star_Search
; -------------------------------------------------------
A_Star_Search PROC NEAR
    PUSH EAX
    PUSH EBX
    PUSH ECX
    PUSH EDX
    PUSH ESI
    PUSH EDI
    PUSH EBP 

    CALL Reset_A_Star
    
    MOV EAX, ghostX 
    MOV ECX, EAX     
    MOV EAX, ghostY
    MOV EDX, EAX     
    CALL Get_Node_Offset 
    MOV EBP, EAX     

    MOV EAX, targetX
    MOV ECX, EAX
    MOV EAX, targetY
    MOV EDX, EAX
    CALL Get_Node_Offset 
    MOV EDI, EAX

    PUSH EDI 
    MOV ECX, ghostX
    MOV EDX, ghostY
    MOV ESI, targetX
    MOV EDI, targetY
    CALL Calculate_Manhattan_H ; EAX = H (32-bit)
    POP EDI
    
    ; 修正: 將 32-bit EAX 轉為 16-bit 寫入
    MOV WORD PTR [NODE_MAP + EBP + NODE_G_COST], 0 
    MOV WORD PTR [NODE_MAP + EBP + NODE_H_COST], AX 
    MOV WORD PTR [NODE_MAP + EBP + NODE_F_COST], AX 
    
    MOV EAX, EBP
    MOV EBX, NODE_SIZE_BYTES
    XOR EDX, EDX 
    DIV EBX ; EAX = Start Node Index
    CALL Heap_Insert 
        
    MOV BYTE PTR [NODE_MAP + EBP + NODE_FLAG], 1 
    
Main_AStar_Loop:
    CMP OPEN_LIST_COUNT, 0
    JE No_Path_Found

    CALL Heap_Extract_Min ; EAX = Current Index
    
    MOV EBX, NODE_SIZE_BYTES
    MUL EBX 
    MOV ESI, EAX ; ESI = Current Offset
    
    CMP ESI, EDI
    JE Path_Found

    MOV BYTE PTR [NODE_MAP + ESI + NODE_FLAG], 2

    MOV ECX, DWORD PTR [NODE_MAP + ESI + NODE_X_POS] 
    MOV EDX, DWORD PTR [NODE_MAP + ESI + NODE_Y_POS] 
    
    ; --- Check UP ---
    PUSH ECX
    PUSH EDX
    DEC EDX 
    CALL Process_Neighbor
    POP EDX
    POP ECX
    
    ; --- Check DOWN ---
    PUSH ECX
    PUSH EDX
    INC EDX 
    CALL Process_Neighbor
    POP EDX
    POP ECX
    
    ; --- Check LEFT ---
    PUSH ECX
    PUSH EDX
    DEC ECX 
    CALL Process_Neighbor
    POP EDX
    POP ECX
    
    ; --- Check RIGHT ---
    PUSH ECX
    PUSH EDX
    INC ECX 
    CALL Process_Neighbor
    POP EDX
    POP ECX

    JMP Main_AStar_Loop  
    
Path_Found:
    STC 
    CALL Reconstruct_Path 
    JMP Search_Done

No_Path_Found:
    CLC

Search_Done:
    POP EBP
    POP EDI
    POP ESI
    POP EDX
    POP ECX
    POP EBX
    POP EAX
    RET
A_Star_Search ENDP

; -------------------------------------------------------
; Process_Neighbor
; -------------------------------------------------------
Process_Neighbor PROC NEAR
    PUSH EAX
    PUSH EBX
    PUSH EBP
    
    CMP ECX, 1
    JL Skip_Proc
    CMP ECX, MAZE_WIDTH ; 使用常數
    JG Skip_Proc
    CMP EDX, 1
    JL Skip_Proc
    CMP EDX, MAZE_HEIGHT ; 使用常數
    JG Skip_Proc
    
    CALL Check_Wall 
    JC Skip_Proc 
    
    CALL Get_Node_Offset 
    MOV EBP, EAX
    
    CMP BYTE PTR [NODE_MAP + EBP + NODE_FLAG], 2
    JE Skip_Proc
    
    MOVZX EAX, WORD PTR [NODE_MAP + ESI + NODE_G_COST] ; <--- 修正: 讀 16-bit
    INC EAX 
    
    CMP BYTE PTR [NODE_MAP + EBP + NODE_FLAG], 1
    JNE New_Node
    
    MOVZX EBX, WORD PTR [NODE_MAP + EBP + NODE_G_COST] ; <--- 修正: 讀 16-bit
    CMP EAX, EBX
    JGE Skip_Proc 
    JMP Update_Node

New_Node:
    PUSH ECX
    PUSH EDX
    PUSH ESI
    PUSH EDI 
    
    MOV EAX, targetX
    MOV ESI, EAX
    MOV EAX, targetY
    MOV EDI, EAX
    
    CALL Calculate_Manhattan_H
    MOV WORD PTR [NODE_MAP + EBP + NODE_H_COST], AX ; <--- 修正: 寫入 16-bit
    
    POP EDI
    POP ESI
    POP EDX
    POP ECX
    
    PUSH EAX 
    MOV EAX, EBP
    MOV EBX, NODE_SIZE_BYTES
    XOR EDX, EDX
    DIV EBX 
    CALL Heap_Insert
    POP EAX 
    
    MOV BYTE PTR [NODE_MAP + EBP + NODE_FLAG], 1

Update_Node:
    MOV WORD PTR [NODE_MAP + EBP + NODE_G_COST], AX 
    
    MOVZX EBX, WORD PTR [NODE_MAP + EBP + NODE_H_COST] ; <--- 修正: 16-bit
    ADD EAX, EBX 
    MOV WORD PTR [NODE_MAP + EBP + NODE_F_COST], AX 
    
    MOV EAX, ESI 
    MOV EBX, NODE_SIZE_BYTES
    XOR EDX, EDX
    DIV EBX 
    MOV WORD PTR [NODE_MAP + EBP + NODE_PARENT], AX ; <--- 修正: 寫入 16-bit Index

Skip_Proc:
    POP EBP
    POP EBX
    POP EAX
    RET
Process_Neighbor ENDP

; -------------------------------------------------------
; Reconstruct_Path
; -------------------------------------------------------
Reconstruct_Path PROC NEAR
    PUSH EAX
    PUSH EBX
    PUSH ECX
    PUSH EDI
    PUSH ESI
    PUSH EBP
    
    MOV EAX, EDI 
    MOV EBX, NODE_SIZE_BYTES
    XOR EDX, EDX
    DIV EBX 
    MOV EBX, EAX 

    MOV ECX, PATH_BUFFER_SIZE 
    
Reconstruct_Loop:
    DEC ECX
    MOV WORD PTR [GHOST_PATH + ECX*2], BX ; <--- 修正: 寫入 16-bit
    
    MOV EAX, EBX
    MOV EBX, NODE_SIZE_BYTES
    MUL EBX 
    MOV ESI, EAX 

    MOVZX EBX, WORD PTR [NODE_MAP + ESI + NODE_PARENT] ; <--- 修正: 讀取 16-bit

    CMP EBX, 0FFFFh 
    JNE Reconstruct_Loop
    
    MOV EAX, PATH_BUFFER_SIZE
    SUB EAX, ECX
    MOV PATH_LENGTH, EAX
    MOV CURRENT_PATH_STEP, 0
    
    MOV ESI, ECX
    MOV EDI, 0
    MOV ECX, PATH_LENGTH
    
Move_Path_Loop:
    MOV AX, WORD PTR [GHOST_PATH + ESI*2] 
    MOV WORD PTR [GHOST_PATH + EDI*2], AX 
    INC ESI
    INC EDI
    LOOP Move_Path_Loop
    
    POP EBP
    POP ESI
    POP EDI
    POP ECX
    POP EBX
    POP EAX
    RET
Reconstruct_Path ENDP

END
