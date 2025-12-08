TITLE ghostBehavior

EXTERN PATH_LENGTH:DWORD, CURRENT_PATH_STEP:DWORD
EXTERN ghostX:DWORD, ghostY:DWORD
EXTERN NODE_MAP:BYTE
EXTERN NODE_SIZE_BYTES:DWORD 
EXTERN GHOST_SPEED_TICKS:WORD, GHOST_MOVE_COUNTER:WORD ; 從 AIdataStructure 或專門檔案獲取
EXTERN A_Star_Search:NEAR

PUBLIC ghostBehavior
PUBLIC Ghost_Main_Update
PUBLIC Ghost_Follow_Path

.CODE
; 幽靈的每幀更新函數 (由 Main Loop 呼叫)
Ghost_Main_Update PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    
    ; 1. 路徑狀態檢查：是否需要搜尋新路徑？ 條件：a) 路徑長度為 0 (路徑未找到或已走完) b) 玩家位置發生了顯著變化 (可選，但優化需要)
    CMP PATH_LENGTH, 0
    JNE Path_Exists ; 如果路徑長度 > 0(存在)，跳過搜尋

    ; 2. 搜尋新路徑
    ; 這裡需要從 Person 2 獲取 TARGET_POS_X/Y (玩家位置) 假設：TARGET_POS_X 和 TARGET_POS_Y 已經被 Person 2 模組設置
    CALL A_Star_Search ; 執行路徑搜尋
    
    ; 檢查 A* 搜尋結果 (CF 旗標)
    JNC Path_Search_Failed ; CF=0, 未找到路徑，維持原位
    
Path_Exists:
    ; 3. 執行路徑移動
    CALL Ghost_Follow_Path

Path_Search_Failed:
Update_Done:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
Ghost_Main_Update ENDP

;沿著 GHOST_PATH 執行網格移動
Ghost_Follow_Path PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
        
    ; 1. 檢查是否到達當前目標點 (即移動計數是否已滿)
    CMP GHOST_MOVE_COUNTER, GHOST_SPEED_TICKS
    JL Smooth_Movement_Update ; 如果計數未滿，繼續平滑移動

    ; 2. 計數已滿：到達當前網格單元格，準備移動到下一個單元格
    MOV GHOST_MOVE_COUNTER, 0 ; 重置計數器

    ; 檢查路徑是否還有下一步
    CMP CURRENT_PATH_STEP, PATH_LENGTH
    JGE Path_Walk_Done ; 如果當前步數 >= 總長度，路徑走完

    ; 3. 獲取下一個目標節點的索引
    ; 假設 GHOST_PATH 儲存的是從起點到終點的序列。直接使用 CURRENT_PATH_STEP 作為索引。
    MOV SI, CURRENT_PATH_STEP ; SI = 路徑序列中的第 N 步
    MOV AX, [GHOST_PATH + SI*2] ; AX = 下一個目標 Node Index
    
    ; 4. 計算目標 Node Index 的 (X, Y) 座標
    PUSH SI ; 保存 SI
    ; 計算目標節點在 NODE_MAP 中的偏移量 Offset = Index * NODE_SIZE_BYTES
    MOVZX EAX, AX ; EAX = Next Node Index (32-bit)
    MOV BL, NODE_SIZE_BYTES
    MUL BL ; DX:AX = Next Node Offset
    MOV SI, EAX ; SI = Next Node Offset
    ; 讀取座標 (假設 ghostX/Y 是 DWORD)
    MOV EAX, [NODE_MAP + SI + NODE_X_POS] ; EAX = Next X
    MOV EBX, [NODE_MAP + SI + NODE_Y_POS] ; EBX = Next Y
    
    POP SI ; 恢復 SI

    ; 5. 更新幽靈的網格位置
    MOV ghostX, EAX
    MOV ghostY, EBX
    
    INC CURRENT_PATH_STEP ; 移動到路徑的下一步
    JMP End_Update ; 結束更新

Smooth_Movement_Update:
    ; 6. 平滑移動邏輯 (可選)
    ; 這部分需要在 Person 1 (Renderer) 中與 ghostX/Y 網格座標一起使用一個浮點偏移量
    ; 來在視覺上實現平滑移動。在彙編中實作浮點運算複雜，
    ; 這裡我們只更新 GHOST_MOVE_COUNTER，讓渲染器知道移動進度。
    
    INC GHOST_MOVE_COUNTER
    JMP End_Update
    ; 渲染器 (Person 1) 邏輯: 
    ; Render_X = ghostX + (Next_X - ghostX) * (GHOST_MOVE_COUNTER / GHOST_SPEED_TICKS)

Path_Walk_Done:
    ; 幽靈已到達路徑的終點
    MOV PATH_LENGTH, 0 ; 清空路徑，強制在下一幀重新搜尋
    
End_Update:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
Ghost_Follow_Path ENDP

END
