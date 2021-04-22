// pch.h : include file for standard system include files,
// or project specific include files that are used frequently, but
// are changed infrequently
//

#pragma once

// Windows Header Files:
#include <unknwn.h>
#include <windows.h>
#include <propvarutil.h>
//#include <mfstd.h> // Must be included before <initguid.h>, or else DirectDraw GUIDs will be defined twice. See the comment in <uuids.h>.
#include <ole2.h>
#include <initguid.h>
#include <ks.h>
#include <ksmedia.h>
#include <mfapi.h>
#include <mferror.h>
#include <mfidl.h>
#include <mfreadwrite.h>
#include <nserror.h>
#include <winmeta.h>
//#include <wrl.h>
#include <d3d9types.h>


#define RESULT_DIAGNOSTICS_LEVEL 4 // include function name

#include <wil\cppwinrt.h> // must be before the first C++ WinRT header, ref:https://github.com/Microsoft/wil/wiki/Error-handling-helpers
#include <wil\result.h>
#include "wil\com.h"

#include <winrt\base.h>



//using namespace Microsoft::WRL;
//using namespace Microsoft::WRL::Wrappers;

#if !defined(_IKsControl_)
#define _IKsControl_
interface DECLSPEC_UUID("28F54685-06FD-11D2-B27A-00A0C9223196") IKsControl;
#undef INTERFACE
#define INTERFACE IKsControl
DECLARE_INTERFACE_(IKsControl, IUnknown)
{
    STDMETHOD(KsProperty)(
        THIS_
        IN PKSPROPERTY Property,
        IN ULONG PropertyLength,
        IN OUT LPVOID PropertyData,
        IN ULONG DataLength,
        OUT ULONG* BytesReturned
        ) PURE;
    STDMETHOD(KsMethod)(
        THIS_
        IN PKSMETHOD Method,
        IN ULONG MethodLength,
        IN OUT LPVOID MethodData,
        IN ULONG DataLength,
        OUT ULONG* BytesReturned
        ) PURE;
    STDMETHOD(KsEvent)(
        THIS_
        IN PKSEVENT Event OPTIONAL,
        IN ULONG EventLength,
        IN OUT LPVOID EventData,
        IN ULONG DataLength,
        OUT ULONG* BytesReturned
        ) PURE;
};
#endif  // _IKsControl_

#include "SimpleFrameGenerator.h"
#include "SimpleMediaStream.h"
#include "SimpleMediaSource.h"
#include "SimpleMediaSourceActivate.h"

#pragma comment(lib, "windowsapp")

inline void DebugPrint(LPCWSTR szFormat, ...)
{
    WCHAR szBuffer[MAX_PATH] = { 0 };

    va_list pArgs;
    va_start(pArgs, szFormat);
    StringCbVPrintf(szBuffer, sizeof(szBuffer), szFormat, pArgs);
    va_end(pArgs);
    OutputDebugStringW(szBuffer);
}

#define DEBUG_MSG(msg,...) \
{\
    DebugPrint(L"[%s@%d] ", TEXT(__FUNCTION__), __LINE__);\
    DebugPrint(msg, __VA_ARGS__);\
    DebugPrint(L"\n");\
}\

namespace wilEx
{
    //template <typename T>
    //using make_unique_cotaskmem_array = unique_any_array_ptr<typename details::element_traits<T>::type>;

    template<typename T>
    wil::unique_cotaskmem_array_ptr<T> make_unique_cotaskmem_array(size_t numOfElements)
    {
        wil::unique_cotaskmem_array_ptr<T> arr;
        size_t cb = sizeof(wil::details::element_traits<T>::type) * numOfElements;
        void* ptr = ::CoTaskMemAlloc(cb);
        if (ptr != nullptr)
        {
            ZeroMemory(ptr, cb);
            arr.reset(reinterpret_cast<typename wil::details::element_traits<T>::type*>(ptr), numOfElements);
        }
        return arr;
    }
};

namespace winrt
{
    template<> bool is_guid_of<IMFMediaSourceEx>(guid const& id) noexcept;

    template<> bool is_guid_of<IMFMediaStream2>(guid const& id) noexcept;

    template<> bool is_guid_of<IMFActivate>(guid const& id) noexcept;
};

