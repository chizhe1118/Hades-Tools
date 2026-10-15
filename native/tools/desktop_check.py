import argparse
import ctypes
from ctypes import wintypes
from pathlib import Path
import time

from PIL import ImageGrab
import pyautogui

parser = argparse.ArgumentParser()
parser.add_argument('--title', required=True)
parser.add_argument('--capture', type=Path)
args = parser.parse_args()
user = ctypes.WinDLL('user32', use_last_error=True)
user.FindWindowW.argtypes = [wintypes.LPCWSTR, wintypes.LPCWSTR]
user.FindWindowW.restype = wintypes.HWND
user.ShowWindow.argtypes = [wintypes.HWND, ctypes.c_int]
user.SetForegroundWindow.argtypes = [wintypes.HWND]
user.GetWindowRect.argtypes = [wintypes.HWND, ctypes.POINTER(wintypes.RECT)]
hwnd = user.FindWindowW(None, args.title)
if not hwnd:
    raise RuntimeError(f'Window not found: {args.title}')
user.ShowWindow(hwnd, 9)
pyautogui.keyDown('alt')
try:
    activated = bool(user.SetForegroundWindow(hwnd))
finally:
    pyautogui.keyUp('alt')
if not activated:
    raise RuntimeError('Window activation failed')
print('foreground:', activated)
time.sleep(1)
rect = wintypes.RECT()
user.GetWindowRect(hwnd, ctypes.byref(rect))
print('window:', rect.left, rect.top, rect.right, rect.bottom)
if args.capture:
    args.capture.parent.mkdir(parents=True, exist_ok=True)
    ImageGrab.grab(bbox=(max(0, rect.left), max(0, rect.top), rect.right, rect.bottom)).save(args.capture)
    print(args.capture.resolve())
