TITLE PathFindIng

INCLUDE Irvine32.inc

EXTERN PATH_LENGTH:DWORD, CURRENT_PATH_STEP:DWORD
EXTERN ghostX:DWORD, ghostY:DWORD, targetX:DWORD, targetY:DWORD
EXTERN OPEN_LIST_COUNT:WORD
EXTERN NODE_MAP:BYTE, GHOST_PATH:WORD 
EXTERN GHOST_STATE:BYTE
EXTERN N:DWORD, MazeMap:BYTE ; 來自 maze.asm
EXTERN NODE_SIZE_BYTES:DWORD  ; 雖然是 EQU，但確保它被正確處理或改為 EXTERN

PUBLIC PathFindIng
PUBLIC Absolute_Value, Calculate_Manhattan_H, Get_Node_Offset
PUBLIC Heap_Insert, Heap_Extract_Min, Reset_A_Star, A_Star_Search, Reconstruct_Path

.CODE

; Check_Wall 檢查 (x, y) 座標是否為牆壁
; 輸入: ECX = x (1-based), EDX = y (1-based)
; 輸出: CF=1 (Wall), CF=0 (Path)
Check_Wall PROC NEAR
    PUSH EAX
    PUSH EBX
    PUSH EDX
    PUSH ECX
    
    ; 轉換 1-based 到 0-based
    DEC ECX
    DEC EDX
    
    ; 計算索引 Index = y * N + x
    ;MOVZX EAX, EDX   ; EAX = y
    MOV EBX, N      ; EBX = N (32)
    MUL EBX         ; EAX = y * N
    ;MOVZX EBX, ECX   ; EBX = x
    ADD EAX, EBX    ; EAX = Index
    
    ; 讀取 MazeMap (BYTE 陣列)
    MOV BL, BYTE PTR MazeMap[EAX]
    
    ; 檢查是否為 1 (牆壁)
    CMP BL, 1
    JE Is_Wall
    
    CLC ; Clear Carry (不是牆壁)
    JMP Check_Wall_Done
    
Is_Wall:
    STC ; Set Carry (是牆壁)

Check_Wall_Done:
    POP ECX
    POP EDX
    POP EBX
    POP EAX
    RET
Check_Wall ENDP

; Absolute_Value (Helper) 輸入: EAX = 數字，輸出: EAX = |數字|
Absolute_Value PROC NEAR
    CMP EAX, 0
    JGE Abs_Done ; 如果 EAX >= 0, 跳過
    NEG EAX       ; 否則，取反變為正數
Abs_Done:
    RET
Absolute_Value ENDP

; Calculate_Manhattan_H
; 輸入: ECX, EDX (Current X, Y), ESI, EDI (Target X, Y)
; 輸出: EAX = Manhattan EDIstance H Value
Calculate_Manhattan_H PROC NEAR
    PUSH EBX       ; 保存 EBX
    PUSH EDX       ; 保存 EDX
    PUSH ESI       ; 保存 ESI
    PUSH EDI       ; 保存 EDI
    
    ; 1. 計算 |x1 - x2|
    MOV EAX, ECX    ; EAX = x1
    SUB EAX, ESI    ; EAX = x1 - x2
    CALL Absolute_Value 
    MOV EBX, EAX    ; EBX = |x1 - x2|

    ; 2. 計算 |y1 - y2|
    MOV EAX, EDX    ; EAX = y1
    SUB EAX, EDI    ; EAX = y1 - y2
    CALL Absolute_Value 
    
    ; 3. 計算總和並回傳
    ADD EAX, EBX    ; EAX = |x1 - x2| + |y1 - y2| (H Value)
    POP EDI        ; 恢復 EDI
    POP ESI        ; 恢復 ESI
    POP EDX        ; 恢復 EDX
    POP EBX        ; 恢復 EBX
    RET
Calculate_Manhattan_H ENDP

; Get_Node_Offset (將 (x, y) 1-based 轉為 NODE_MAP 中的記憶體偏移量)
; 輸入: 
;   ECX = x 座標 (0 到 MAZE_WIDTH-1)
;   EDX = y 座標 (0 到 MAZE_HEIGHT-1)
; 輸出:
;   EAX = 節點在 NODE_MAP 中的線性偏移量 (Offset)
Get_Node_Offset PROC NEAR
    PUSH EBX      ; 保存 32-bit 暫存器
    PUSH EDX      ; MUL 會用到 EDX
    
    ; 轉換 1-based 到 0-based 用於內部計算
    DEC ECX 
    DEC EDX

    ; Index = (y * N) + x
    MOVZX EAX, EDX  
    MOV EBX, N     
    MUL EBX        
    MOVZX EBX, ECX  
    ADD EAX, EBX
    
    ; 2. 計算偏移量 Offset = Index * NODE_SIZE_BYTES
    MOV EBX, NODE_SIZE_BYTES ; EBX = 14
    MUL EBX        ; EAX = Offset (Index * 14)
    
    ; 恢復 1-based 座標 (因為呼叫者可能還需要用)
    INC ECX
    INC EDX

    POP EDX
    POP EBX
    RET
Get_Node_Offset ENDP

; Compare_Nodes_F (Helper)，比較兩個節點的 F 值
; 輸入: 
;   EAX = Index_A (第一個節點的線性索引)
;   EBX = Index_B (第二個節點的線性索引)
; 輸出:
;   ZF (Zero Flag) = 1 (兩者 F 值相等)
;   CF (Carry Flag) = 1 (A 的 F 值較小)
;   CF (Carry Flag) = 0 (B 的 F 值較小或相等)
Compare_Nodes_F PROC NEAR
    PUSH ESI        ; 保存暫存器
    PUSH EDI
    
    ; 計算 Index_A 的 F 值偏移量 (Offset_A = Index_A * NODE_SIZE_BYTES + NODE_F_COST)
    MOV ESI, EAX     
    MOV EDI, NODE_SIZE_BYTES
    MUL EDI         ; EDX:EAX = Index_A * 14
    ADD EAX, NODE_F_COST ; EAX = Offset_A

    ; 從 NODE_MAP 讀取 F_A (A的F值)
    MOV ESI, OFFSET NODE_MAP ; ESI 指向 NODE_MAP 的起始
    MOV EDI, [ESI + EAX]     ; EDI = F_A 

    ; 計算 Index_B 的 F 值偏移量
    MOV EAX, EBX
    PUSH EDX ; MUL 使用 EDX
    MOV ESI, NODE_SIZE_BYTES
    MUL ESI         ; EDX:EAX = Index_B * 14
    POP EDX
    ADD EAX, NODE_F_COST ; EAX = Offset_B
    
    ; 從 NODE_MAP 讀取 F_B (B的F值)
    MOV ESI, OFFSET NODE_MAP ; ESI 指向 NODE_MAP 的起始
    MOV ECX, [ESI + EAX]     ; ECX = F_B 

    ; 比較 F_A 和 F_B
    ; CMP EDI, ECX 會影響 CF 旗標
    CMP EDI, ECX ; 比較 F_A (EDI) 和 F_B (ECX)
    
    ; 如果 EDI < ECX (F_A < F_B)，則 CF=1 (符合我們將 CF=1 定義為 A 較小的慣例)
    ; 如果 EDI >= ECX (F_A >= F_B)，則 CF=0
    POP EDI
    POP ESI
    RET
Compare_Nodes_F ENDP


; Swap_Open_List_Elements (Helper)，交換 Open List 中兩個位置的節點索引
; 輸入: 
;   ESI = Index_in_Open_List_A (Open List 中的陣列位置 A)
;   EDI = Index_in_Open_List_B (Open List 中的陣列位置 B)
Swap_Open_List_Elements PROC NEAR
    PUSH EAX
    PUSH EBX

    MOV EAX, [OPEN_LIST_BUFFER + ESI*2] ; 1. 讀取 A 的值到 EAX。ESI*2 因為每個元素是 DW (2 bytes)        
    MOV EBX, [OPEN_LIST_BUFFER + EDI*2] ; 2. 讀取 B 的值到 EBX        
    MOV [OPEN_LIST_BUFFER + ESI*2], EBX ; 3. 交換: 將 B 的值寫入 A 的位置
    MOV [OPEN_LIST_BUFFER + EDI*2], EAX ; 4. 交換: 將 A 的值寫入 B 的位置

    POP EBX
    POP EAX
    RET
Swap_Open_List_Elements ENDP

; Heap_Insert， 將一個新的節點索引插入 Open List 堆積
; 輸入: 
;   EAX = Node_Index (要插入的節點的線性索引)
; 輸出:
;   無。Open List Count 增加 1。
; -------------------------------------------------------
Heap_Insert PROC NEAR
    PUSH EBX
    PUSH ECX
    PUSH EDX
    PUSH ESI
    PUSH EDI
    
    ; 1. 將新節點放在堆積的最後一個位置 (Current = Open_List_Count)
    MOV ECX, OPEN_LIST_COUNT ; ECX = 當前堆積大小 N
    MOV [OPEN_LIST_BUFFER + ECX*2], EAX ; 存入新的 Node Index
    INC OPEN_LIST_COUNT     ; N++
    
    ; 2. 上浮操作開始 (Swim Up)
Swim_Loop:
    CMP ECX, 0
    JE Insert_Done ; 如果 Current = 0 (根節點)，完成

    ; Parent_Index = (Current - 1) / 2
    MOV EAX, ECX     ; EAX = Current
    DEC EAX         ; EAX = Current - 1
    SHR EAX, 1      ; EAX = Parent_Index
    MOV EBX, EAX     ; EBX = Parent_Index
    
    ; 3. 比較 Current 節點 (ECX) 和 Parent 節點 (EBX)，讀取 OPEN_LIST_BUFFER 中的 Node 索引
    MOV ESI, [OPEN_LIST_BUFFER + ECX*2] ; ESI = Child_Node_Index (A)
    MOV EDI, [OPEN_LIST_BUFFER + EBX*2] ; EDI = Parent_Node_Index (B)
    
    ; 比較 F 值 (Compare_Nodes_F 比較 F(ESI) 和 F(EDI))
    PUSH ECX        ; 保存 ECX (Current Index)
    MOV EAX, ESI     ; 設置 Compare_Nodes_F 的 EAX, EBX 輸入
    MOV EBX, EDI
    CALL Compare_Nodes_F 
    POP ECX         ; 恢復 ECX
    
    JNC Insert_Done    ; JNC (Jump if No Carry): 如果 Parent F 值 <= Child F 值 (堆積屬性滿足)，則停止上浮
    
    ; 4. 交換 (Swap): 如果 Child F 值 < Parent F 值 (Child 較小，需要上浮)
    PUSH EAX        ; Swap_Open_List_Elements 會使用 EAX, EBX, EDX，我們先保存
    PUSH EBX

    MOV ESI, ECX     ; ESI = Child (Current index in open list)
    MOV EDI, EBX     ; EDI = Parent (Parent index in open list)
    CALL Swap_Open_List_Elements 

    POP EBX
    POP EAX

    ; 5. 更新 Current = Parent，繼續循環
    MOV ECX, EBX     ; ECX = Parent_Index
    JMP Swim_Loop

Insert_Done:
    POP EDI  ; 恢復 EDI
    POP ESI
    POP EDX
    POP ECX
    POP EBX
    RET
Heap_Insert ENDP

; Heap_Extract_Min，取出 F 值最小的節點索引 (堆積的根)
; 輸出: 
;   EAX = F 值最小的 Node_Index
;   Open List Count 減少 1。
; -------------------------------------------------------
Heap_Extract_Min PROC NEAR
    PUSH EBX
    PUSH ECX
    PUSH EDX
    PUSH ESI
    PUSH EDI
    
    CMP OPEN_LIST_COUNT, 0
    JE Extract_Empty ; 如果堆積為空，則返回 0
    
    ; 1. 取出根節點 (F 值最小)
    MOV EAX, [OPEN_LIST_BUFFER + 0] ; EAX = 根節點的 Node Index (要回傳的值)
    
    ; 2. 將最後一個節點移到根部
    DEC OPEN_LIST_COUNT
    MOV ECX, OPEN_LIST_COUNT ; ECX = 新的堆積大小 (最後一個節點的位置)
    MOV ESI, [OPEN_LIST_BUFFER + ECX*2] ; ESI = 最後一個節點的 Node Index
    MOV [OPEN_LIST_BUFFER + 0], ESI    ; 將其移動到根部 (位置 0)
    
    ; 3. 下沉操作開始 (ESInk Down)
    MOV ECX, 0 ; ECX = Current Index (從根部開始)
ESInk_Loop:
    ; Left_Child_Index = 2 * Current + 1
    MOV EDX, ECX     ; EDX = Current
    SHL EDX, 1      ; EDX = Current * 2
    INC EDX         ; EDX = Left_Child_Index (Potential Smallest Child)

    CMP EDX, OPEN_LIST_COUNT
    JGE ESInk_Done  ; 如果 Left_Child >= N，則沒有子節點，完成

    ; 4. 找到較小的子節點 (Smallest_Child = EDX)
    MOV ESI, EDX     ; ESI = Left_Child_Index    
    ; 檢查 Right_Child_Index = Left_Child_Index + 1
    MOV EDI, EDX     ; EDI = Left_Child_Index
    INC EDI         ; EDI = Right_Child_Index

    CMP EDI, OPEN_LIST_COUNT
    JGE Compare_Only_Left ; 如果 Right_Child >= N (只有左子節點)，跳過右子節點的比較

    ; 比較 Left (ESI) 和 Right (EDI) 的 F 值
    PUSH ECX ; 保存 ECX
    PUSH EDX ; 保存 EDX
    
    MOV EAX, [OPEN_LIST_BUFFER + ESI*2] ; EAX = Left Node Index
    MOV EBX, [OPEN_LIST_BUFFER + EDI*2] ; EBX = Right Node Index
    CALL Compare_Nodes_F
    
    POP EDX
    POP ECX

    JC Left_Is_Smaller ; 如果 Left F < Right F (CF=1)，保持 ESI=Left
    MOV ESI, EDI         ; 否則，ESI = Right_Child_Index (Right F <= Left F)

Left_Is_Smaller:    
Compare_Only_Left:
    ; ESI 現在是兩個子節點中 F 值較小者的索引 (或唯一的左子節點)
    
    ; 5. 比較 Current (ECX) 和 Smallest_Child (ESI)
    MOV EDI, [OPEN_LIST_BUFFER + ECX*2] ; EDI = Current Node Index
    MOV EBX, [OPEN_LIST_BUFFER + ESI*2] ; EBX = Smallest Child Node Index
    
    PUSH ECX
    PUSH EDX
    
    MOV EAX, EDI     ; 設置 Compare_Nodes_F 的 EAX, EBX 輸入
    CALL Compare_Nodes_F 
    
    POP EDX
    POP ECX
    
    JNC ESInk_Done  ; JNC: 如果 Current F <= Child F (堆積屬性滿足)，則完成下沉
    
    ; 6. 交換 (Swap): 如果 Child F < Current F (Child 較小，需要下沉)
    PUSH EAX
    PUSH EBX
    
    MOV EDI, ESI     ; EDI = Smallest_Child_Index (在 Open List 中的位置)
    CALL Swap_Open_List_Elements ; Swap_Open_List_Elements(ECX, ESI)
    
    POP EBX
    POP EAX
    
    ; 7. 更新 Current = Smallest_Child，繼續循環
    MOV ECX, ESI     ; ECX = Smallest_Child_Index
    JMP ESInk_Loop

Extract_Empty:
    MOV EAX, 0xFFFF ; 用一個無效的索引表示 Open List 為空

ESInk_Done:
    POP EDI
    POP ESI
    POP EDX
    POP ECX
    POP EBX
    RET
Heap_Extract_Min ENDP

; Reset_A_Star，重置 Open List 和所有節點的 F/G/H/Flag 狀態
Reset_A_Star PROC NEAR
    PUSH EAX
    PUSH ECX
    PUSH ESI
    
    ; 1. 重置 Open List 計數器
    MOV OPEN_LIST_COUNT, 0

    ; 2. 遍歷 NODE_MAP，重置每個節點的狀態和值
    MOV ECX, TOTAL_NODES ; 循環次數
    MOV ESI, 0           ; ESI 作為偏移量 (0, 14, 28, ...)
    
Reset_Loop:
    ; 重置 G, H, F 值 (NODE_G_COST=4, NODE_H_COST=6, NODE_F_COST=8)
    MOV WORD PTR [NODE_MAP + ESI + NODE_G_COST], 0xFFFF ; 用一個大值表示未達
    MOV WORD PTR [NODE_MAP + ESI + NODE_H_COST], 0
    MOV WORD PTR [NODE_MAP + ESI + NODE_F_COST], 0xFFFF    
    ; 重置父節點 (NODE_PARENT=10)
    MOV WORD PTR [NODE_MAP + ESI + NODE_PARENT], 0xFFFF ; 用 FFFFh 表示無父節點
    ; 重置標記 (NODE_FLAG=12): 0 = 未處理
    MOV BYTE PTR [NODE_MAP + ESI + NODE_FLAG], 0
    
    ADD ESI, NODE_SIZE_BYTES ; 移動到下一個節點
    LOOP Reset_Loop
    
    ; 3. 重置路徑緩衝區的長度
    MOV PATH_LENGTH, 0
    MOV CURRENT_PATH_STEP, 0

    POP ESI
    POP ECX
    POP EAX
    RET
Reset_A_Star ENDP

; A_Star_Search，執行 A* 演算法
; 輸入: 
;   Start_Index (我們需要在呼叫前將 Start/End Index 存入暫存器或全域變數)
; 假設: ghostX/Y, TargetX/Y 已被設定
; 輸出: 
;   CF = 1: 找到路徑
;   CF = 0: 未找到路徑
;   如果找到，GHOST_PATH 陣列將被填充。
; -------------------------------------------------------
A_Star_Search PROC NEAR
    PUSH EAX
    PUSH EBX
    PUSH ECX
    PUSH EDX
    PUSH ESI
    PUSH EDI
    PUSH EBP ; 使用 EBP 儲存 Start/End Index

; 1. 初始化
    CALL Reset_A_Star
    
    ; 讀取起點與終點 (使用 DWORD 變數)
    MOV EAX, ghostX   
    MOV ECX, EAX      ; ECX = Start X
    MOV EAX, ghostY
    MOV EDX, EAX      ; EDX = Start Y
    
    CALL Get_Node_Offset 
    MOV EBP, EAX        ; EBP = Start Node Offset (16-bit)

    MOV EAX, targetX
    MOV ECX, EAX      ; ECX = Target X
    MOV EAX, targetY
    MOV EDX, EAX      ; EDX = Target Y
    
    CALL Get_Node_Offset 
    MOV EDI, EAX        ; EDI = Target Node Offset

    ; 2. 初始化起點
    MOV EAX, ghostX
    MOV ECX, EAX
    MOV EAX, ghostY
    MOV EDX, EAX
    MOV EAX, targetX
    MOV ESI, EAX
    MOV EAX, targetY
    MOV EDI, EAX       ; 這裡 EDI 暫時用於存座標
    
    CALL Calculate_Manhattan_H ; EAX = H
    
    ; 恢復 EDI 為 Target Offset
    PUSH EAX
    MOV EAX, targetX ; 需要重新計算 Target Offset 給 EDI 嗎？
    ; 為了效率，我們上面應該把 Target Offset 存到另一個地方，或者這裡重算
    ; 這裡簡單重算 Offset 給 EDI (因為上面 Calculate_Manhattan_H 覆蓋了 EDI)
    MOV EAX, targetY
    MOV EDX, EAX
    MOV EAX, targetX
    MOV ECX, EAX
    CALL Get_Node_Offset
    MOV EDI, EAX
    POP EAX ; 恢復 H 值
    
    MOV [NODE_MAP + EBP + NODE_G_COST], 0 ; G = 0
    MOV [NODE_MAP + EBP + NODE_H_COST], EAX ; H = H
    MOV [NODE_MAP + EBP + NODE_F_COST], EAX ; F = H (G=0)
    
    ; 將起點加入 Open List (需要計算 Start Index)
    MOV EAX, EBP
    MOV EBX, NODE_SIZE_BYTES
    XOR EDX, EDX ; 清除餘數
    DIV EBX           ; EAX = Start Node Index
    CALL Heap_Insert ; 插入起點
        
    MOV BYTE PTR [NODE_MAP + EBP + NODE_FLAG], 1  ; 將起點標記為 In Open List (Flag = 1)
    
Main_AStar_Loop:
    ; 3. 檢查 Open List 是否為空
    CMP OPEN_LIST_COUNT, 0
    JE No_Path_Found ; 如果為空，則找不到路徑

    ; 4. 取出 F 值最小的節點 (Current)
    CALL Heap_Extract_Min ; EAX = Current_Node_Index
    
    ; 計算 Current 節點的 Offset
    MOV EBX, NODE_SIZE_BYTES
    MUL EBX           ; EDX:EAX = Current_Node_Offset
    MOV ESI, EAX       ; ESI = Current_Node_Offset
    
    ; 5. 檢查是否到達終點
    CMP ESI, EDI       ; 比較 Current Offset 和 Target Offset
    JE Path_Found    ; 如果相等，找到路徑

    ; 6. 將 Current 節點移到 Closed List
    ; 標記為 In Closed List (Flag = 2)
    MOV BYTE PTR [NODE_MAP + ESI + NODE_FLAG], 2

; --- 鄰居檢查 (上下左右) ---
    ; 我們使用一個迴圈處理 4 個方向：(0,-1), (0,1), (-1,0), (1,0)
    ; 為了簡化彙編，我們展開寫 4 次，或者用堆疊存方向
    
    ; 這裡展示 "向上" (Up) 的邏輯，其他方向類似
    
    ; Current Coords
    MOV ECX, [NODE_MAP + ESI + NODE_X_POS] 
    MOV EDX, [NODE_MAP + ESI + NODE_Y_POS] 
    
    ; --- Check UP (Y - 1) ---
    PUSH ECX
    PUSH EDX
    DEC EDX ; Y - 1
    CALL Process_Neighbor
    POP EDX
    POP ECX
    
    ; --- Check DOWN (Y + 1) ---
    PUSH ECX
    PUSH EDX
    INC EDX ; Y + 1
    CALL Process_Neighbor
    POP EDX
    POP ECX
    
    ; --- Check LEFT (X - 1) ---
    PUSH ECX
    PUSH EDX
    DEC ECX ; X - 1
    CALL Process_Neighbor
    POP EDX
    POP ECX
    
    ; --- Check RIGHT (X + 1) ---
    PUSH ECX
    PUSH EDX
    INC ECX ; X + 1
    CALL Process_Neighbor
    POP EDX
    POP ECX

    JMP Main_AStar_Loop  
    
; --- 結束標籤 ---
Path_Found:
    ; 設定 CF 旗標為 1 (找到路徑)
    STC 
    ; 呼叫路徑重構
    CALL Reconstruct_Path
    JMP Search_Done

No_Path_Found:
    CLC ; 清除 CF 旗標 (未找到路徑)

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

; =======================================================
; Process_Neighbor (Helper): 處理單一鄰居的邏輯
; 輸入: ECX, EDX (Neighbor X, Y), ESI (Parent Offset)
Process_Neighbor PROC NEAR
    PUSH EAX
    PUSH EBX
    PUSH EBP ; 用於 Neighbor Offset
    
    ; 1. 邊界檢查 (1 到 N)
    CMP ECX, 1
    JL Skip_Proc
    CMP ECX, WORD PTR N
    JG Skip_Proc
    CMP EDX, 1
    JL Skip_Proc
    CMP EDX, WORD PTR N
    JG Skip_Proc
    
    ; 2. 牆壁檢查
    CALL Check_Wall ; 輸入 ECX, EDX
    JC Skip_Proc    ; CF=1 是牆壁
    
    ; 3. 獲取 Offset
    CALL Get_Node_Offset ; EAX = Neighbor Offset
    MOV EBP, EAX
    
    ; 4. 檢查 Closed List
    CMP BYTE PTR [NODE_MAP + EBP + NODE_FLAG], 2
    JE Skip_Proc
    
    ; 5. 計算 G 值
    MOV EAX, [NODE_MAP + ESI + NODE_G_COST]
    INC EAX ; New G
    
    ; 6. Open List 檢查
    CMP BYTE PTR [NODE_MAP + EBP + NODE_FLAG], 1
    JNE New_Node
    
    ; 比較 G 值
    CMP EAX, [NODE_MAP + EBP + NODE_G_COST]
    JGE Skip_Proc ; New G >= Old G, 不更新
    JMP Update_Node

New_Node:
    ; 計算 H
    PUSH ECX
    PUSH EDX
    PUSH ESI
    PUSH EDI ; 保存暫存器
    
    ; 需要 Target X, Y
    MOV EAX, targetX
    MOV ESI, EAX
    MOV EAX, targetY
    MOV EDI, EAX
    
    CALL Calculate_Manhattan_H
    MOV [NODE_MAP + EBP + NODE_H_COST], EAX
    
    POP EDI
    POP ESI
    POP EDX
    POP ECX
    
    ; 插入 Open List
    PUSH EAX ; 保存 H
    MOV EAX, EBP
    MOV EBX, NODE_SIZE_BYTES
    XOR EDX, EDX
    DIV EBX 
    CALL Heap_Insert
    POP EAX ; 恢復 H (EAX) - 其實上面被覆蓋了，這裡是 Update 邏輯
    
    MOV BYTE PTR [NODE_MAP + EBP + NODE_FLAG], 1

Update_Node:
    ; 更新 G, F, Parent
    MOV [NODE_MAP + EBP + NODE_G_COST], EAX ; New G
    ADD EAX, [NODE_MAP + EBP + NODE_H_COST] ; F = G + H
    MOV [NODE_MAP + EBP + NODE_F_COST], EAX
    
    ; Parent Index calculation
    MOV EAX, ESI ; Parent Offset
    MOV EBX, NODE_SIZE_BYTES
    XOR EDX, EDX
    DIV EBX    
    MOV [NODE_MAP + EBP + NODE_PARENT], EAX

Skip_Proc:
    POP EBP
    POP EBX
    POP EAX
    RET
Process_Neighbor ENDP


; =======================================================
; Reconstruct_Path: 從 Target 回溯到 Start，將 Node 索引存入 GHOST_PATH 緩衝區。
Reconstruct_Path PROC NEAR
    PUSH EAX
    PUSH EBX
    PUSH ECX
    PUSH EDI
    PUSH ESI
    PUSH EBP
    
    ; 假設 Target Node Index 在 EBP 中 (從 A_Star_Search 繼承)
    ; 如果您在 A_Star_Search 中使用了暫存器，這裡需要重新計算 Target Index
    
    ; 這裡，我們假設 Target Index 是從 A_Star_Search 的結束點獲取，假設 EBX 儲存了 Target Node Index
    ; 從 EDI (Target Offset) 開始
    MOV EAX, EDI ; EDI 是 Target Offset
    MOV EBX, NODE_SIZE_BYTES
    XOR EDX, EDX
    DIV EBX ; EAX = Target Index    
    MOV EBX, EAX  ; EBX = Target Index
    
    MOV ECX, PATH_BUFFER_SIZE ; ECX 作為路徑長度計數器，並作為 GHOST_PATH 的寫入索引 (從高處寫入)
    
Reconstruct_Loop:
    ; 1. 儲存當前節點索引
    DEC ECX ; 寫入索引遞減
    MOV [GHOST_PATH + ECX*2], EBX ; 儲存當前節點索引
    
    ; 2. 獲取當前節點的 Offset
    MOV EAX, EBX
    MOV EBX, NODE_SIZE_BYTES
    MUL EBX ; EDX:EAX = Current Node Offset
    MOV ESI, EAX ; ESI = Current Node Offset

    ; 3. 讀取父節點索引
    MOV EBX, [NODE_MAP + ESI + NODE_PARENT] ; EBX = Parent Index

    ; 4. 檢查是否到達起點 (起點的 Parent 是 FFFFh)
    CMP EBX, 0xFFFF 
    JNE Reconstruct_Loop ; 如果不是 FFFFh，繼續回溯
    
    ; 5. 路徑反轉 (Optional) 或 調整 PATH_LENGTH
    ; 目前邏輯是存入 GHOST_PATH[ECX] ... GHOST_PATH[99]
    ; Ghost_Follow_Path 需要正向讀取。
    ; 這裡我們可以簡單地將資料搬移到 GHOST_PATH[0]
    
    ; 計算實際長度
    MOV EAX, PATH_BUFFER_SIZE
    SUB EAX, ECX
    MOV PATH_LENGTH, EAX
    MOV CURRENT_PATH_STEP, 0
    
    ; 搬移迴圈: 將 GHOST_PATH[ECX]... 搬到 GHOST_PATH[0]...
    MOV ESI, ECX     ; Source Index
    MOV EDI, 0      ; Dest Index
    MOV ECX, PATH_LENGTH ; Loop Count
    
Move_Path_Loop:
    MOV EAX, [GHOST_PATH + ESI*2]
    MOV [GHOST_PATH + EDI*2], EAX
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
