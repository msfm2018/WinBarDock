#include <windows.h>
#include <stdio.h>
#include <time.h>

static HANDLE hDllModule = NULL;
static HHOOK hCBTHook = NULL;
 HWND g_hWndTarget = NULL; // ȫ�ֱ����洢����� handle
HHOOK CbtHook = NULL;
FILE* pFile ;
int write_log(FILE* pFile, const char* format, ...) {
	va_list arg;
	int done;

	va_start(arg, format);
	//done = vfprintf (stdout, format, arg);

	time_t time_log = time(NULL);
	struct tm* tm_log = localtime(&time_log);
	fprintf(pFile, "%04d-%02d-%02d %02d:%02d:%02d ", tm_log->tm_year + 1900, tm_log->tm_mon + 1, tm_log->tm_mday, tm_log->tm_hour, tm_log->tm_min, tm_log->tm_sec);

	done = vfprintf(pFile, format, arg);
	va_end(arg);

	fflush(pFile);
	return done;
}


// ���ӻص�����
LRESULT CALLBACK CBTProc(int nCode, WPARAM wParam, LPARAM lParam) {
 
    if (nCode < 0)
        return CallNextHookEx(hCBTHook, nCode, wParam, lParam);
	//if ((nCode == HCBT_ACTIVATE) || (nCode == HCBT_SETFOCUS)) {
		if (nCode == HCBT_SETFOCUS){
		HWND hWndActivated = (HWND)wParam;
		 g_hWndTarget = FindWindow(NULL, L"myxyzabc");
		// write_log(pFile, "%s,%d--------,%d\n", "Ŀ�괰�ھ����Ч��\n", g_hWndTarget, hWndActivated);

			if (g_hWndTarget != NULL) {
			
			if (hWndActivated != g_hWndTarget) {
			
				PostMessage(g_hWndTarget, 1025, 0, 0);
			}

		}
	};


    // ���ݸ���һ������
    return CallNextHookEx(hCBTHook, nCode, wParam, lParam);
}

// �����������������ù��Ӳ�������� handle
__declspec(dllexport) BOOL SetCBTHook(HWND hWndTarget) {

    if ((hCBTHook == NULL)&& (hDllModule!=NULL))
        // ���ù���
        hCBTHook = SetWindowsHookEx(WH_CBT, CBTProc, (HINSTANCE)hDllModule, 0);
    return hCBTHook != NULL;
}

// ��������������ж�ع���
__declspec(dllexport) void UnsetCBTHook() {
    if (hCBTHook) {
        UnhookWindowsHookEx(hCBTHook);
        hCBTHook = NULL;
    }
}




// DLL ��ں���
BOOL APIENTRY DllMain(HMODULE hModule, DWORD  ul_reason_for_call, LPVOID lpReserved) {
	switch (ul_reason_for_call) {
	case DLL_PROCESS_ATTACH:
		hDllModule = hModule; 
		//HANDLE hProcess = GetCurrentProcess();
		//WCHAR szFilePath[MAX_PATH] = { 0 };
		//GetProcessImageFileNameW(hProcess,  szFilePath, MAX_PATH);
		 //pFile = fopen("c:\\123.txt", "a");
		 //fwprintf(pFile, L"%s\n", szFilePath);

		break;
	case DLL_THREAD_ATTACH:
		break;
	case DLL_THREAD_DETACH:
		break;
	case DLL_PROCESS_DETACH:
		//fclose(pFile);
	
		UnsetCBTHook();
		break;
	}
	return TRUE;
}
