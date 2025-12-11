INCLUDE Irvine32.inc

InputModule PROTO
PlayerPos PROTO
PlayerRotate PROTO
PlayerState PROTO
PlayerReset PROTO

EXTERN playerX:DWORD, playerY:DWORD, dir:DWORD, inputCode:DWORD, prevX:DWORD, prevY:DWORD

.data
xMsg  BYTE "X=",0
yMsg  BYTE "Y=",0
dirMsg BYTE "DIR=",0
pxMsg  BYTE "PrevX=",0
pyMsg  BYTE "PrevY=",0

.code
main PROC

main_loop:

    ; print "PrevX="
    mov edx, OFFSET pxMsg
    call WriteString
    mov eax, prevX
    call WriteDec
    call Crlf

    ; print "PrevY="
    mov edx, OFFSET pyMsg
    call WriteString
    mov eax, prevY
    call WriteDec
    call Crlf

    ; print "X="
    mov edx, OFFSET xMsg
    call WriteString
    mov eax, playerX
    call WriteDec
    call Crlf

    ; print "Y="
    mov edx, OFFSET yMsg
    call WriteString
    mov eax, playerY
    call WriteDec
    call Crlf

    ; print "DIR="
    mov edx, OFFSET dirMsg
    call WriteString
    mov eax, dir
    call WriteDec

    call Crlf
    call Crlf

    ; get input
    call InputModule
    call PlayerPos
    call PlayerRotate

    mov eax, 200
    call Delay

    jmp main_loop

main ENDP

END main
