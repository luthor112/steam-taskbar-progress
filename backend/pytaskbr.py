from ctypes import c_wchar_p, c_int, c_ulonglong, POINTER, HRESULT
import comtypes.client
from comtypes import GUID, IUnknown, COMMETHOD
from enum import IntFlag


class ITaskbarList(IUnknown):
  _case_insensitive_ = True
  _iid_ = GUID('{56FDF342-FD6D-11D0-958A-006097C9A090}')
  _idlflags_ = []


class ITaskbarList2(ITaskbarList):
  _case_insensitive_ = True
  _iid_ = GUID('{602D4995-B13A-429B-A66E-1935E44F4317}')
  _idlflags_ = []


class ITaskbarList3(ITaskbarList2):
  _case_insensitive_ = True
  _iid_ = GUID('{EA1AFB91-9E28-4B86-90E9-9E9F8A5EEFAF}')
  _idlflags_ = []


dummyMethod = COMMETHOD([], None, '__dummyMethodDontUse__')

ITaskbarList._methods_ = [
  COMMETHOD([], HRESULT, 'HrInit'),
  dummyMethod,  # AddTab
  dummyMethod,  # DeleteTab
  COMMETHOD([], HRESULT, 'ActivateTab', (['in'], c_int, 'hwnd')),
  dummyMethod,  # SetActiveAlt
]

ITaskbarList2._methods_ = [
  dummyMethod,  # MarkFullscreenWindow
]


class TBPFlag(IntFlag):
  noProgress = 0
  indeterminate = 1
  normal = 2
  error = 4
  paused = 8


ITaskbarList3._methods_ = [
  COMMETHOD([], HRESULT, 'SetProgressValue', (['in'], c_int, 'hwnd'),
            (['in'], c_ulonglong, 'ullCompleted'),
            (['in'], c_ulonglong, 'ullTotal')),
  COMMETHOD([], HRESULT, 'SetProgressState', (['in'], c_int, 'hwnd'),
            (['in'], c_int, 'tbpFlags')),
  dummyMethod,  # RegisterTab
  dummyMethod,  # RegisterTab
  dummyMethod,  # SetTabOrder
  dummyMethod,  # SetTabActive
  dummyMethod,  # ThumbBarAddButtons
  dummyMethod,  # ThumbBarUpdateButtons
  dummyMethod,  # ThumbBarSetImageList
  COMMETHOD([], HRESULT, 'SetOverlayIcon', (['in'], c_int, 'hwnd'),
            (['in'], POINTER(IUnknown), 'hIcon'),
            (['in'], c_wchar_p, 'pszDescription')),
  COMMETHOD([], HRESULT, 'SetThumbnailTooltip', (['in'], c_int, 'hwnd'),
            (['in'], c_wchar_p, 'pszTip')),
  dummyMethod,  # SetThumbnailClip
]
taskbar = comtypes.client.CreateObject('{56FDF344-FD6D-11d0-958A-006097C9A090}',
                                       interface=ITaskbarList3)