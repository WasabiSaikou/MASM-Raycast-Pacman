MAZE_WIDTH  EQU 32      ; 迷宮寬度 (X 軸)
MAZE_HEIGHT EQU 32      ; 迷宮高度 (Y 軸)
TOTAL_NODES EQU MAZE_WIDTH * MAZE_HEIGHT ; 總節點數 (32 * 32 = 1024)

NODE_X_POS     EQU 0    ; 2 Bytes  | DW: 節點 X 座標 (Grid Column)
NODE_Y_POS     EQU 2    ; 2 Bytes  | DW: 節點 Y 座標 (Grid Row)
NODE_G_COST    EQU 4    ; 2 Bytes  | DW: G 值 (從起點到此節點的實際成本)
NODE_H_COST    EQU 6    ; 2 Bytes  | DW: H 值 (曼哈頓距離的估計成本)
NODE_F_COST    EQU 8    ; 2 Bytes  | DW: F 值 (G + H)
NODE_PARENT    EQU 10   ; 2 Bytes  | DW: 父節點的線性索引 (0 到 TOTAL_NODES-1)
NODE_FLAG      EQU 12   ; 1 Byte   | DB: 節點狀態標記 (0=未處理, 1=在Open, 2=在Closed)
NODE_SIZE_BYTES EQU 14  ; 總大小

.DATA ; 資料段開始

NODE_MAP DB TOTAL_NODES * NODE_SIZE_BYTES DUP (?)

OPEN_LIST_SIZE EQU TOTAL_NODES ; 最大容量
OPEN_LIST_BUFFER DW OPEN_LIST_SIZE DUP (?) 
OPEN_LIST_COUNT DW 0           ; 追蹤 Open List 中節點的數量 (堆積的大小)

PATH_BUFFER_SIZE EQU 100 
GHOST_PATH DW PATH_BUFFER_SIZE DUP (?) 
PATH_LENGTH DW 0           ; 實際路徑長度
CURRENT_PATH_STEP DW 0     ; 幽靈目前走到第幾步 (用於 movement logic)

GHOST_POS_X DW 0           ; 幽靈當前 X 座標
GHOST_POS_Y DW 0           ; 幽靈當前 Y 座標
TARGET_POS_X DW 0          ; 目標玩家 X 座標 (由 Person 2 提供)
TARGET_POS_Y DW 0          ; 目標玩家 Y 座標 (由 Person 2 提供)

