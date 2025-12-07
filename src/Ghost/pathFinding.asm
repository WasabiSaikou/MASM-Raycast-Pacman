TITLE PathFinding

INCLUDE AIdataStructure.asm
INCLUDE Irvine32.inc

PUBLIC Absolute_Value, Calculate_Manhattan_H, Get_Node_Offset
PUBLIC Heap_Insert, Heap_Extract_Min, Reset_A_Star, A_Star_Search, Reconstruct_Path

.CODE

; Check_Wall 檢查 (x, y) 座標是否為牆壁
; 輸入: CX = x (1-based), DX = y (1-based)
; 輸出: CF=1 (Wall), CF=0 (Path)
Check_Wall PROC NEAR
    PUSH EAX
    PUSH EBX
    PUSH EDX
    PUSH ECX
    
    ; 轉換 1-based 到 0-based
    DEC CX
    DEC DX
    
    ; 計算索引 Index = y * N + x
    MOVZX EAX, DX   ; EAX = y
    MOV EBX, N      ; EBX = N (32)
    MUL EBX         ; EAX = y * N
    MOVZX EBX, CX   ; EBX = x
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

; Absolute_Value (Helper) 輸入: AX = 數字，輸出: AX = |數字|
Absolute_Value PROC NEAR
    CMP AX, 0
    JGE Abs_Done ; 如果 AX >= 0, 跳過
    NEG AX       ; 否則，取反變為正數
Abs_Done:
    RET
Absolute_Value ENDP

; Calculate_Manhattan_H
; 輸入: CX, DX (Current X, Y), SI, DI (Target X, Y)
; 輸出: AX = Manhattan Distance H Value
Calculate_Manhattan_H PROC NEAR
    PUSH BX       ; 保存 BX
    PUSH DX       ; 保存 DX
    PUSH SI       ; 保存 SI
    PUSH DI       ; 保存 DI
    
    ; 1. 計算 |x1 - x2|
    MOV AX, CX    ; AX = x1
    SUB AX, SI    ; AX = x1 - x2
    CALL Absolute_Value 
    MOV BX, AX    ; BX = |x1 - x2|

    ; 2. 計算 |y1 - y2|
    MOV AX, DX    ; AX = y1
    SUB AX, DI    ; AX = y1 - y2
    CALL Absolute_Value 
    
    ; 3. 計算總和並回傳
    ADD AX, BX    ; AX = |x1 - x2| + |y1 - y2| (H Value)
    POP DI        ; 恢復 DI
    POP SI        ; 恢復 SI
    POP DX        ; 恢復 DX
    POP BX        ; 恢復 BX
    RET
Calculate_Manhattan_H ENDP

; Get_Node_Offset (將 (x, y) 1-based 轉為 NODE_MAP 中的記憶體偏移量)
; 輸入: 
;   CX = x 座標 (0 到 MAZE_WIDTH-1)
;   DX = y 座標 (0 到 MAZE_HEIGHT-1)
; 輸出:
;   EAX = 節點在 NODE_MAP 中的線性偏移量 (Offset)
Get_Node_Offset PROC NEAR
    PUSH EBX      ; 保存 32-bit 暫存器
    PUSH EDX      ; MUL 會用到 EDX
    
    ; 轉換 1-based 到 0-based 用於內部計算
    DEC CX 
    DEC DX

    ; Index = (y * N) + x
    MOVZX EAX, DX  
    MOV EBX, N     
    MUL EBX        
    MOVZX EBX, CX  
    ADD EAX, EBX
    
    ; 2. 計算偏移量 Offset = Index * NODE_SIZE_BYTES
    MOV EBX, NODE_SIZE_BYTES ; EBX = 14
    MUL EBX        ; EAX = Offset (Index * 14)
    
    ; 恢復 1-based 座標 (因為呼叫者可能還需要用)
    INC CX
    INC DX

    POP EDX
    POP EBX
    RET
Get_Node_Offset ENDP

; Compare_Nodes_F (Helper)，比較兩個節點的 F 值
; 輸入: 
;   AX = Index_A (第一個節點的線性索引)
;   BX = Index_B (第二個節點的線性索引)
; 輸出:
;   ZF (Zero Flag) = 1 (兩者 F 值相等)
;   CF (Carry Flag) = 1 (A 的 F 值較小)
;   CF (Carry Flag) = 0 (B 的 F 值較小或相等)
Compare_Nodes_F PROC NEAR
    PUSH SI        ; 保存暫存器
    PUSH DI
    
    ; 計算 Index_A 的 F 值偏移量 (Offset_A = Index_A * NODE_SIZE_BYTES + NODE_F_COST)
    MOV SI, AX     
    MOV DI, NODE_SIZE_BYTES
    MUL DI         ; DX:AX = Index_A * 14
    ADD AX, NODE_F_COST ; AX = Offset_A

    ; 從 NODE_MAP 讀取 F_A (A的F值)
    MOV SI, OFFSET NODE_MAP ; SI 指向 NODE_MAP 的起始
    MOV DI, [SI + AX]     ; DI = F_A 

    ; 計算 Index_B 的 F 值偏移量
    MOV AX, BX
    PUSH DX ; MUL 使用 DX
    MOV SI, NODE_SIZE_BYTES
    MUL SI         ; DX:AX = Index_B * 14
    POP DX
    ADD AX, NODE_F_COST ; AX = Offset_B
    
    ; 從 NODE_MAP 讀取 F_B (B的F值)
    MOV SI, OFFSET NODE_MAP ; SI 指向 NODE_MAP 的起始
    MOV CX, [SI + AX]     ; CX = F_B 

    ; 比較 F_A 和 F_B
    ; CMP DI, CX 會影響 CF 旗標
    CMP DI, CX ; 比較 F_A (DI) 和 F_B (CX)
    
    ; 如果 DI < CX (F_A < F_B)，則 CF=1 (符合我們將 CF=1 定義為 A 較小的慣例)
    ; 如果 DI >= CX (F_A >= F_B)，則 CF=0
    POP DI
    POP SI
    RET
Compare_Nodes_F ENDP


; Swap_Open_List_Elements (Helper)，交換 Open List 中兩個位置的節點索引
; 輸入: 
;   SI = Index_in_Open_List_A (Open List 中的陣列位置 A)
;   DI = Index_in_Open_List_B (Open List 中的陣列位置 B)
Swap_Open_List_Elements PROC NEAR
    PUSH AX
    PUSH BX

    MOV AX, [OPEN_LIST_BUFFER + SI*2] ; 1. 讀取 A 的值到 AX。SI*2 因為每個元素是 DW (2 bytes)        
    MOV BX, [OPEN_LIST_BUFFER + DI*2] ; 2. 讀取 B 的值到 BX        
    MOV [OPEN_LIST_BUFFER + SI*2], BX ; 3. 交換: 將 B 的值寫入 A 的位置
    MOV [OPEN_LIST_BUFFER + DI*2], AX ; 4. 交換: 將 A 的值寫入 B 的位置

    POP BX
    POP AX
    RET
Swap_Open_List_Elements ENDP

; Heap_Insert， 將一個新的節點索引插入 Open List 堆積
; 輸入: 
;   AX = Node_Index (要插入的節點的線性索引)
; 輸出:
;   無。Open List Count 增加 1。
; -------------------------------------------------------
Heap_Insert PROC NEAR
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    
    ; 1. 將新節點放在堆積的最後一個位置 (Current = Open_List_Count)
    MOV CX, OPEN_LIST_COUNT ; CX = 當前堆積大小 N
    MOV [OPEN_LIST_BUFFER + CX*2], AX ; 存入新的 Node Index
    INC OPEN_LIST_COUNT     ; N++
    
    ; 2. 上浮操作開始 (Swim Up)
Swim_Loop:
    CMP CX, 0
    JE Insert_Done ; 如果 Current = 0 (根節點)，完成

    ; Parent_Index = (Current - 1) / 2
    MOV AX, CX     ; AX = Current
    DEC AX         ; AX = Current - 1
    SHR AX, 1      ; AX = Parent_Index
    MOV BX, AX     ; BX = Parent_Index
    
    ; 3. 比較 Current 節點 (CX) 和 Parent 節點 (BX)，讀取 OPEN_LIST_BUFFER 中的 Node 索引
    MOV SI, [OPEN_LIST_BUFFER + CX*2] ; SI = Child_Node_Index (A)
    MOV DI, [OPEN_LIST_BUFFER + BX*2] ; DI = Parent_Node_Index (B)
    
    ; 比較 F 值 (Compare_Nodes_F 比較 F(SI) 和 F(DI))
    PUSH CX        ; 保存 CX (Current Index)
    MOV AX, SI     ; 設置 Compare_Nodes_F 的 AX, BX 輸入
    MOV BX, DI
    CALL Compare_Nodes_F 
    POP CX         ; 恢復 CX
    
    JNC Insert_Done    ; JNC (Jump if No Carry): 如果 Parent F 值 <= Child F 值 (堆積屬性滿足)，則停止上浮
    
    ; 4. 交換 (Swap): 如果 Child F 值 < Parent F 值 (Child 較小，需要上浮)
    PUSH AX        ; Swap_Open_List_Elements 會使用 AX, BX, DX，我們先保存
    PUSH BX

    MOV SI, CX     ; SI = Child (Current index in open list)
    MOV DI, BX     ; DI = Parent (Parent index in open list)
    CALL Swap_Open_List_Elements 

    POP BX
    POP AX

    ; 5. 更新 Current = Parent，繼續循環
    MOV CX, BX     ; CX = Parent_Index
    JMP Swim_Loop

Insert_Done:
    POP DI  ; 恢復 DI
    POP SI
    POP DX
    POP CX
    POP BX
    RET
Heap_Insert ENDP

; Heap_Extract_Min，取出 F 值最小的節點索引 (堆積的根)
; 輸出: 
;   AX = F 值最小的 Node_Index
;   Open List Count 減少 1。
; -------------------------------------------------------
Heap_Extract_Min PROC NEAR
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    
    CMP OPEN_LIST_COUNT, 0
    JE Extract_Empty ; 如果堆積為空，則返回 0
    
    ; 1. 取出根節點 (F 值最小)
    MOV AX, [OPEN_LIST_BUFFER + 0] ; AX = 根節點的 Node Index (要回傳的值)
    
    ; 2. 將最後一個節點移到根部
    DEC OPEN_LIST_COUNT
    MOV CX, OPEN_LIST_COUNT ; CX = 新的堆積大小 (最後一個節點的位置)
    MOV SI, [OPEN_LIST_BUFFER + CX*2] ; SI = 最後一個節點的 Node Index
    MOV [OPEN_LIST_BUFFER + 0], SI    ; 將其移動到根部 (位置 0)
    
    ; 3. 下沉操作開始 (Sink Down)
    MOV CX, 0 ; CX = Current Index (從根部開始)
Sink_Loop:
    ; Left_Child_Index = 2 * Current + 1
    MOV DX, CX     ; DX = Current
    SHL DX, 1      ; DX = Current * 2
    INC DX         ; DX = Left_Child_Index (Potential Smallest Child)

    CMP DX, OPEN_LIST_COUNT
    JGE Sink_Done  ; 如果 Left_Child >= N，則沒有子節點，完成

    ; 4. 找到較小的子節點 (Smallest_Child = DX)
    MOV SI, DX     ; SI = Left_Child_Index    
    ; 檢查 Right_Child_Index = Left_Child_Index + 1
    MOV DI, DX     ; DI = Left_Child_Index
    INC DI         ; DI = Right_Child_Index

    CMP DI, OPEN_LIST_COUNT
    JGE Compare_Only_Left ; 如果 Right_Child >= N (只有左子節點)，跳過右子節點的比較

    ; 比較 Left (SI) 和 Right (DI) 的 F 值
    PUSH CX ; 保存 CX
    PUSH DX ; 保存 DX
    
    MOV AX, [OPEN_LIST_BUFFER + SI*2] ; AX = Left Node Index
    MOV BX, [OPEN_LIST_BUFFER + DI*2] ; BX = Right Node Index
    CALL Compare_Nodes_F
    
    POP DX
    POP CX

    JC Left_Is_Smaller ; 如果 Left F < Right F (CF=1)，保持 SI=Left
    MOV SI, DI         ; 否則，SI = Right_Child_Index (Right F <= Left F)

Left_Is_Smaller:    
Compare_Only_Left:
    ; SI 現在是兩個子節點中 F 值較小者的索引 (或唯一的左子節點)
    
    ; 5. 比較 Current (CX) 和 Smallest_Child (SI)
    MOV DI, [OPEN_LIST_BUFFER + CX*2] ; DI = Current Node Index
    MOV BX, [OPEN_LIST_BUFFER + SI*2] ; BX = Smallest Child Node Index
    
    PUSH CX
    PUSH DX
    
    MOV AX, DI     ; 設置 Compare_Nodes_F 的 AX, BX 輸入
    CALL Compare_Nodes_F 
    
    POP DX
    POP CX
    
    JNC Sink_Done  ; JNC: 如果 Current F <= Child F (堆積屬性滿足)，則完成下沉
    
    ; 6. 交換 (Swap): 如果 Child F < Current F (Child 較小，需要下沉)
    PUSH AX
    PUSH BX
    
    MOV DI, SI     ; DI = Smallest_Child_Index (在 Open List 中的位置)
    CALL Swap_Open_List_Elements ; Swap_Open_List_Elements(CX, SI)
    
    POP BX
    POP AX
    
    ; 7. 更新 Current = Smallest_Child，繼續循環
    MOV CX, SI     ; CX = Smallest_Child_Index
    JMP Sink_Loop

Extract_Empty:
    MOV AX, 0xFFFF ; 用一個無效的索引表示 Open List 為空

Sink_Done:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    RET
Heap_Extract_Min ENDP

; Reset_A_Star，重置 Open List 和所有節點的 F/G/H/Flag 狀態
Reset_A_Star PROC NEAR
    PUSH AX
    PUSH CX
    PUSH SI
    
    ; 1. 重置 Open List 計數器
    MOV OPEN_LIST_COUNT, 0

    ; 2. 遍歷 NODE_MAP，重置每個節點的狀態和值
    MOV CX, TOTAL_NODES ; 循環次數
    MOV SI, 0           ; SI 作為偏移量 (0, 14, 28, ...)
    
Reset_Loop:
    ; 重置 G, H, F 值 (NODE_G_COST=4, NODE_H_COST=6, NODE_F_COST=8)
    MOV WORD PTR [NODE_MAP + SI + NODE_G_COST], 0xFFFF ; 用一個大值表示未達
    MOV WORD PTR [NODE_MAP + SI + NODE_H_COST], 0
    MOV WORD PTR [NODE_MAP + SI + NODE_F_COST], 0xFFFF    
    ; 重置父節點 (NODE_PARENT=10)
    MOV WORD PTR [NODE_MAP + SI + NODE_PARENT], 0xFFFF ; 用 FFFFh 表示無父節點
    ; 重置標記 (NODE_FLAG=12): 0 = 未處理
    MOV BYTE PTR [NODE_MAP + SI + NODE_FLAG], 0
    
    ADD SI, NODE_SIZE_BYTES ; 移動到下一個節點
    LOOP Reset_Loop
    
    ; 3. 重置路徑緩衝區的長度
    MOV PATH_LENGTH, 0
    MOV CURRENT_PATH_STEP, 0

    POP SI
    POP CX
    POP AX
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
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    PUSH BP ; 使用 BP 儲存 Start/End Index

; 1. 初始化
    CALL Reset_A_Star
    
    ; 讀取起點與終點 (使用 DWORD 變數)
    MOV EAX, ghostX   
    MOV ECX, EAX      ; CX = Start X
    MOV EAX, ghostY
    MOV EDX, EAX      ; DX = Start Y
    
    CALL Get_Node_Offset 
    MOV BP, AX        ; BP = Start Node Offset (16-bit)

    MOV EAX, targetX
    MOV ECX, EAX      ; CX = Target X
    MOV EAX, targetY
    MOV EDX, EAX      ; DX = Target Y
    
    CALL Get_Node_Offset 
    MOV DI, AX        ; DI = Target Node Offset

    ; 2. 初始化起點
    MOV EAX, ghostX
    MOV CX, AX
    MOV EAX, ghostY
    MOV DX, AX
    MOV EAX, targetX
    MOV SI, AX
    MOV EAX, targetY
    MOV DI, AX       ; 這裡 DI 暫時用於存座標
    
    CALL Calculate_Manhattan_H ; AX = H
    
    ; 恢復 DI 為 Target Offset
    PUSH AX
    MOV EAX, targetX ; 需要重新計算 Target Offset 給 DI 嗎？
    ; 為了效率，我們上面應該把 Target Offset 存到另一個地方，或者這裡重算
    ; 這裡簡單重算 Offset 給 DI (因為上面 Calculate_Manhattan_H 覆蓋了 DI)
    MOV EAX, targetY
    MOV EDX, EAX
    MOV EAX, targetX
    MOV ECX, EAX
    CALL Get_Node_Offset
    MOV DI, AX
    POP AX ; 恢復 H 值
    
    MOV [NODE_MAP + BP + NODE_G_COST], 0 ; G = 0
    MOV [NODE_MAP + BP + NODE_H_COST], AX ; H = H
    MOV [NODE_MAP + BP + NODE_F_COST], AX ; F = H (G=0)
    
    ; 將起點加入 Open List (需要計算 Start Index)
    MOV AX, BP
    MOV BL, NODE_SIZE_BYTES
    DIV BL           ; AX = Start Node Index
    MOV AH, 0 ; 清除餘數
    CALL Heap_Insert ; 插入起點
        
    MOV BYTE PTR [NODE_MAP + BP + NODE_FLAG], 1  ; 將起點標記為 In Open List (Flag = 1)
    
Main_AStar_Loop:
    ; 3. 檢查 Open List 是否為空
    CMP OPEN_LIST_COUNT, 0
    JE No_Path_Found ; 如果為空，則找不到路徑

    ; 4. 取出 F 值最小的節點 (Current)
    CALL Heap_Extract_Min ; AX = Current_Node_Index
    
    ; 計算 Current 節點的 Offset
    MOV CL, NODE_SIZE_BYTES
    MUL CL           ; DX:AX = Current_Node_Offset
    MOV SI, AX       ; SI = Current_Node_Offset
    
    ; 5. 檢查是否到達終點
    CMP SI, DI       ; 比較 Current Offset 和 Target Offset
    JE Path_Found    ; 如果相等，找到路徑

    ; 6. 將 Current 節點移到 Closed List
    ; 標記為 In Closed List (Flag = 2)
    MOV BYTE PTR [NODE_MAP + SI + NODE_FLAG], 2

; --- 鄰居檢查 (上下左右) ---
    ; 我們使用一個迴圈處理 4 個方向：(0,-1), (0,1), (-1,0), (1,0)
    ; 為了簡化彙編，我們展開寫 4 次，或者用堆疊存方向
    
    ; 這裡展示 "向上" (Up) 的邏輯，其他方向類似
    
    ; Current Coords
    MOV CX, [NODE_MAP + SI + NODE_X_POS] 
    MOV DX, [NODE_MAP + SI + NODE_Y_POS] 
    
    ; --- Check UP (Y - 1) ---
    PUSH CX
    PUSH DX
    DEC DX ; Y - 1
    CALL Process_Neighbor
    POP DX
    POP CX
    
    ; --- Check DOWN (Y + 1) ---
    PUSH CX
    PUSH DX
    INC DX ; Y + 1
    CALL Process_Neighbor
    POP DX
    POP CX
    
    ; --- Check LEFT (X - 1) ---
    PUSH CX
    PUSH DX
    DEC CX ; X - 1
    CALL Process_Neighbor
    POP DX
    POP CX
    
    ; --- Check RIGHT (X + 1) ---
    PUSH CX
    PUSH DX
    INC CX ; X + 1
    CALL Process_Neighbor
    POP DX
    POP CX

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
    POP BP
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
A_Star_Search ENDP

; =======================================================
; Process_Neighbor (Helper): 處理單一鄰居的邏輯
; 輸入: CX, DX (Neighbor X, Y), SI (Parent Offset)
Process_Neighbor PROC NEAR
    PUSH AX
    PUSH BX
    PUSH BP ; 用於 Neighbor Offset
    
    ; 1. 邊界檢查 (1 到 N)
    CMP CX, 1
    JL Skip_Proc
    CMP CX, WORD PTR N
    JG Skip_Proc
    CMP DX, 1
    JL Skip_Proc
    CMP DX, WORD PTR N
    JG Skip_Proc
    
    ; 2. 牆壁檢查
    CALL Check_Wall ; 輸入 CX, DX
    JC Skip_Proc    ; CF=1 是牆壁
    
    ; 3. 獲取 Offset
    CALL Get_Node_Offset ; EAX = Neighbor Offset
    MOV BP, AX
    
    ; 4. 檢查 Closed List
    CMP BYTE PTR [NODE_MAP + BP + NODE_FLAG], 2
    JE Skip_Proc
    
    ; 5. 計算 G 值
    MOV AX, [NODE_MAP + SI + NODE_G_COST]
    INC AX ; New G
    
    ; 6. Open List 檢查
    CMP BYTE PTR [NODE_MAP + BP + NODE_FLAG], 1
    JNE New_Node
    
    ; 比較 G 值
    CMP AX, [NODE_MAP + BP + NODE_G_COST]
    JGE Skip_Proc ; New G >= Old G, 不更新
    JMP Update_Node

New_Node:
    ; 計算 H
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI ; 保存暫存器
    
    ; 需要 Target X, Y
    MOV EAX, targetX
    MOV SI, AX
    MOV EAX, targetY
    MOV DI, AX
    
    CALL Calculate_Manhattan_H
    MOV [NODE_MAP + BP + NODE_H_COST], AX
    
    POP DI
    POP SI
    POP DX
    POP CX
    
    ; 插入 Open List
    PUSH AX ; 保存 H
    MOV AX, BP
    MOV BL, NODE_SIZE_BYTES
    DIV BL
    MOV AH, 0
    CALL Heap_Insert
    POP AX ; 恢復 H (AX) - 其實上面被覆蓋了，這裡是 Update 邏輯
    
    MOV BYTE PTR [NODE_MAP + BP + NODE_FLAG], 1

Update_Node:
    ; 更新 G, F, Parent
    MOV [NODE_MAP + BP + NODE_G_COST], AX ; New G
    ADD AX, [NODE_MAP + BP + NODE_H_COST] ; F = G + H
    MOV [NODE_MAP + BP + NODE_F_COST], AX
    
    ; Parent Index calculation
    MOV AX, SI ; Parent Offset
    MOV BL, NODE_SIZE_BYTES
    DIV BL
    MOV AH, 0
    MOV [NODE_MAP + BP + NODE_PARENT], AX

Skip_Proc:
    POP BP
    POP BX
    POP AX
    RET
Process_Neighbor ENDP


; =======================================================
; Reconstruct_Path: 從 Target 回溯到 Start，將 Node 索引存入 GHOST_PATH 緩衝區。
Reconstruct_Path PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DI
    PUSH SI
    PUSH BP
    
    ; 假設 Target Node Index 在 BP 中 (從 A_Star_Search 繼承)
    ; 如果您在 A_Star_Search 中使用了暫存器，這裡需要重新計算 Target Index
    
    ; 這裡，我們假設 Target Index 是從 A_Star_Search 的結束點獲取，假設 BX 儲存了 Target Node Index
    ; 從 DI (Target Offset) 開始
    MOV AX, DI ; DI 是 Target Offset
    MOV CL, NODE_SIZE_BYTES
    DIV CL ; AX = Target Index
    MOV AH, 0
    MOV BX, AX  ; BX = Target Index
    
    MOV CX, PATH_BUFFER_SIZE ; CX 作為路徑長度計數器，並作為 GHOST_PATH 的寫入索引 (從高處寫入)
    
Reconstruct_Loop:
    ; 1. 儲存當前節點索引
    DEC CX ; 寫入索引遞減
    MOV [GHOST_PATH + CX*2], BX ; 儲存當前節點索引
    
    ; 2. 獲取當前節點的 Offset
    MOV AX, BX
    MOV AL, NODE_SIZE_BYTES
    MUL AL ; DX:AX = Current Node Offset
    MOV SI, AX ; SI = Current Node Offset

    ; 3. 讀取父節點索引
    MOV BX, [NODE_MAP + SI + NODE_PARENT] ; BX = Parent Index

    ; 4. 檢查是否到達起點 (起點的 Parent 是 FFFFh)
    CMP BX, 0xFFFF 
    JNE Reconstruct_Loop ; 如果不是 FFFFh，繼續回溯
    
    ; 5. 路徑反轉 (Optional) 或 調整 PATH_LENGTH
    ; 目前邏輯是存入 GHOST_PATH[CX] ... GHOST_PATH[99]
    ; Ghost_Follow_Path 需要正向讀取。
    ; 這裡我們可以簡單地將資料搬移到 GHOST_PATH[0]
    
    ; 計算實際長度
    MOV AX, PATH_BUFFER_SIZE
    SUB AX, CX
    MOV PATH_LENGTH, AX
    MOV CURRENT_PATH_STEP, 0
    
    ; 搬移迴圈: 將 GHOST_PATH[CX]... 搬到 GHOST_PATH[0]...
    MOV SI, CX     ; Source Index
    MOV DI, 0      ; Dest Index
    MOV CX, PATH_LENGTH ; Loop Count
    
Move_Path_Loop:
    MOV AX, [GHOST_PATH + SI*2]
    MOV [GHOST_PATH + DI*2], AX
    INC SI
    INC DI
    LOOP Move_Path_Loop
    
    POP BP
    POP SI
    POP DI
    POP CX
    POP BX
    POP AX
    RET
Reconstruct_Path ENDP

END
