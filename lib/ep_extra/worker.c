#include <Windows.h>
#include <Shlwapi.h>
#pragma comment(lib, "Shlwapi.lib")
#include <stdio.h>

HMODULE hModule = NULL;
HANDLE sigFinish = NULL;
void* pFinishProc = NULL;

void done() {
    WaitForSingleObject(sigFinish, INFINITE);
    FreeLibraryAndExitThread(hModule, 0);
}

void* worker() {


wchar_t directory[MAX_PATH];

if (GetModuleFileNameW(NULL, directory, MAX_PATH) == 0) {
    wprintf(L"Failed to get executable path. Error: %lu\n", GetLastError());
    return 1;
}
wchar_t* lastSlash = wcsrchr(directory, L'\\');
if (lastSlash) {
    *lastSlash = L'\0';  
}


wchar_t pattern[MAX_PATH];
swprintf(pattern, MAX_PATH, L"%ls\\plug\\exp_*.dll", directory);

  

WIN32_FIND_DATA data;
HANDLE hFind = FindFirstFileW(pattern, &data);

if (hFind != INVALID_HANDLE_VALUE) {
    do {
        wchar_t fullPath[MAX_PATH];
        swprintf(fullPath, MAX_PATH, L"%ls\\plug\\%ls", directory, data.cFileName);
        wprintf(L"Found file: %ls\n", fullPath);
          HMODULE hLib = LoadLibraryW(fullPath);
            if (hLib) {
                FARPROC proc = (FARPROC)(GetProcAddress(hLib, "setup"));
                if (proc) {
                    if (proc()) FreeLibrary(hLib);
                }
                else FreeLibrary(hLib);
            }

    } while (FindNextFileW(hFind, &data)); 

    FindClose(hFind); 
}


    sigFinish = CreateEventW(NULL, FALSE, FALSE, NULL);
    if (sigFinish) {
        BYTE payload[] = {
            0x48, 0xB9, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // mov rcx, sigFinish
            0x48, 0xB8, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // mov rax, SetEvent
            0xFF, 0xD0, // call SetEvent
            0xC9, // leave
            0xC3  // ret
        };
        *(INT64*)(payload + 2) = sigFinish;
        *(INT64*)(payload + 12) = SetEvent;

        pFinishProc = VirtualAlloc(NULL, sizeof(payload), MEM_COMMIT, PAGE_EXECUTE_READWRITE);
        if (pFinishProc) {
            memcpy(pFinishProc, payload, sizeof(payload));
            SHCreateThread(done, 0, CTF_NOADDREFLIB, NULL);
            return pFinishProc;
        }
    }
    return NULL;
}

BOOL WINAPI DllMain(
    _In_ HINSTANCE hinstDLL,
    _In_ DWORD     fdwReason,
    _In_ LPVOID    lpvReserved
)
{
    switch (fdwReason)
    {
    case DLL_PROCESS_ATTACH:
        DisableThreadLibraryCalls(hinstDLL);
        hModule = hinstDLL;
        break;
    case DLL_THREAD_ATTACH:
        break;
    case DLL_THREAD_DETACH:
        break;
    case DLL_PROCESS_DETACH:
        break;
    }
    return TRUE;
}




//WCHAR wszExtraLibPath[MAX_PATH];
//if (GetWindowsDirectoryW(wszExtraLibPath, MAX_PATH))
//{
//    wcscat_s(wszExtraLibPath, MAX_PATH, L"\\ep_extra.dll");
//    if (FileExistsW(wszExtraLibPath))
//    {
//        HMODULE hExtra = LoadLibraryW(wszExtraLibPath);
//        if (hExtra)
//        {
//            printf("[Extra] Found library: %p.\n", hExtra);
//            FARPROC ep_extra_entrypoint = GetProcAddress(hExtra, "ep_extra_EntryPoint");
//            if (ep_extra_entrypoint)
//            {
//                printf("[Extra] Running entry point...\n");
//                ep_extra_entrypoint();
//                printf("[Extra] Finished running entry point.\n");
//            }
//        }
//        else
//        {
//            printf("[Extra] LoadLibraryW failed with 0x%x.", GetLastError());
//        }
//    }
//}