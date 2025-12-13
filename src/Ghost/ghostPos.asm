TITLE ghostPos Module

INCLUDE Irvine32.inc
INCLUDE AIDataStruct.inc 

EXTERN ghostX:DWORD, ghostY:DWORD 
EXTERN targetX:DWORD, targetY:DWORD
EXTERN PATH_LENGTH:DWORD, CURRENT_PATH_STEP:DWORD
EXTERN GHOST_PATH:WORD 
EXTERN NODE_MAP:BYTE

Ghost_Main_Update PROTO

PUBLIC ghostPos

.CODE

ghostPos PROC USES EAX EBX ECX EDX ESI EDI

    ; 1. 執行 Ghost AI 邏輯 (尋路與狀態更新)
    CALL Ghost_Main_Update 
    
    ; 2. 根據路徑更新位置
    
    ; 檢查是否有路徑
    CMP PATH_LENGTH, 0
    JE ghostPos_Done 
    
    ; 檢查是否到達路徑終點
    MOV EAX, CURRENT_PATH_STEP
    CMP EAX, PATH_LENGTH
    JGE ghostPos_Done 
    
    ; --- 計算當前路徑索引 ---
    ; Index = GHOST_PATH[CURRENT_PATH_STEP]
    ; 因為 GHOST_PATH 是 WORD 陣列，所以索引要 * 2
    MOV ESI, CURRENT_PATH_STEP
    MOVZX EBX, WORD PTR [GHOST_PATH + ESI*2] ; EBX = Next Node Index
    
    ; --- 將 Node Index 轉換為座標 ---
    ; Offset = Index * NODE_SIZE_BYTES
    MOV EAX, EBX
    MOV ECX, NODE_SIZE_BYTES
    MUL ECX         ; EAX = Next Node Offset
    MOV EDI, EAX    ; EDI = Offset
    
    ; --- 更新座標 ---
    ; 讀取新的 X, Y 並寫入 ghostX, ghostY
    MOV EAX, DWORD PTR [NODE_MAP + EDI + NODE_X_POS]
    MOV ghostX, EAX
    
    MOV EAX, DWORD PTR [NODE_MAP + EDI + NODE_Y_POS]
    MOV ghostY, EAX

    ; --- 更新步數 ---
    INC CURRENT_PATH_STEP
    
ghostPos_Done:
    RET
ghostPos ENDP

END
