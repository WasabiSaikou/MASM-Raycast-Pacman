TITLE GhostBehavior

INCLUDE Irvine32.inc
INCLUDE AIDataStruct.inc 

EXTERN PATH_LENGTH:DWORD, CURRENT_PATH_STEP:DWORD
EXTERN ghostX:DWORD, ghostY:DWORD
EXTERN NODE_MAP:BYTE
EXTERN GHOST_PATH:WORD
EXTERN GHOST_SPEED_TICKS:WORD, GHOST_MOVE_COUNTER:WORD
A_Star_Search PROTO

PUBLIC Ghost_Main_Update
PUBLIC Ghost_Follow_Path

.CODE

Ghost_Main_Update PROC NEAR USES EAX EBX ECX EDX ESI EDI
    CMP PATH_LENGTH, 0
    JNE Path_Exists
    CALL A_Star_Search 
    JNC Path_Search_Failed 
Path_Exists:
    CALL Ghost_Follow_Path
Path_Search_Failed:
    RET
Ghost_Main_Update ENDP

Ghost_Follow_Path PROC NEAR USES EAX EBX ECX EDX ESI EDI
        
    MOV AX, GHOST_MOVE_COUNTER
    CMP AX, GHOST_SPEED_TICKS
    JL Smooth_Movement_Update
    MOV GHOST_MOVE_COUNTER, 0

    MOV EAX, CURRENT_PATH_STEP
    CMP EAX, PATH_LENGTH
    JGE Path_Walk_Done

    ; 1. 獲取 Index
    MOV ESI, CURRENT_PATH_STEP
    MOVZX EAX, WORD PTR [GHOST_PATH + ESI*2] 
    
    ; 先算出 Offset
    PUSH ESI
    MOV EBX, NODE_SIZE_BYTES
    MUL EBX
    MOV ESI, EAX 
    
    ; 直接讀取座標
    MOV EAX, DWORD PTR [NODE_MAP + ESI + NODE_X_POS]
    MOV EBX, DWORD PTR [NODE_MAP + ESI + NODE_Y_POS]
    
    POP ESI

    ; 更新位置
    MOV ghostX, EAX
    MOV ghostY, EBX
    
    INC CURRENT_PATH_STEP
    JMP End_Update

Smooth_Movement_Update:
    INC GHOST_MOVE_COUNTER
    JMP End_Update

Path_Walk_Done:
    MOV PATH_LENGTH, 0 
    
End_Update:
    RET
Ghost_Follow_Path ENDP

END
