@echo off
REM make
REM Assembles and links the 32-bit ASM program into .exe which can be used by WinDBG
REM Uses MicroSoft Macro Assembler version 6.11 and 32-bit Incremental Linker version 5.10.7303
REM Created by Huang 

REM delete related files
REM 	del helloworld.lst
REM 	del helloworld.obj
REM 	del helloworld.ilk
REM 	del helloworld.pdb
REM 	del helloworld.exe


REM /c          assemble without linking
REM /coff       generate object code to be linked into flat memory model 
REM /Zi         generate symbolic debugging information for WinDBG
REM /Fl		Generate a listing file

REM =========== 1. 組譯主程式 (123.asm) ============ 
ML /c /coff /Zi   Main.asm
if errorlevel 1 goto terminate

REM =========== 2. 組譯外部程序 (procedure.asm) ============
ML /c /coff /Zi InputModule.asm  
if errorlevel 1 goto terminate

ML /c /coff /Zi playerPos.asm  
if errorlevel 1 goto terminate

ML /c /coff /Zi playerReset.asm  
if errorlevel 1 goto terminate

ML /c /coff /Zi playerRotate.asm  
if errorlevel 1 goto terminate

ML /c /coff /Zi playerState.asm  
if errorlevel 1 goto terminate

ML /c /coff /Zi pathFinding.asm  
if errorlevel 1 goto terminate

ML /c /coff /Zi AIdataStructure.asm  
if errorlevel 1 goto terminate

ML /c /coff /Zi ghostBehavior.asm  
if errorlevel 1 goto terminate

ML /c /coff /Zi gameState.asm  
if errorlevel 1 goto terminate

ML /c /coff /Zi maze.asm  
if errorlevel 1 goto terminate

ML /c /coff /Zi collision.asm  
if errorlevel 1 goto terminate


REM /debug              generate symbolic debugging information
REM /subsystem:console  generate console application code
REM /entry:start        entry point from WinDBG to the program 
REM                           the entry point of the program must be _start

REM /out:%1.exe         output %1.exe code
REM %1.obj              input %1.obj
REM Kernel32.lib        library procedures to be invoked from the program
REM irvine32.lib
REM user32.lib

LINK /INCREMENTAL:no /debug /subsystem:console /entry:start /out:Main.exe Main.obj InputModule.obj playerPos.obj playerReset.obj playerRotate.obj playerState.obj pathFinding.obj AIdataStructure.obj ghostBehavior.obj gameState.obj maze.obj collision.obj Kernel32.lib irvine32.lib user32.lib
if errorlevel 1 goto terminate

REM Display all files related to this program:
DIR Main.* InputModule.* playerPos.* playerReset.* playerRotate.* playerState.* pathFinding.* AIdataStructure.* ghostBehavior.* gameState.* maze.* collision.* 

:terminate
pause
endlocal
