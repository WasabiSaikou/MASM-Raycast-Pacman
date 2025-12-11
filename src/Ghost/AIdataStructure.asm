TITLE AIdataStructure
INCLUDE Irvine32.inc
INCLUDE AIDataStruct.inc ; 引入常數

; 公開變數給其他檔案使用
PUBLIC NODE_MAP, OPEN_LIST_BUFFER, OPEN_LIST_COUNT
PUBLIC GHOST_PATH, PATH_LENGTH, CURRENT_PATH_STEP
PUBLIC ghostX, ghostY, targetX, targetY
PUBLIC GHOST_STATE
PUBLIC GHOST_SPEED_TICKS, GHOST_MOVE_COUNTER

.DATA 
; --- 1. 網格節點地圖 ---
NODE_MAP DB TOTAL_NODES * NODE_SIZE_BYTES DUP (?)

; --- 2. Open List 緩衝區 (儲存 Node Index，16-bit) ---
OPEN_LIST_SIZE EQU TOTAL_NODES 
OPEN_LIST_BUFFER DW OPEN_LIST_SIZE DUP (?) 
OPEN_LIST_COUNT DW 0           

; --- 3. 路徑儲存緩衝區 (儲存 Node Index，16-bit) ---
GHOST_PATH DW PATH_BUFFER_SIZE DUP (?) 
PATH_LENGTH DWORD 0           
CURRENT_PATH_STEP DWORD 0     

; --- 4. 坐標 (32-bit) ---
ghostX DWORD 26           
ghostY DWORD 4           
targetX DWORD 15          
targetY DWORD 14          

; --- 5. 狀態與速度 ---
GHOST_STATE DB 0  
GHOST_SPEED_TICKS WORD 4  
GHOST_MOVE_COUNTER WORD 0 

END
