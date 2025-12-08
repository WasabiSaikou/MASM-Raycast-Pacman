TITLE ghost_test_main

; --- 1. 引入 Irvine 庫和常數定義 ---
INCLUDE Irvine32.inc
INCLUDE AIDataStruct.inc   ; 引入所有 NODE_X_POS, NODE_SIZE_BYTES 等常數 (EQU)

; --- 2. 外部程序宣告 (PROTO) ---
; 這些程序在 pathFinding.asm 和 ghostBehavior.asm 中定義
A_Star_Search PROTO
Ghost_Follow_Path PROTO

; --- 3. 外部變數宣告 (EXTERN) ---
; 這些變數在 AIdataStructure.asm 中定義
EXTERN ghostX:DWORD, ghostY:DWORD       ; 幽靈當前網格坐標
EXTERN targetX:DWORD, targetY:DWORD     ; 幽靈目標網格坐標
EXTERN PATH_LENGTH:DWORD                ; 找到的路徑總長度
EXTERN CURRENT_PATH_STEP:DWORD          ; 當前走到的路徑步驟
EXTERN OPEN_LIST_COUNT:WORD             ; A* 開啟列表計數
EXTERN GHOST_SPEED_TICKS:WORD           ; 幽靈速度常數
EXTERN GHOST_MOVE_COUNTER:WORD          ; 幽靈移動計數器

; --- 4. 數據段 (用於輸出訊息) ---
.data
startMsg      BYTE "--- A* Ghost Path Test ---", 0dh, 0ah, 0
targetMsg     BYTE "TARGET: (", 0
ghostMsg      BYTE "GHOST POS: (", 0
pathMsg       BYTE "PATH LEN: ", 0
stepMsg       BYTE "PATH STEP: ", 0
tickMsg       BYTE "MOVE TICK: ", 0
comma         BYTE ", ", 0
parenEnd      BYTE ")", 0dh, 0ah, 0
separator     BYTE "----------------------------------", 0dh, 0ah, 0
failMsg       BYTE "A* Search Failed or No Path!", 0dh, 0ah, 0

.code
main PROC

    CALL Clrscr
    
    ; 設置起點和終點 (假設迷宮是 32x32)
    MOV targetX, 30
    MOV targetY, 30
    MOV ghostX, 1
    MOV ghostY, 1
    
    MOV EDX, OFFSET startMsg
    CALL WriteString

main_loop:

    ; 1. 執行 A* 搜尋 (如果路徑走完或還未找到)
    CMP PATH_LENGTH, 0
    JNE Path_Exists_Skip_Search

    ; 輸出目標坐標
    MOV EDX, OFFSET targetMsg
    CALL WriteString
    MOV EAX, targetX
    CALL WriteDec
    MOV EDX, OFFSET comma
    CALL WriteString
    MOV EAX, targetY
    CALL WriteDec
    MOV EDX, OFFSET parenEnd
    CALL WriteString
    
    ; 呼叫 A* 演算法
    CALL A_Star_Search

    JNC Search_Failure ; 如果 CF=0，表示搜尋失敗 (找不到路徑)
    JMP Print_Status
    
Path_Exists_Skip_Search:

    ; 2. 模擬幽靈沿路徑移動
    CALL Ghost_Follow_Path

Print_Status:
    ; --- 輸出結果 ---
    
    ; A. 輸出幽靈坐標 (ghostX, ghostY)
    MOV EDX, OFFSET ghostMsg
    CALL WriteString
    MOV EAX, ghostX
    CALL WriteDec
    MOV EDX, OFFSET comma
    CALL WriteString
    MOV EAX, ghostY
    CALL WriteDec
    MOV EDX, OFFSET parenEnd
    CALL WriteString
    
    ; B. 輸出路徑長度 (PATH_LENGTH)
    MOV EDX, OFFSET pathMsg
    CALL WriteString
    MOV EAX, PATH_LENGTH
    CALL WriteDec
    CALL Crlf

    ; C. 輸出當前步數 (CURRENT_PATH_STEP)
    MOV EDX, OFFSET stepMsg
    CALL WriteString
    MOV EAX, CURRENT_PATH_STEP
    CALL WriteDec
    CALL Crlf

    ; D. 輸出移動計數 (GHOST_MOVE_COUNTER)
    MOV EDX, OFFSET tickMsg
    CALL WriteString
    MOVZX EAX, GHOST_MOVE_COUNTER ; WORD to DWORD
    CALL WriteDec
    CALL Crlf
    
    MOV EDX, OFFSET separator
    CALL WriteString

    ; 檢查是否到達終點 (Path length = 0 表示到達)
    CMP PATH_LENGTH, 0
    JE Test_End_Delay
    
    ; 延遲並繼續迴圈
    MOV EAX, 300
    CALL Delay
    CALL Clrscr
    JMP main_loop

Search_Failure:
    MOV EDX, OFFSET failMsg
    CALL WriteString
    JMP Test_End_Delay

Test_End_Delay:
    MOV EDX, OFFSET separator
    CALL WriteString
    MOV EAX, 5000 ; 延遲 5 秒
    CALL Delay
    
    INVOKE ExitProcess, 0 

main ENDP
END main