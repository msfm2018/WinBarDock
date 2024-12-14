#define WIN32_LEAN_AND_MEAN
#include <windows.h>

//////////////////////////////////////////////////////////////////////////
// STL

#include <filesystem>
#include <stdexcept>

//////////////////////////////////////////////////////////////////////////
// Libraries

#include <wil/stl.h> // must be included before other wil includes
#include <wil/resource.h>
#include <wil/result.h>
#include <wil/win32_helpers.h>
#include "functions.h"
#include "engine_control.h"
#include <thread>  // For std::thread

extern "C" {

	// ȫ�־�̬���� engineControl��ֻ��ʼ��һ��
	static EngineControl engineControl;

	// ����������������ȡ�½��̵�����
	__declspec(dllexport) int HandleNewProcessesExport()
	{
		// ʹ��ȫ�־�̬�� engineControl
		int count = engineControl.HandleNewProcesses();
		if (count == 1) {
			// Injected into a new process
		}
		else if (count > 1) {
			// Injected into multiple processes
		}
		return count;
	}

	// DLL ������
	__declspec(dllexport) int dllmaincpp()
	{
		SetDebugPrivilege(TRUE);

	

		return 0;
	}
}




