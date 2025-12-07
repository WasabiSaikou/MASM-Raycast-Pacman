INCLUDE Irvine32.inc

InputModule PROTO
PlayerPos PROTO
PlayerRotate PROTO
PlayerState PROTO
PlayerReset PROTO

EXTERN playerX:DWORD, playerY:DWORD, dir:DWORD, inputCode:DWORD, prevX:DWORD, prevY:DWORD
EXTERN moveState:DWORD

.data
xMsg  BYTE "X=",0
yMsg  BYTE "Y=",0
dirMsg BYTE "DIR=",0
pxMsg  BYTE "PrevX=",0
pyMsg  BYTE "PrevY=",0

.code
main PROC

main_loop:

    ; 印 "PrevX="
    mov edx, OFFSET pxMsg
    call WriteString
    mov eax, prevX
    call WriteDec
    call Crlf

    ; 印 "PrevY="
    mov edx, OFFSET pyMsg
    call WriteString
    mov eax, prevY
    call WriteDec
    call Crlf

    ; 印 "X="
    mov edx, OFFSET xMsg
    call WriteString
    mov eax, playerX
    call WriteDec
    call Crlf

    ; 印 "Y="
    mov edx, OFFSET yMsg
    call WriteString
    mov eax, playerY
    call WriteDec
    call Crlf

    ; 印 "DIR="
    mov edx, OFFSET dirMsg
    call WriteString
    mov eax, dir
    call WriteDec

    call Crlf
    call Crlf

    ; 取得輸入
    call InputModule
    call PlayerPos
    call PlayerRotate
    call PlayerReset

    mov eax, 200
    call Delay

    jmp main_loop

main ENDP

END main
