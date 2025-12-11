@echo off
REM make
REM Assembles and links the 32-bit ASM program into .exe which can be used by WinDBG
REM Uses MicroSoft Macro Assembler version 6.11 and 32-bit Incremental Linker version 5.10.7303
REM Created by Huang 

REM /c          assemble without linking
REM /coff       generate object code to be linked into flat memory model 
REM /Zi         generate symbolic debugging information for WinDBG
REM /Fl		    Generate a listing file

ML /c /coff /Zi /I. src\Main.asm
if errorlevel 1 goto terminate

ML /c /coff /Zi /I. src\Player\InputModule.asm  
if errorlevel 1 goto terminate

ML /c /coff /Zi /I. src\Player\playerPos.asm  
if errorlevel 1 goto terminate

ML /c /coff /Zi /I. src\Player\playerReset.asm  
if errorlevel 1 goto terminate

ML /c /coff /Zi /I. src\Player\playerRotate.asm  
if errorlevel 1 goto terminate

ML /c /coff /Zi /I. src\Player\playerState.asm  
if errorlevel 1 goto terminate

ML /c /coff /Zi /I. src\Ghost\pathFinding.asm  
if errorlevel 1 goto terminate

ML /c /coff /Zi /I. src\Ghost\AIdataStructure.asm  
if errorlevel 1 goto terminate

ML /c /coff /Zi /I. src\Ghost\ghostBehavior.asm  
if errorlevel 1 goto terminate

ML /c /coff /Zi /I. src\Ghost\ghostPos.asm  
if errorlevel 1 goto terminate

ML /c /coff /Zi /I. src\Logic\gameState.asm  
if errorlevel 1 goto terminate

ML /c /coff /Zi /I. src\Logic\maze.asm  
if errorlevel 1 goto terminate

ML /c /coff /Zi /I. src\Logic\collision.asm  
if errorlevel 1 goto terminate

ML /c /coff /Zi /I. src\Interface\render.asm
if errorlevel 1 goto terminate

gcc -c -g -m32 src\Interface\renderGL.c -o renderGL.obj
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

LINK /INCREMENTAL:no /debug /subsystem:console /entry:start /out:Main.exe Main.obj InputModule.obj playerPos.obj playerReset.obj playerRotate.obj playerState.obj pathFinding.obj AIdataStructure.obj ghostBehavior.obj ghostPos.obj gameState.obj maze.obj collision.obj render.obj renderGL.obj Kernel32.lib irvine32.lib user32.lib OpenGL32.lib Gdi32.lib

if errorlevel 1 goto terminate

REM Display all files related to this program:
DIR Main.* InputModule.* playerPos.* playerReset.* playerRotate.* playerState.* pathFinding.* AIdataStructure.* ghostBehavior.* ghostPos.* gameState.* maze.* collision.* render.* rendeGL.*

:terminate
pause
endlocal