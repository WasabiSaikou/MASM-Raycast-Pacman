TITLE AIdataStructure

INCLUDE Irvine32.inc

; A* 核心參數定義 (EQU - 內部結構尺寸)
; 這裡不再定義迷宮的實際尺寸 N，而是透過 EXTERN 引用
NODE_X_POS     EQU 0
NODE_Y_POS     EQU 2
NODE_G_COST    EQU 4
NODE_H_COST    EQU 6
NODE_F_COST    EQU 8
NODE_PARENT    EQU 10
NODE_FLAG      EQU 12
NODE_SIZE_BYTES EQU 14  ; 節點總大小

; 外部變數宣告 (EXTERN)
; 必須宣告從 maze.asm 獲取的迷宮尺寸變數，供 A* 內部計算使用
EXTERN N:DWORD 
EXTERN MazeMap:BYTE ; 迷宮地圖數據

; PUBLIC 宣告 (讓其他模組能存取 A* 數據)
PUBLIC NODE_MAP, OPEN_LIST_BUFFER, OPEN_LIST_COUNT
PUBLIC GHOST_PATH, PATH_LENGTH, CURRENT_PATH_STEP
PUBLIC ghostX, ghostY, targetX, targetY
PUBLIC GHOST_STATE
PUBLIC GHOST_SPEED_TICKS, GHOST_MOVE_COUNTER 

.DATA 

TOTAL_NODES EQU 32 * 32 

; --- 1. 網格節點地圖 (NODE_MAP) ---
NODE_MAP DB TOTAL_NODES * NODE_SIZE_BYTES DUP (?)

; --- 2. Open List 緩衝區 ---
OPEN_LIST_SIZE EQU TOTAL_NODES 
OPEN_LIST_BUFFER DW OPEN_LIST_SIZE DUP (?) 
OPEN_LIST_COUNT DW 0           

; --- 3. 路徑儲存緩衝區 ---
PATH_BUFFER_SIZE EQU 100 
GHOST_PATH DW PATH_BUFFER_SIZE DUP (?) 
PATH_LENGTH DW 0           
CURRENT_PATH_STEP DW 0     

; --- 4. 幽靈/目標位置 (已統一命名) ---
ghostX DWORD 27           
ghostY DWORD 5           
targetX DWORD 16          
targetY DWORD 15        

; --- 5. 幽靈速度與計數器，假設速度參數
GHOST_SPEED_TICKS DW 4 ; 幽靈移動一格需要 4 遊戲幀
GHOST_MOVE_COUNTER DW 0 ; 紀錄移動進度

GHOST_STATE DB 0  

END
