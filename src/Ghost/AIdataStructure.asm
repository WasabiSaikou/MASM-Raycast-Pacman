; =======================================================
; A* 核心參數定義 (使用 EQU 類似於 #define)
; =======================================================
MAZE_WIDTH  EQU 32      ; 迷宮寬度 (X 軸)
MAZE_HEIGHT EQU 32      ; 迷宮高度 (Y 軸)
TOTAL_NODES EQU MAZE_WIDTH * MAZE_HEIGHT ; 總節點數 (32 * 32 = 1024)

; 節點結構定義 (NODE_SIZE_BYTES)
; ----------------------------------------------------------------------------------------------------------------------------------
; 結構成員            | 大小 (Bytes) | 備註
; ----------------------------------------------------------------------------------------------------------------------------------
NODE_X_POS     EQU 0    ; 2 Bytes  | DW: 節點 X 座標 (Grid Column)
NODE_Y_POS     EQU 2    ; 2 Bytes  | DW: 節點 Y 座標 (Grid Row)
NODE_G_COST    EQU 4    ; 2 Bytes  | DW: G 值 (從起點到此節點的實際成本)
NODE_H_COST    EQU 6    ; 2 Bytes  | DW: H 值 (曼哈頓距離的估計成本)
NODE_F_COST    EQU 8    ; 2 Bytes  | DW: F 值 (G + H)
NODE_PARENT    EQU 10   ; 2 Bytes  | DW: 父節點的線性索引 (0 到 TOTAL_NODES-1)
NODE_FLAG      EQU 12   ; 1 Byte   | DB: 節點狀態標記 (0=未處理, 1=在Open, 2=在Closed)
NODE_SIZE_BYTES EQU 14  ; 總大小
; ----------------------------------------------------------------------------------------------------------------------------------


.DATA ; 資料段開始

; --- 1. 網格節點地圖 (NODE_MAP) ---
; 儲存所有節點的詳細資料。這是 A* 運算的基礎記憶體。
NODE_MAP DB TOTAL_NODES * NODE_SIZE_BYTES DUP (?)

; --- 2. Open List 緩衝區 (用於實作堆積/優先佇列) ---
; 儲存節點在 NODE_MAP 中的線性索引 (0 到 1023)。
OPEN_LIST_SIZE EQU TOTAL_NODES ; 最大容量
OPEN_LIST_BUFFER DW OPEN_LIST_SIZE DUP (?) 
OPEN_LIST_COUNT DW 0           ; 追蹤 Open List 中節點的數量 (堆積的大小)

; --- 3. Closed/Status Map (用於快速檢查節點狀態) ---
; 雖然 NODE_MAP 中有 NODE_FLAG，但我們可以使用一個獨立的、更小的陣列來進行快速標記
; GHOST_STATUS_MAP DB TOTAL_NODES DUP (0) ; 暫時不使用這個獨立陣列，使用 NODE_FLAG

; --- 4. 路徑儲存緩衝區 (Path Buffer) ---
; 儲存 A* 找到的路徑 (Node 索引序列)
PATH_BUFFER_SIZE EQU 100 
GHOST_PATH DW PATH_BUFFER_SIZE DUP (?) 
PATH_LENGTH DW 0           ; 實際路徑長度
CURRENT_PATH_STEP DW 0     ; 幽靈目前走到第幾步 (用於 movement logic)

; --- 5. 幽靈位置 (供 Logic 和 Render 使用) ---
GHOST_POS_X DW 0           ; 幽靈當前 X 座標
GHOST_POS_Y DW 0           ; 幽靈當前 Y 座標
TARGET_POS_X DW 0          ; 目標玩家 X 座標 (由 Person 2 提供)
TARGET_POS_Y DW 0          ; 目標玩家 Y 座標 (由 Person 2 提供)
