TITLE PathFinding

INCLUDE Irvine32.inc
INCLUDE AIDataStruct.inc

EXTERN N:DWORD, MazeMap:BYTE
EXTERN PATH_LENGTH:DWORD, CURRENT_PATH_STEP:DWORD
EXTERN ghostX:DWORD, ghostY:DWORD, targetX:DWORD, targetY:DWORD
EXTERN OPEN_LIST_COUNT:WORD
EXTERN NODE_MAP:BYTE, GHOST_PATH:WORD 
EXTERN OPEN_LIST_BUFFER:WORD

PUBLIC Absolute_Value, Calculate_Manhattan_H, Get_Node_Offset
PUBLIC Heap_Insert, Heap_Extract_Min, Reset_A_Star, A_Star_Search, Reconstruct_Path
PUBLIC Init_Node_Map

.CODE

Init_Node_Map PROC NEAR USES EAX EBX ECX EDX ESI EDI
    
    MOV ECX, 0 ; 使用 ECX 作為 Index (0 ~ 1023)

Init_Loop:
    CMP ECX, TOTAL_NODES
    JGE Init_Done

    ; --- 1. 計算 X 和 Y ---
    ; Y = Index / N
    ; X = Index % N
    MOV EAX, ECX
    MOV EBX, N
    XOR EDX, EDX
    DIV EBX      ; EAX = Y, EDX = X

    ; --- 2. 計算記憶體 Offset ---
    ; Offset = Index * NODE_SIZE_BYTES
    PUSH EAX     ; 保存 Y
    PUSH EDX     ; 保存 X
    
    MOV EAX, ECX
    MOV EBX, NODE_SIZE_BYTES
    MUL EBX
    MOV ESI, EAX ; ESI = Offset

    POP EDX      ; 恢復 X
    POP EAX      ; 恢復 Y

    ; --- 3. 寫入 NODE_MAP ---
    MOV DWORD PTR [NODE_MAP + ESI + NODE_X_POS], EDX
    MOV DWORD PTR [NODE_MAP + ESI + NODE_Y_POS], EAX
    
    ; 順便初始化其他欄位
    MOV WORD PTR [NODE_MAP + ESI + NODE_G_COST], 0FFFFh
    MOV WORD PTR [NODE_MAP + ESI + NODE_F_COST], 0FFFFh
    MOV BYTE PTR [NODE_MAP + ESI + NODE_FLAG], 0

    INC ECX
    JMP Init_Loop

Init_Done:
    RET
Init_Node_Map ENDP

Check_Wall PROC NEAR USES EAX EBX ECX EDX
    
    MOV EAX, EDX    
    MOV EBX, N      
    MUL EBX         
    ADD EAX, ECX    
    
    MOV BL, BYTE PTR MazeMap[EAX]
    
    CMP BL, 1
    JE Is_Wall
    
    CLC 
    RET
    
Is_Wall:
    STC 
    RET
Check_Wall ENDP

Absolute_Value PROC NEAR
    ; 這裡不需要 USES，因為 EAX 是回傳值，不能被恢復
    CMP EAX, 0
    JGE Abs_Done
    NEG EAX
Abs_Done:
    RET
Absolute_Value ENDP

Calculate_Manhattan_H PROC NEAR USES EBX ECX EDX ESI EDI
    ; EAX 是回傳值，不在 USES 列表中
    
    MOV EAX, ECX
    SUB EAX, ESI
    CALL Absolute_Value 
    MOV EBX, EAX

    MOV EAX, EDX
    SUB EAX, EDI
    CALL Absolute_Value 
    
    ADD EAX, EBX
    
    RET
Calculate_Manhattan_H ENDP

Get_Node_Offset PROC NEAR USES EBX ECX EDX

    MOV EAX, EDX  
    MOV EBX, N 
    MUL EBX        
    ADD EAX, ECX
    
    MOV EBX, NODE_SIZE_BYTES
    MUL EBX 
    
    RET
Get_Node_Offset ENDP

Compare_Nodes_F PROC NEAR USES EAX ECX EDX ESI EDI
    
    ; Index A -> Offset A
    MOV ESI, EAX
    MOV EDI, NODE_SIZE_BYTES
    
    ; 這裡內部的 PUSH EAX 是為了乘法運算保存 EAX，這必須保留
    PUSH EAX
    MOV EAX, ESI
    MUL EDI
    MOV ESI, EAX ; ESI = Offset A
    POP EAX 
    ADD ESI, NODE_F_COST

    ; 讀取 F_A
    MOV EDI, OFFSET NODE_MAP
    MOVZX EDI, WORD PTR [EDI + ESI]

    ; Index B -> Offset B
    MOV EAX, EBX
    PUSH EDX ; 這裡的 PUSH EDX 也是運算需要，保留
    MOV ESI, NODE_SIZE_BYTES
    MUL ESI 
    POP EDX
    ADD EAX, NODE_F_COST
    
    ; 讀取 F_B
    MOV ESI, OFFSET NODE_MAP 
    MOVZX ECX, WORD PTR [ESI + EAX]

    CMP EDI, ECX 
    
    RET
Compare_Nodes_F ENDP

Swap_Open_List_Elements PROC NEAR USES EAX EBX

    MOV AX, WORD PTR [OPEN_LIST_BUFFER + ESI*2] 
    MOV BX, WORD PTR [OPEN_LIST_BUFFER + EDI*2] 
    MOV WORD PTR [OPEN_LIST_BUFFER + ESI*2], BX 
    MOV WORD PTR [OPEN_LIST_BUFFER + EDI*2], AX 

    RET
Swap_Open_List_Elements ENDP

Heap_Insert PROC NEAR USES EAX EBX ECX EDX ESI EDI
    
    MOVZX ECX, OPEN_LIST_COUNT 
    MOV WORD PTR [OPEN_LIST_BUFFER + ECX*2], AX 
    INC OPEN_LIST_COUNT 
    
Swim_Loop:
    CMP ECX, 0
    JE Insert_Done

    MOV EAX, ECX
    DEC EAX
    SHR EAX, 1
    MOV EBX, EAX 
    
    MOVZX ESI, WORD PTR [OPEN_LIST_BUFFER + ECX*2] 
    MOVZX EDI, WORD PTR [OPEN_LIST_BUFFER + EBX*2] 
    
    ; 這裡必須保留 PUSH/POP ECX，因為 Compare_Nodes_F 可能會改動 ECX
    ; 雖然 Compare_Nodes_F 現在也有 USES，但在呼叫過程中還是手動保護比較保險
    ; 且此處邏輯是暫存變數保護
    PUSH ECX
    MOV EAX, ESI
    MOV EBX, EDI
    CALL Compare_Nodes_F 
    POP ECX
    
    JNC Insert_Done 
    
    ; 這裡的 PUSH/POP 是為了 Swap 準備參數，必須保留
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
    RET
Heap_Insert ENDP

Heap_Extract_Min PROC NEAR USES EBX ECX EDX ESI EDI
    ; EAX 回傳值，不放入 USES
    
    CMP OPEN_LIST_COUNT, 0
    JE Extract_Empty
    
    MOVZX EAX, WORD PTR [OPEN_LIST_BUFFER + 0] 
    
    DEC OPEN_LIST_COUNT
    MOVZX ECX, OPEN_LIST_COUNT
    MOVZX ESI, WORD PTR [OPEN_LIST_BUFFER + ECX*2] 
    MOV WORD PTR [OPEN_LIST_BUFFER + 0], SI    
    
    MOV ECX, 0 
Sink_Loop:
    MOV EDX, ECX 
    SHL EDX, 1
    INC EDX
    
    MOVZX EBX, OPEN_LIST_COUNT 
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
    RET
Heap_Extract_Min ENDP

Reset_A_Star PROC NEAR USES EAX ECX ESI
    
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

    RET
Reset_A_Star ENDP

A_Star_Search PROC NEAR USES EAX EBX ECX EDX ESI EDI EBP 

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
    CALL Calculate_Manhattan_H 
    POP EDI
    
    MOV WORD PTR [NODE_MAP + EBP + NODE_G_COST], 0 
    MOV WORD PTR [NODE_MAP + EBP + NODE_H_COST], AX 
    MOV WORD PTR [NODE_MAP + EBP + NODE_F_COST], AX 
    
    MOV EAX, EBP
    MOV EBX, NODE_SIZE_BYTES
    XOR EDX, EDX 
    DIV EBX 
    CALL Heap_Insert 
        
    MOV BYTE PTR [NODE_MAP + EBP + NODE_FLAG], 1 
    
Main_AStar_Loop:
    CMP OPEN_LIST_COUNT, 0
    JE No_Path_Found

    CALL Heap_Extract_Min ; EAX = Current Index (0-based)
    
    ; 計算 Offset
    PUSH EAX
    MOV EBX, NODE_SIZE_BYTES
    MUL EBX 
    MOV ESI, EAX ; ESI = Current Offset
    POP EAX      ; EAX = Index
    
    CMP ESI, EDI
    JE Path_Found

    MOV BYTE PTR [NODE_MAP + ESI + NODE_FLAG], 2

    ; [FIX] 從 Index 計算座標 (1-based)
    MOV EBX, N      
    XOR EDX, EDX    
    DIV EBX         ; EAX = y-1, EDX = x-1
    
    MOV ECX, EDX    ; ECX = x
    MOV EDX, EAX    ; EDX = y
    
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
    RET
A_Star_Search ENDP

Process_Neighbor PROC NEAR USES EAX EBX EBP
    
    ; 1. 邊界檢查
    CMP ECX, 0
    JL Skip_Proc
    CMP ECX, MAZE_WIDTH 
    JGE Skip_Proc

    CMP EDX, 0
    JL Skip_Proc
    CMP EDX, MAZE_HEIGHT 
    JGE Skip_Proc
    
    ; 2. 牆壁檢查
    CALL Check_Wall 
    JC Skip_Proc 
    
    ; 3. 取得鄰居 Offset (EBP)
    CALL Get_Node_Offset 
    MOV EBP, EAX
    
    ; 4. 檢查是否在 Closed List
    CMP BYTE PTR [NODE_MAP + EBP + NODE_FLAG], 2
    JE Skip_Proc
    
    ; 5. 計算 New G = Parent.G + 1
    MOVZX EAX, WORD PTR [NODE_MAP + ESI + NODE_G_COST] 
    INC EAX ; EAX = New G
    
    ; 6. 檢查 Open List
    CMP BYTE PTR [NODE_MAP + EBP + NODE_FLAG], 1
    JNE New_Node_Label ; 如果不在 Open List，跳轉處理
    
    ; 如果在 Open List，比較 G 值
    MOVZX EBX, WORD PTR [NODE_MAP + EBP + NODE_G_COST] 
    CMP EAX, EBX
    JGE Skip_Proc ; 如果 New G >= Old G，不更新
    JMP Update_Node_Label

New_Node_Label:
    PUSH EAX 
    
    ; 計算 H 值 (會用到暫存器，所以要保護 context)
    PUSH ECX
    PUSH EDX
    PUSH ESI
    PUSH EDI 
    
    MOV EAX, targetX
    MOV ESI, EAX
    MOV EAX, targetY
    MOV EDI, EAX
    
    CALL Calculate_Manhattan_H
    MOV WORD PTR [NODE_MAP + EBP + NODE_H_COST], AX ; 寫入 H
    
    POP EDI
    POP ESI
    POP EDX
    POP ECX
    
    ; 插入 Heap (需要 Node Index)
    PUSH EAX ; 臨時保存 (雖然這裡 EAX 是 H，後面會被覆蓋)
    MOV EAX, EBP
    MOV EBX, NODE_SIZE_BYTES
    XOR EDX, EDX
    DIV EBX 
    CALL Heap_Insert
    POP EAX 
    
    MOV BYTE PTR [NODE_MAP + EBP + NODE_FLAG], 1
    
    POP EAX 

Update_Node_Label:
    ; 此時 EAX 必須是 New G
    MOV WORD PTR [NODE_MAP + EBP + NODE_G_COST], AX 
    
    ; 計算 F = G + H
    MOVZX EBX, WORD PTR [NODE_MAP + EBP + NODE_H_COST] 
    ADD EBX, EAX 
    MOV WORD PTR [NODE_MAP + EBP + NODE_F_COST], BX 
    
    ; 設定 Parent Index
    PUSH EAX ; 保存 G (因為 DIV 會改 EAX)
    MOV EAX, ESI 
    MOV EBX, NODE_SIZE_BYTES
    XOR EDX, EDX
    DIV EBX 
    MOV WORD PTR [NODE_MAP + EBP + NODE_PARENT], AX 
    POP EAX ; 恢復 G

Skip_Proc:
    RET
Process_Neighbor ENDP

Reconstruct_Path PROC NEAR USES EAX EBX ECX EDI ESI EBP
    
    MOV EAX, EDI 
    MOV EBX, NODE_SIZE_BYTES
    XOR EDX, EDX
    DIV EBX 
    MOV EBX, EAX 

    MOV ECX, PATH_BUFFER_SIZE 
    
Reconstruct_Loop:
    DEC ECX
    MOV WORD PTR [GHOST_PATH + ECX*2], BX 
    
    MOV EAX, EBX
    MOV EBX, NODE_SIZE_BYTES
    MUL EBX 
    MOV ESI, EAX 

    MOVZX EBX, WORD PTR [NODE_MAP + ESI + NODE_PARENT] 

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
    
    RET
Reconstruct_Path ENDP

END
