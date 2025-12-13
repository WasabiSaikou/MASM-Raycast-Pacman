TITLE ghostPos Module

INCLUDE Irvine32.inc

EXTERN ghostX:DWORD, ghostY:DWORD 
EXTERN targetX:DWORD, targetY:DWORD
EXTERN GHOST_SPEED_TICKS:WORD, GHOST_MOVE_COUNTER:WORD
EXTERN MazeMap:BYTE, N:DWORD

PUBLIC ghostPos

.DATA
; BFS Queue (stores positions as DWORD: high word = Y, low word = X)
BFS_QUEUE DWORD 1024 DUP (?)
QUEUE_START DWORD 0
QUEUE_END DWORD 0

; Visited array (1024 bytes for 32x32 grid)
VISITED BYTE 1024 DUP (?)

; Parent tracking (to reconstruct path)
PARENT DWORD 1024 DUP (?)

; Shared variables for TryDirection
g_targetIdx DWORD ?
g_currentPos DWORD ?

.CODE

; Convert (X, Y) to index
; Input: ECX = X, EDX = Y
; Output: EAX = index
PosToIndex PROC
    MOV EAX, EDX
    IMUL EAX, N
    ADD EAX, ECX
    RET
PosToIndex ENDP

; Check if position is valid and not a wall
; Input: ECX = X, EDX = Y
; Output: CF = 0 if valid, CF = 1 if invalid/wall
IsValid PROC USES EBX
    ; Check bounds
    CMP ECX, 0
    JL invalid
    CMP EDX, 0
    JL invalid
    MOV EBX, N
    CMP ECX, EBX
    JGE invalid
    CMP EDX, EBX
    JGE invalid
    
    ; Check if wall
    CALL PosToIndex
    MOV EBX, OFFSET MazeMap
    MOVZX EBX, BYTE PTR [EBX + EAX]
    CMP EBX, 1
    JE invalid
    
    CLC
    RET
    
invalid:
    STC
    RET
IsValid ENDP

; Try to visit a direction
; Input: ECX = newX, EDX = newY
; Uses: g_targetIdx, g_currentPos
; Sets CF if this is the target
TryDirection PROC USES EAX EBX ESI EDI
    
    ; Check if valid
    CALL IsValid
    JC try_done
    
    ; Get index
    CALL PosToIndex
    MOV ESI, EAX        ; ESI = newIdx
    
    ; Check if visited
    CMP BYTE PTR [VISITED + EAX], 1
    JE try_done
    
    ; Mark visited
    MOV BYTE PTR [VISITED + EAX], 1
    
    ; Set parent - get parent index from current position
    MOV EBX, g_currentPos
    MOV EAX, [BFS_QUEUE + EBX*4]
    MOVZX ECX, AX           ; X
    SHR EAX, 16
    MOV EDX, EAX            ; Y
    CALL PosToIndex
    
    MOV [PARENT + ESI*4], EAX
    
    ; Check if target
    MOV EAX, g_targetIdx
    CMP ESI, EAX
    JE found_it
    
    ; Enqueue - restore newX, newY from ESI
    MOV EAX, ESI
    XOR EDX, EDX
    MOV EBX, N
    DIV EBX
    ; EAX = Y, EDX = X
    SHL EAX, 16
    MOV AX, DX
    MOV EBX, QUEUE_END
    MOV [BFS_QUEUE + EBX*4], EAX
    INC QUEUE_END
    
try_done:
    CLC
    RET
    
found_it:
    STC
    RET
TryDirection ENDP

; BFS to find next step toward player
; Returns: CF = 0 if path found, CF = 1 if no path
FindPath PROC USES EBX ECX EDX ESI EDI
    LOCAL startIdx:DWORD
    
    ; Clear visited array
    MOV EDI, OFFSET VISITED
    MOV ECX, 1024
    XOR AL, AL
    REP STOSB
    
    ; Initialize queue
    MOV QUEUE_START, 0
    MOV QUEUE_END, 0
    
    ; Calculate start and target indices
    MOV ECX, ghostX
    MOV EDX, ghostY
    CALL PosToIndex
    MOV startIdx, EAX
    
    MOV ECX, targetX
    MOV EDX, targetY
    CALL PosToIndex
    MOV g_targetIdx, EAX
    
    ; Check if already at target
    MOV EAX, startIdx
    CMP EAX, g_targetIdx
    JE no_path_needed
    
    ; Enqueue start position
    MOV EAX, ghostY
    SHL EAX, 16
    MOV AX, WORD PTR ghostX
    MOV EBX, QUEUE_END
    MOV [BFS_QUEUE + EBX*4], EAX
    INC QUEUE_END
    
    ; Mark start as visited
    MOV EBX, startIdx
    MOV BYTE PTR [VISITED + EBX], 1
    
    ; Parent of start is itself
    MOV [PARENT + EBX*4], EBX
    
bfs_loop:
    ; Check if queue empty
    MOV EAX, QUEUE_START
    CMP EAX, QUEUE_END
    JGE path_not_found
    
    ; Dequeue
    MOV EBX, QUEUE_START
    MOV g_currentPos, EBX
    MOV EAX, [BFS_QUEUE + EBX*4]
    INC QUEUE_START
    
    ; Extract X and Y
    MOVZX ECX, AX           ; X
    SHR EAX, 16
    MOV EDX, EAX            ; Y
    
    ; Save current X, Y
    PUSH ECX
    PUSH EDX
    
    ; Try UP (Y-1)
    POP EDX
    POP ECX
    PUSH ECX
    PUSH EDX
    DEC EDX
    CALL TryDirection
    JC found_target
    
    ; Try RIGHT (X+1)
    POP EDX
    POP ECX
    PUSH ECX
    PUSH EDX
    INC ECX
    CALL TryDirection
    JC found_target
    
    ; Try DOWN (Y+1)
    POP EDX
    POP ECX
    PUSH ECX
    PUSH EDX
    INC EDX
    CALL TryDirection
    JC found_target
    
    ; Try LEFT (X-1)
    POP EDX
    POP ECX
    PUSH ECX
    PUSH EDX
    DEC ECX
    CALL TryDirection
    JC found_target
    
    ; Clean up stack
    POP EDX
    POP ECX
    
    JMP bfs_loop

found_target:
    ; Clean up stack
    POP EDX
    POP ECX
    
    ; Reconstruct path and move ghost one step
    MOV EAX, g_targetIdx
    
    ; Trace back to find first step
trace_back:
    MOV EBX, [PARENT + EAX*4]
    CMP EBX, startIdx
    JE found_first_step
    MOV EAX, EBX
    JMP trace_back
    
found_first_step:
    ; EAX contains the index of first step
    ; Convert back to X, Y
    XOR EDX, EDX
    MOV EBX, N
    DIV EBX
    ; EAX = Y, EDX = X
    MOV ghostY, EAX
    MOV ghostX, EDX
    
    CLC
    RET

no_path_needed:
path_not_found:
    STC
    RET
FindPath ENDP

ghostPos PROC USES EAX EBX ECX EDX

    ; Check speed counter
    MOV AX, GHOST_MOVE_COUNTER
    CMP AX, GHOST_SPEED_TICKS
    JL increment_counter
    
    ; Reset counter and move
    MOV GHOST_MOVE_COUNTER, 0
    
    ; Find path and move
    CALL FindPath
    JMP done_moving

increment_counter:
    INC GHOST_MOVE_COUNTER

done_moving:
    RET
ghostPos ENDP

END