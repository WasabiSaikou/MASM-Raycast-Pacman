TITLE ghost_test_main

INCLUDE Irvine32.inc
INCLUDE AIDataStruct.inc   ; 引入常數

; 原本是 A_Star_Search 和 Ghost_Follow_Path
; 現在改成只呼叫 ghostPos，因為它封裝了所有邏輯
ghostPos PROTO
Init_Node_Map PROTO

; 這些變數仍然需要，因為我們要印出數值來驗證
EXTERN ghostX:DWORD, ghostY:DWORD       
EXTERN targetX:DWORD, targetY:DWORD     
EXTERN PATH_LENGTH:DWORD                
EXTERN CURRENT_PATH_STEP:DWORD          
EXTERN GHOST_SPEED_TICKS:WORD           
EXTERN GHOST_MOVE_COUNTER:WORD          

; --- 4. 數據段 ---
.data
startMsg      BYTE "--- GhostPos Module Test ---", 0dh, 0ah, 0
targetMsg     BYTE "TARGET: (", 0
ghostMsg      BYTE "GHOST POS: (", 0
pathMsg       BYTE "PATH LEN: ", 0
stepMsg       BYTE "PATH STEP: ", 0
tickMsg       BYTE "MOVE TICK: ", 0
comma         BYTE ", ", 0
parenEnd      BYTE ")", 0dh, 0ah, 0
separator     BYTE "----------------------------------", 0dh, 0ah, 0
successMsg    BYTE "Ghost Reached Target!", 0dh, 0ah, 0

.code
main PROC

    CALL Clrscr
    CALL Init_Node_Map

    MOV ghostX, 1    ; 起點 X
    MOV ghostY, 1    ; 起點 Y
    
    MOV targetX, 7   ; 終點 X
    MOV targetY, 1   ; 終點 Y
    
    MOV EDX, OFFSET startMsg
    CALL WriteString

main_loop:

    ; 直接呼叫 ghostPos
    ; ghostPos 內部會自動判斷是否需要尋路、是否需要移動
    CALL ghostPos

    ; 下面全是輸出顯示邏輯 (驗證 ghostPos 有沒有在工作)

    ; 1. 輸出目標坐標
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
    
    ; 2. 輸出幽靈坐標 (ghostX, ghostY)
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
    
    ; 3. 輸出路徑狀態
    MOV EDX, OFFSET pathMsg
    CALL WriteString
    MOV EAX, PATH_LENGTH
    CALL WriteDec
    CALL Crlf

    ; 4. 輸出移動計數
    MOV EDX, OFFSET tickMsg
    CALL WriteString
    MOVZX EAX, GHOST_MOVE_COUNTER 
    CALL WriteDec
    CALL Crlf
    
    MOV EDX, OFFSET separator
    CALL WriteString

    ; 檢查測試結束條件：幽靈座標 == 目標座標
    MOV EAX, ghostX
    CMP EAX, targetX
    JNE Continue_Loop
    
    MOV EAX, ghostY
    CMP EAX, targetY
    JNE Continue_Loop
    
    ; 到達目標
    JMP Test_Success

Continue_Loop:
    ; 延遲 300ms 讓我們看清楚變化，並清除螢幕
    MOV EAX, 300
    CALL Delay
    CALL Clrscr
    JMP main_loop

Test_Success:
    MOV EDX, OFFSET successMsg
    CALL WriteString
    MOV EAX, 5000 
    CALL Delay
    INVOKE ExitProcess, 0 

main ENDP
END main
