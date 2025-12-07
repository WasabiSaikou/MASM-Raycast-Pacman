
INCLUDE AIdataStructure.asm

.CODE

Get_Ghost_Position PROC NEAR
     MOV AX, GHOST_POS_X
     MOV BX, GHOST_POS_Y
     RET
Get_Ghost_Position ENDP

END
