#include <windows.h>
#include <gl/gl.h>

static HWND hWnd = NULL;
static HDC hDC = NULL;
static HGLRC hRC = NULL;
static int screenWidth = 800;
static int screenHeight = 600;
static GLuint fontBase = 0;

typedef struct {
    float r, g, b;
} Color;

static Color wallColors[] = {
    {0.0f, 0.0f, 0.0f},
    {0.2f, 0.2f, 0.8f},
    {0.1f, 0.5f, 0.1f},
    {0.8f, 0.6f, 0.0f},
};

static int StrLen(const char* str) {
    int len = 0;
    while (str[len] != '\0') len++;
    return len;
}

static void StrCopy(char* dest, const char* src) {
    int i = 0;
    while (src[i] != '\0') {
        dest[i] = src[i];
        i++;
    }
    dest[i] = '\0';
}

static void StrCat(char* dest, const char* src) {
    int destLen = StrLen(dest);
    int i = 0;
    while (src[i] != '\0') {
        dest[destLen + i] = src[i];
        i++;
    }
    dest[destLen + i] = '\0';
}

static void IntToStr(int num, char* str) {
    int i = 0;
    int isNegative = 0;
    
    if (num == 0) {
        str[0] = '0';
        str[1] = '\0';
        return;
    }
    
    if (num < 0) {
        isNegative = 1;
        num = -num;
    }
    
    while (num > 0) {
        str[i++] = (num % 10) + '0';
        num /= 10;
    }
    
    if (isNegative) {
        str[i++] = '-';
    }
    
    str[i] = '\0';
    
    int start = 0;
    int end = i - 1;
    while (start < end) {
        char temp = str[start];
        str[start] = str[end];
        str[end] = temp;
        start++;
        end--;
    }
}

static void BuildFont(HDC hDC) {
    HFONT font;
    HFONT oldFont;
    
    fontBase = glGenLists(256);
    
    font = CreateFont(
        -24,                        
        0,                          
        0,                          
        0,                          
        FW_BOLD,                    
        FALSE,                      
        FALSE,                      
        FALSE,                      
        ANSI_CHARSET,               
        OUT_TT_PRECIS,              
        CLIP_DEFAULT_PRECIS,        
        ANTIALIASED_QUALITY,        
        FF_DONTCARE | DEFAULT_PITCH,
        "Arial");                   
    
    oldFont = (HFONT)SelectObject(hDC, font);
    wglUseFontBitmaps(hDC, 0, 256, fontBase);
    SelectObject(hDC, oldFont);
    DeleteObject(font);
}

static void RenderText(int x, int y, const char* text, float r, float g, float b) {
    if (!text || !fontBase) return;
    
    glColor3f(r, g, b);
    glRasterPos2i(x, y);
    glPushAttrib(GL_LIST_BIT);
    glListBase(fontBase);
    glCallLists(StrLen(text), GL_UNSIGNED_BYTE, text);
    glPopAttrib();
}

LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) {
    switch (message) {
        case WM_CLOSE:
            PostQuitMessage(0);
            return 0;
        case WM_DESTROY:
            return 0;
        case WM_KEYDOWN:
            if (wParam == VK_ESCAPE) {
                PostQuitMessage(0);
            }
            return 0;
        default:
            return DefWindowProc(hWnd, message, wParam, lParam);
    }
}

int __cdecl InitOpenGL(void) {
    WNDCLASSEX wc;
    PIXELFORMATDESCRIPTOR pfd;
    int format;
    HINSTANCE hInstance = GetModuleHandle(NULL);
    int i;
    
    for (i = 0; i < sizeof(WNDCLASSEX); i++) {
        ((char*)&wc)[i] = 0;
    }
    for (i = 0; i < sizeof(PIXELFORMATDESCRIPTOR); i++) {
        ((char*)&pfd)[i] = 0;
    }
    
    wc.cbSize = sizeof(WNDCLASSEX);
    wc.style = CS_HREDRAW | CS_VREDRAW | CS_OWNDC;
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInstance;
    wc.hIcon = LoadIcon(NULL, IDI_APPLICATION);
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.lpszClassName = "RaycastPacman";
    wc.hIconSm = LoadIcon(NULL, IDI_APPLICATION);
    
    if (!RegisterClassEx(&wc)) {
        MessageBox(NULL, "Window Registration Failed!", "Error", MB_ICONEXCLAMATION | MB_OK);
        return 0;
    }
    
    hWnd = CreateWindowEx(
        WS_EX_APPWINDOW,
        "RaycastPacman",
        "MASM Raycast Pacman - 3D View",
        WS_OVERLAPPEDWINDOW,
        100, 100,
        screenWidth + 16,
        screenHeight + 39,
        NULL, NULL,
        hInstance,
        NULL
    );
    
    if (hWnd == NULL) {
        MessageBox(NULL, "Window Creation Failed!", "Error", MB_ICONEXCLAMATION | MB_OK);
        return 0;
    }
    
    ShowWindow(hWnd, SW_SHOW);
    UpdateWindow(hWnd);
    SetForegroundWindow(hWnd);
    SetFocus(hWnd);
    
    hDC = GetDC(hWnd);
    if (!hDC) {
        MessageBox(NULL, "Failed to get DC!", "Error", MB_ICONEXCLAMATION | MB_OK);
        return 0;
    }
    
    pfd.nSize = sizeof(pfd);
    pfd.nVersion = 1;
    pfd.dwFlags = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER;
    pfd.iPixelType = PFD_TYPE_RGBA;
    pfd.cColorBits = 24;
    pfd.cDepthBits = 16;
    pfd.iLayerType = PFD_MAIN_PLANE;
    
    format = ChoosePixelFormat(hDC, &pfd);
    if (!format || !SetPixelFormat(hDC, format, &pfd)) {
        MessageBox(NULL, "Failed to set pixel format!", "Error", MB_ICONEXCLAMATION | MB_OK);
        return 0;
    }
    
    hRC = wglCreateContext(hDC);
    if (!hRC || !wglMakeCurrent(hDC, hRC)) {
        MessageBox(NULL, "Failed to create OpenGL!", "Error", MB_ICONEXCLAMATION | MB_OK);
        return 0;
    }
    
    glViewport(0, 0, screenWidth, screenHeight);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, screenWidth, screenHeight, 0, -1, 1);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glDisable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    // Build bitmap font
    BuildFont(hDC);
    
    return 1;
}

void __cdecl DrawCeiling(void) {
    glClear(GL_COLOR_BUFFER_BIT);
    
    glColor3f(0.05f, 0.05f, 0.15f);
    glBegin(GL_QUADS);
        glVertex2i(0, 0);
        glVertex2i(screenWidth, 0);
        glVertex2i(screenWidth, screenHeight / 2);
        glVertex2i(0, screenHeight / 2);
    glEnd();
}

void __cdecl DrawWallColumn(int column, int wallHeight, int wallType, int brightness) {
    int drawStart, drawEnd;
    Color color;
    float b = brightness / 255.0f;
    
    if (column < 0 || column >= screenWidth || wallHeight <= 0) return;
    
    drawStart = (screenHeight - wallHeight) / 2;
    if (drawStart < 0) drawStart = 0;
    
    drawEnd = (screenHeight + wallHeight) / 2;
    if (drawEnd >= screenHeight) drawEnd = screenHeight - 1;
    
    if (wallType >= 0 && wallType < 4) {
        color = wallColors[wallType];
    } else {
        color = wallColors[1];
    }
    
    glBegin(GL_QUADS);
        glColor3f(color.r * b, color.g * b, color.b * b);
        glVertex2i(column, drawStart);
        glVertex2i(column + 1, drawStart);
        glVertex2i(column + 1, drawEnd);
        glVertex2i(column, drawEnd);
    glEnd();
}

void __cdecl DrawFloorPixel(int column, int y, int color) {
    float r, g, b;
    
    if (column < 0 || column >= screenWidth) return;
    if (y < 0 || y >= screenHeight) return;
    
    r = ((color >> 16) & 0xFF) / 255.0f;
    g = ((color >> 8) & 0xFF) / 255.0f;
    b = (color & 0xFF) / 255.0f;
    
    glBegin(GL_POINTS);
        glColor3f(r, g, b);
        glVertex2i(column, y);
    glEnd();
}

void __cdecl DrawHUD(int playerX, int playerY, int points, int lives, int gameState) {
    char buffer[128];
    
    glColor4f(0.0f, 0.0f, 0.0f, 0.7f);
    glBegin(GL_QUADS);
        glVertex2i(0, 0);
        glVertex2i(screenWidth, 0);
        glVertex2i(screenWidth, 50);
        glVertex2i(0, 50);
    glEnd();
    
    StrCopy(buffer, "SCORE: ");
    if (points < 100) StrCat(buffer, "0");
    if (points < 10) StrCat(buffer, "0");
    {
        char numStr[16];
        IntToStr(points, numStr);
        StrCat(buffer, numStr);
    }
    RenderText(10, 30, buffer, 1.0f, 1.0f, 0.0f);
    
    StrCopy(buffer, "POS: (");
    {
        char numStr[16];
        IntToStr(playerX, numStr);
        StrCat(buffer, numStr);
        StrCat(buffer, ", ");
        IntToStr(playerY, numStr);
        StrCat(buffer, numStr);
        StrCat(buffer, ")");
    }
    RenderText(200, 30, buffer, 1.0f, 1.0f, 0.0f);
    RenderText(screenWidth - 280, 30, "Arrow Keys | ESC: Quit", 0.6f, 0.6f, 0.6f);
    
    if (gameState == 6) {  // Start screen
        RenderText(screenWidth / 2 - 170, screenHeight / 2, "PRESS ANY KEY TO START", 0.0f, 1.0f, 1.0f);
    } else if (gameState == 3) {  // Win screen
        RenderText(screenWidth / 2 - 60, screenHeight / 2 - 20, "YOU WIN!", 0.0f, 1.0f, 0.0f);
        RenderText(screenWidth / 2 - 150, screenHeight / 2 + 20, "Press any key to continue", 1.0f, 1.0f, 1.0f);
    } else if (gameState == 4) {  // Game over screen
        RenderText(screenWidth / 2 - 70, screenHeight / 2 - 20, "GAME OVER!", 1.0f, 0.0f, 0.0f);
        RenderText(screenWidth / 2 - 150, screenHeight / 2 + 20, "Press any key to continue", 1.0f, 1.0f, 1.0f);
    }
    
    if (gameState == 0) {
        glColor3f(1.0f, 1.0f, 0.0f);
        {
            int centerX = screenWidth / 2;
            int centerY = screenHeight / 2;
            glBegin(GL_LINES);
                glVertex2i(centerX - 10, centerY);
                glVertex2i(centerX + 10, centerY);
                glVertex2i(centerX, centerY - 10);
                glVertex2i(centerX, centerY + 10);
            glEnd();
        }
    }
}

void __cdecl DrawMinimap(unsigned char* mazeMap, int mazeSize, int playerX, int playerY, int ghostX, int ghostY) {
    int minimapSize = 150;
    int minimapX = screenWidth - minimapSize - 10;
    int minimapY = 50;
    int cellSize = minimapSize / mazeSize;
    int x, y;
    
    if (!mazeMap) return;
    
    glColor4f(0.0f, 0.0f, 0.0f, 0.7f);
    glBegin(GL_QUADS);
        glVertex2i(minimapX - 5, minimapY - 5);
        glVertex2i(minimapX + minimapSize + 5, minimapY - 5);
        glVertex2i(minimapX + minimapSize + 5, minimapY + minimapSize + 5);
        glVertex2i(minimapX - 5, minimapY + minimapSize + 5);
    glEnd();
    
    glColor3f(0.5f, 0.5f, 0.5f);
    glBegin(GL_LINE_LOOP);
        glVertex2i(minimapX - 5, minimapY - 5);
        glVertex2i(minimapX + minimapSize + 5, minimapY - 5);
        glVertex2i(minimapX + minimapSize + 5, minimapY + minimapSize + 5);
        glVertex2i(minimapX - 5, minimapY + minimapSize + 5);
    glEnd();
    
    for (y = 0; y < mazeSize; y++) {
        for (x = 0; x < mazeSize; x++) {
            int idx = y * mazeSize + x;
            int cellType = mazeMap[idx];
            int px = minimapX + x * cellSize;
            int py = minimapY + y * cellSize;
            
            if (cellType == 1) {
                glColor3f(0.3f, 0.3f, 0.9f);
            } else if (cellType == 2) {
                glColor3f(0.9f, 0.9f, 0.0f);
            } else {
                glColor3f(0.1f, 0.1f, 0.1f);
            }
            
            glBegin(GL_QUADS);
                glVertex2i(px, py);
                glVertex2i(px + cellSize, py);
                glVertex2i(px + cellSize, py + cellSize);
                glVertex2i(px, py + cellSize);
            glEnd();
        }
    }
    
    glColor3f(0.0f, 1.0f, 0.0f);
    {
        int px = minimapX + playerX * cellSize + cellSize / 2;
        int py = minimapY + playerY * cellSize + cellSize / 2;
        int psize = cellSize > 3 ? 3 : cellSize;
        glBegin(GL_QUADS);
            glVertex2i(px - psize, py - psize);
            glVertex2i(px + psize, py - psize);
            glVertex2i(px + psize, py + psize);
            glVertex2i(px - psize, py + psize);
        glEnd();
    }
    
    glColor3f(1.0f, 0.0f, 0.0f);
    {
        int gx = minimapX + ghostX * cellSize + cellSize / 2;
        int gy = minimapY + ghostY * cellSize + cellSize / 2;
        int gsize = cellSize > 3 ? 3 : cellSize;
        glBegin(GL_QUADS);
            glVertex2i(gx - gsize, gy - gsize);
            glVertex2i(gx + gsize, gy - gsize);
            glVertex2i(gx + gsize, gy + gsize);
            glVertex2i(gx - gsize, gy + gsize);
        glEnd();
    }
}

void __cdecl UpdateDisplay(void) {
    MSG msg;
    
    if (hDC) {
        SwapBuffers(hDC);
    }
    
    while (PeekMessage(&msg, NULL, 0, 0, PM_REMOVE)) {
        if (msg.message == WM_QUIT) {
            ExitProcess(0);
        }
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
}

void __cdecl CloseRenderWindow(void) {
    if (fontBase) {
        glDeleteLists(fontBase, 256);
        fontBase = 0;
    }
    if (hRC) {
        wglMakeCurrent(NULL, NULL);
        wglDeleteContext(hRC);
        hRC = NULL;
    }
    if (hDC) {
        ReleaseDC(hWnd, hDC);
        hDC = NULL;
    }
    if (hWnd) {
        DestroyWindow(hWnd);
        hWnd = NULL;
    }
}