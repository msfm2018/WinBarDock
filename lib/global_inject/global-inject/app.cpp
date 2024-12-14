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

	// 全局静态变量 engineControl，只初始化一次
	static EngineControl engineControl;

	// 导出函数，用来获取新进程的数量
	__declspec(dllexport) int HandleNewProcessesExport()
	{
		// 使用全局静态的 engineControl
		int count = engineControl.HandleNewProcesses();
		if (count == 1) {
			// Injected into a new process
		}
		else if (count > 1) {
			// Injected into multiple processes
		}
		return count;
	}

	// DLL 主函数
	__declspec(dllexport) int dllmaincpp()
	{
		SetDebugPrivilege(TRUE);

	

		return 0;
	}
}




