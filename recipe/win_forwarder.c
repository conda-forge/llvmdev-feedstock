// adapted from example in MSFT docs, see
// https://learn.microsoft.com/en-us/windows/win32/procthread/creating-processes
#include <windows.h>
#include <stdio.h>
#include <string.h>
#include <tchar.h>

// the idea here is as follows; this wrapper will be compiled and renamed into
// a file corresponding to the versioned binaries created in install_llvm.bat.
// For example, we'll have llc.exe and llc-19.exe, both under %LIBRARY_BIN%.
// To avoid security holes, we ensure that the wrapper can only call binaries
// in %LIBRARY_BIN%, otherwise we fail. For example:
//  * user calls `llc -version`; argv[0] == "llc", argv[1] == "-version"
//  * determine path of calling binary, i.e. %LIBRARY_BIN%\llc.exe
//  * construct versioned path, i.e. %LIBRARY_BIN%\llc-19.exe
//  * collect all other arguments & quote them, e.g. `"argv[1]" "argv[2]" ...`
//  * invoke `%LIBRARY_BIN%\llc-19.exe "argv[1]" "argv[2]" ...`
//  * collect return value from inner call and return the same from wrapper

int _tmain( int argc, TCHAR *argv[] )
{
    STARTUPINFO si;
    PROCESS_INFORMATION pi;
    DWORD error_code;

    ZeroMemory( &si, sizeof(si) );
    si.cb = sizeof(si);
    ZeroMemory( &pi, sizeof(pi) );

    // reconstruct commandline call we received, pointing to versioned binary;
    // 32767 == maximum length for lpCommandLine argument
    char forwarded[32767];
    // initialize buffer with dummy so that strlen below is not UB
    strcat(forwarded, "xxx");

    // argv[0] is the name of the calling function, which might be a relative path;
    // for security reasons, get the absolute path of the binary we're calling from
    // with help from the MIT-licensed https://github.com/gpakosz/whereami
    void* addr = _ReturnAddress();
    HMODULE hm = NULL;
    // non-zero return means success
    if (GetModuleHandleEx(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
                          GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                          (LPCSTR) addr, &hm))
        GetModuleFileNameA(hm, forwarded, sizeof(forwarded));

    unsigned int len = strlen(forwarded);
    if (len < 4) {
        // realistically, minimum len(r"C:\a") == 4; dummy value has length 3
        printf( "Could not determine location of calling binary!\n" );
        return GetLastError();
    }
    // chop off ".exe" (if the binary we're in was invoked like that)
    if (strcmp(&forwarded[len-4], ".exe") == 0)
        // set null-terminator to finish the string early
        forwarded[len-4] = '\0';
    // point to versioned binary
    strcat(forwarded, "-{{ majorversion }}.exe");
    // rest stays the same, but wrap everything in quotes, because
    // the contents of argv[i] get stripped of those, which fails
    // if there's any argument that relies on atomicity, e.g. paths
    // with spaces in them (c.f. "C:\Program Files\...")
    for (int i = 1; i < argc; i++) {
        strcat(forwarded, " \"");
        strcat(forwarded, argv[i]);
        strcat(forwarded, "\"");
    }

    // Start the child process.
    if( !CreateProcess( NULL,       // No module name (use command line)
                        (char*)&forwarded,  // Command line
                        NULL,       // Process handle not inheritable
                        NULL,       // Thread handle not inheritable
                        FALSE,      // Set handle inheritance to FALSE
                        0,          // No creation flags
                        NULL,       // Use parent's environment block
                        NULL,       // Use parent's starting directory
                        &si,        // Pointer to STARTUPINFO structure
                        &pi ) )     // Pointer to PROCESS_INFORMATION structure
    {
        printf( "Forwarding call to versioned binary failed:\n" );
        printf( "%s", forwarded );
        return GetLastError();
    }

    // Wait until child process exits.
    WaitForSingleObject( pi.hProcess, INFINITE );

    // Needs be called before the thread terminates, even though the value
    // only gets populated after the thread terminates.
    // If GetExitCodeProcess succeeds, it will correctly set &error_code to
    // the result of the inner call, but will return a non-zero value itself.
    // If it fails, use the last available error. For details see
    // https://learn.microsoft.com/en-gb/windows/win32/api/processthreadsapi/nf-processthreadsapi-getexitcodeprocess
    if( !GetExitCodeProcess( pi.hProcess, &error_code ) )
        error_code = GetLastError();

    // Close process and thread handles.
    CloseHandle( pi.hProcess );
    CloseHandle( pi.hThread );

    return error_code;
}
