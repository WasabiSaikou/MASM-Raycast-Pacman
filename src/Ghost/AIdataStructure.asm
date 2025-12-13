TITLE AIdataStructure
INCLUDE Irvine32.inc

PUBLIC ghostX, ghostY, targetX, targetY
PUBLIC GHOST_SPEED_TICKS, GHOST_MOVE_COUNTER

.DATA 
; Ghost position and target
ghostX DWORD 26           
ghostY DWORD 4           
targetX DWORD 15          
targetY DWORD 14          

; Ghost movement speed control
GHOST_SPEED_TICKS WORD 2
GHOST_MOVE_COUNTER WORD 0

END