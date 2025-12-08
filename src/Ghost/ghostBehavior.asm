TITLE GhostBehavior


; --- 2. 引入必要的定義 ---
INCLUDE Irvine32.inc
INCLUDE AIDataStruct.inc  ; 引入 NODE_X_POS, NODE_SIZE_BYTES 等常數

; --- 3. 外部變數與程序宣告 ---
EXTERN PATH_LENGTH:DWORD, CURRENT_PATH_STEP:DWORD
EXTERN ghostX:DWORD, ghostY:DWORD
EXTERN NODE_MAP:BYTE
EXTERN GHOST_PATH:WORD  ; 注意：這是 WORD 陣列
EXTERN GHOST_SPEED_TICKS:WORD, GHOST_MOVE_COUNTER:WORD
A_Star_Search PROTO

PUBLIC Ghost_Main_Update
PUBLIC Ghost_Follow_Path

.CODE

; =======================================================
; FUNCTION: Ghost_Main_Update
; 描述: 幽靈的每幀更新函數 (由 Main Loop 呼叫)
; =======================================================
Ghost_Main_Update PROC NEAR
    ; 使用 32 位元暫存器保存狀態
    PUSH EAX
    PUSH EBX
    PUSH ECX
    PUSH EDX
    PUSH ESI
    PUSH EDI
    
    ; 1. 路徑狀態檢查
    CMP PATH_LENGTH, 0
    JNE Path_Exists ; 如果路徑長度 > 0 (存在)，跳過搜尋

    ; 2. 搜尋新路徑
    CALL A_Star_Search ; 執行路徑搜尋
    
    ; 檢查 A* 搜尋結果 (CF 旗標)
    JNC Path_Search_Failed ; CF=0, 未找到路徑，維持原位
    
Path_Exists:
    ; 3. 執行路徑移動
    CALL Ghost_Follow_Path

Path_Search_Failed:
Update_Done:
    POP EDI
    POP ESI
    POP EDX
    POP ECX
    POP EBX
    POP EAX
    RET
Ghost_Main_Update ENDP

; =======================================================
; FUNCTION: Ghost_Follow_Path
; 描述: 沿著 GHOST_PATH 執行網格移動
; =======================================================
Ghost_Follow_Path PROC NEAR
    PUSH EAX
    PUSH EBX
    PUSH ECX
    PUSH EDX
    PUSH ESI
    PUSH EDI
        
    ; 1. 檢查是否到達當前目標點 (速度控制)
    MOV AX, GHOST_MOVE_COUNTER      ; 讀取 WORD
    CMP AX, GHOST_SPEED_TICKS       ; 比較 WORD
    JL Smooth_Movement_Update       ; 如果計數未滿，繼續等待

    ; 2. 計數已滿：準備移動到下一個單元格
    MOV GHOST_MOVE_COUNTER, 0       ; 重置計數器

    ; 檢查路徑是否還有下一步
    MOV EAX, CURRENT_PATH_STEP
    CMP EAX, PATH_LENGTH
    JGE Path_Walk_Done              ; 如果當前步數 >= 總長度，路徑走完

    ; 3. 獲取下一個目標節點的索引
    ; GHOST_PATH 是 WORD 陣列，索引需 * 2
    MOV ESI, CURRENT_PATH_STEP      ; ESI = Step Index (32-bit)
    MOVZX EAX, WORD PTR [GHOST_PATH + ESI*2] ; EAX = Next Node Index (讀取 16-bit 擴展為 32-bit)
    
    ; 4. 計算目標 Node Index 的 (X, Y) 座標
    ; Offset = Index * NODE_SIZE_BYTES
    PUSH ESI                        ; 保存 Step Index
    
    MOV EBX, NODE_SIZE_BYTES        ; 使用 32-bit 乘法
    MUL EBX                         ; EAX = EAX * EBX (Node Offset)
    MOV ESI, EAX                    ; ESI = Next Node Offset
    
    ; 讀取座標 (X, Y 都是 DWORD)
    MOV EAX, DWORD PTR [NODE_MAP + ESI + NODE_X_POS] ; EAX = Next X
    MOV EBX, DWORD PTR [NODE_MAP + ESI + NODE_Y_POS] ; EBX = Next Y
    
    POP ESI                         ; 恢復 Step Index

    ; 5. 更新幽靈的網格位置
    MOV ghostX, EAX
    MOV ghostY, EBX
    
    INC CURRENT_PATH_STEP           ; 移動到路徑的下一步
    JMP End_Update

Smooth_Movement_Update:
    ; 6. 更新移動計數器
    INC GHOST_MOVE_COUNTER
    JMP End_Update

Path_Walk_Done:
    ; 幽靈已到達路徑的終點，清空路徑以觸發重新搜尋
    MOV PATH_LENGTH, 0 
    
End_Update:
    POP EDI
    POP ESI
    POP EDX
    POP ECX
    POP EBX
    POP EAX
    RET
Ghost_Follow_Path ENDP

END
