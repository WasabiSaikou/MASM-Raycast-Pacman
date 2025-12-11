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
 
ML /c /coff /Zi   p3_main.asm
ML /c /coff /Zi   p3_InputModule.asm
ML /c /coff /Zi   p3_PlayerState.asm
ML /c /coff /Zi   p3_PlayerPos.asm
ML /c /coff /Zi   p3_PlayerRotate.asm
ML /c /coff /Zi   p3_PlayerReset.asm
ML /c /coff /Zi   maze.asm
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

LINK /INCREMENTAL:no /debug /subsystem:console /entry:main /out:p3_main.exe p3_main.obj p3_InputModule.obj p3_PlayerState.obj p3_PlayerPos.obj p3_PlayerRotate.obj p3_PlayerReset.obj maze.obj Kernel32.lib irvine32.lib user32.lib
if errorlevel 1 goto terminate

REM Display all files related to this program:
DIR p3_main.* p3_InputModule.* p3_PlayerState.* p3_PlayerPos.* p3_PlayerRotate.* p3_PlayerReset.* maze.obj.*

:terminate
pause
endlocal
