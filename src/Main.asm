TITLE Main
.386
.MODEL FLAT, C

main          EQU start@0

EXTERN collision:PROC              ; 迷宮與邏輯

.data
    
    gameState GameState <>         ; 遊戲狀態結構（玩家、鬼、迷宮、記分）

.code

mian PROC

    ; 初始化視窗與 OpenGL（呼叫 C 函式）
    call InitWindow
    call InitOpenGL

    ; 初始化迷宮、點點、玩家、鬼怪
    lea eax, gameState
    push eax
    call InitGameState

GameLoop:

    ; 處理鍵盤輸入
    push OFFSET gameState
    call ProcessInput            ; WASD、旋轉左右鍵等

    ; 更新玩家位置 / 旋轉
    push OFFSET gameState
    call UpdatePlayer

    ; 更新鬼怪 AI（A*）
    push OFFSET gameState
    call UpdateGhostAI

    ; 碰撞檢查（牆、鬼、點點）
    push OFFSET gameState
    call CheckCollision          ; 牆和鬼怪的判定

    ; 是否結束？
    mov eax, gameState.isGameOver
    cmp eax, 1
    je GameOver

    ; 渲染畫面（Raycasting）
    push OFFSET gameState
    call RenderFrame             ; Person1：raycaster

    ; 更新視窗（C 端刷新 buffer）
    call SwapBuffers

    jmp GameLoop                 ; 回到迴圈

GameOver:
    ; Render 結束畫面（你們想畫文字也可以）
    call RenderEndScreen

    ; 等待使用者按 Enter 或 R 重開
    call WaitForRestartKey

    ; 重新初始化
    lea eax, gameState
    push eax
    call InitGameState

    jmp GameLoop

main ENDP
END main
