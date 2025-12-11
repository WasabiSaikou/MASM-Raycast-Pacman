#include <windows.h>
#include <gl/gl.h>
#include <gl/glu.h>
#include <stdio.h>
#include <string.h>

// Window and OpenGL context
static HWND hWnd = NULL;
static HDC hDC = NULL;
static HGLRC hRC = NULL;
static int screenWidth = 640;
static int screenHeight = 480;

// Color palette for different wall types
typedef struct {
    float r, g, b;
} Color;

static Color wallColors[] = {
    {0.0f, 0.0f, 0.0f},      // Type 0: Black (empty/no wall)
    {0.3f, 0.3f, 0.6f},      // Type 1: Blue-gray wall
    {0.6f, 0.4f, 0.1f},      // Type 2: Orange (path with dots)
};

// Window procedure
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

// Initialize OpenGL context and window
int __cdecl InitOpenGL(void) {
    WNDCLASSEX wc;
    PIXELFORMATDESCRIPTOR pfd;
    int format;
    HINSTANCE hInstance = GetModuleHandle(NULL);
    
    // Zero out structures
    wc.cbSize = sizeof(WNDCLASSEX);
    wc.style = CS_HREDRAW | CS_VREDRAW | CS_OWNDC;
    wc.lpfnWndProc = WndProc;
    wc.cbClsExtra = 0;
    wc.cbWndExtra = 0;
    
    // Register window class
    wc.cbSize = sizeof(WNDCLASSEX);
    wc.style = CS_HREDRAW | CS_VREDRAW | CS_OWNDC;
    wc.lpfnWndProc = WndProc;
    wc.cbClsExtra = 0;
    wc.cbWndExtra = 0;
    wc.hInstance = hInstance;
    wc.hIcon = LoadIcon(NULL, IDI_APPLICATION);
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.lpszMenuName = NULL;
    wc.lpszClassName = "RaycastPacman";
    wc.hIconSm = LoadIcon(NULL, IDI_APPLICATION);
    
    if (!RegisterClassEx(&wc)) {
        MessageBox(NULL, "Window Registration Failed!", "Error", MB_ICONEXCLAMATION | MB_OK);
        return 0;
    }
    
    // Create window with adjusted size for borders
    RECT wr = {0, 0, screenWidth, screenHeight};
    AdjustWindowRect(&wr, WS_OVERLAPPEDWINDOW, FALSE);
    
    hWnd = CreateWindowEx(
        WS_EX_APPWINDOW,
        "RaycastPacman",
        "MASM Raycast Pacman",
        WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT,
        wr.right - wr.left,
        wr.bottom - wr.top,
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
    
    // Get device context
    hDC = GetDC(hWnd);
    if (!hDC) {
        MessageBox(NULL, "Failed to get device context!", "Error", MB_ICONEXCLAMATION | MB_OK);
        return 0;
    }
    
    // Set pixel format
    pfd.nSize = sizeof(pfd);
    pfd.nVersion = 1;
    pfd.dwFlags = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER;
    pfd.iPixelType = PFD_TYPE_RGBA;
    pfd.cColorBits = 24;
    pfd.cDepthBits = 16;
    pfd.iLayerType = PFD_MAIN_PLANE;
    
    format = ChoosePixelFormat(hDC, &pfd);
    if (!format) {
        MessageBox(NULL, "Failed to choose pixel format!", "Error", MB_ICONEXCLAMATION | MB_OK);
        return 0;
    }
    
    if (!SetPixelFormat(hDC, format, &pfd)) {
        MessageBox(NULL, "Failed to set pixel format!", "Error", MB_ICONEXCLAMATION | MB_OK);
        return 0;
    }
    
    // Create OpenGL context
    hRC = wglCreateContext(hDC);
    if (!hRC) {
        MessageBox(NULL, "Failed to create OpenGL context!", "Error", MB_ICONEXCLAMATION | MB_OK);
        return 0;
    }
    
    if (!wglMakeCurrent(hDC, hRC)) {
        MessageBox(NULL, "Failed to activate OpenGL context!", "Error", MB_ICONEXCLAMATION | MB_OK);
        return 0;
    }
    
    // Set up OpenGL viewport
    glViewport(0, 0, screenWidth, screenHeight);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, screenWidth, screenHeight, 0, -1, 1);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    
    // OpenGL settings
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glDisable(GL_DEPTH_TEST);
    glClear(GL_COLOR_BUFFER_BIT);
    
    return 1;
}

// Draw floor and ceiling
void __cdecl DrawFloorCeiling(void) {
    // Draw ceiling (dark blue-gray)
    glColor3f(0.1f, 0.1f, 0.2f);
    glBegin(GL_QUADS);
        glVertex2i(0, 0);
        glVertex2i(screenWidth, 0);
        glVertex2i(screenWidth, screenHeight / 2);
        glVertex2i(0, screenHeight / 2);
    glEnd();
    
    // Draw floor (darker gray)
    glColor3f(0.2f, 0.2f, 0.2f);
    glBegin(GL_QUADS);
        glVertex2i(0, screenHeight / 2);
        glVertex2i(screenWidth, screenHeight / 2);
        glVertex2i(screenWidth, screenHeight);
        glVertex2i(0, screenHeight);
    glEnd();
}

// Draw a single wall column
void __cdecl DrawWallColumn(int column, int wallHeight, int wallType, int textureX) {
    int drawStart, drawEnd;
    Color color;
    float shadeFactor = 1.0f;
    
    // Validate inputs
    if (column < 0 || column >= screenWidth) return;
    if (wallHeight <= 0) return;
    
    // Calculate drawing boundaries
    drawStart = (screenHeight - wallHeight) / 2;
    if (drawStart < 0) drawStart = 0;
    
    drawEnd = (screenHeight + wallHeight) / 2;
    if (drawEnd >= screenHeight) drawEnd = screenHeight - 1;
    
    // Get wall color based on type
    if (wallType >= 0 && wallType < sizeof(wallColors) / sizeof(Color)) {
        color = wallColors[wallType];
    } else {
        color = wallColors[1]; // Default to wall color
    }
    
    // Apply distance shading (darker = farther)
    if (wallHeight < screenHeight / 8) {
        shadeFactor = 0.3f;
    } else if (wallHeight < screenHeight / 4) {
        shadeFactor = 0.5f;
    } else if (wallHeight < screenHeight / 2) {
        shadeFactor = 0.7f;
    }
    
    glColor3f(color.r * shadeFactor, color.g * shadeFactor, color.b * shadeFactor);
    
    // Draw vertical line for this column
    glBegin(GL_LINES);
        glVertex2i(column, drawStart);
        glVertex2i(column, drawEnd);
    glEnd();
}

// Update the display (swap buffers, process events)
void __cdecl UpdateDisplay(void) {
    MSG msg;
    
    // Swap buffers
    if (hDC) {
        SwapBuffers(hDC);
    }
    
    // Process Windows messages (non-blocking)
    while (PeekMessage(&msg, NULL, 0, 0, PM_REMOVE)) {
        if (msg.message == WM_QUIT) {
            ExitProcess(0);
        }
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
    
    // Clear for next frame
    glClear(GL_COLOR_BUFFER_BIT);
}

// Cleanup
void __cdecl CloseRenderWindow(void) {
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