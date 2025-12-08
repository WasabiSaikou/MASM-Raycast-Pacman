; =======================================================
; AIDataStruct.inc - 常數與結構定義
; =======================================================

; 迷宮與路徑參數
MAZE_WIDTH       EQU 32
MAZE_HEIGHT      EQU 32
TOTAL_NODES      EQU 32 * 32
PATH_BUFFER_SIZE EQU 100  ; <--- 必須定義在這裡，pathFinding 才能看到

; 節點結構偏移量 (配合 32-bit 存取調整)
NODE_X_POS      EQU 0    ; 4 Bytes (DWORD)
NODE_Y_POS      EQU 4    ; 4 Bytes (DWORD)
NODE_G_COST     EQU 8    ; 2 Bytes (WORD)
NODE_H_COST     EQU 10   ; 2 Bytes (WORD)
NODE_F_COST     EQU 12   ; 2 Bytes (WORD)
NODE_PARENT     EQU 14   ; 2 Bytes (WORD)
NODE_FLAG       EQU 16   ; 1 Byte  (BYTE)

; 結構總大小 (對齊後)
NODE_SIZE_BYTES EQU 18