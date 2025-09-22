import Millennium, PluginUtils # type: ignore
logger = PluginUtils.Logger()

import ctypes
import json
import os
import shutil
import subprocess
import sys

if sys.platform == "win32":
    import pygetwindow
    from pytaskbr import taskbar, TBPFlag
    taskbar.HrInit()

MAX_PROGRESS = 100

completion_task = 0

def get_config():
    config_fname = os.path.join(PLUGIN_BASE_DIR, "config.json")
    if not os.path.exists(config_fname):
        defaults_fname = os.path.join(PLUGIN_BASE_DIR, "defaults.json")
        shutil.copyfile(defaults_fname, config_fname)

    with open(config_fname, "rt") as fp:
        return json.load(fp)

def run_completion_task():
    global completion_task
    if completion_task == 1:
        subprocess.Popen(["shutdown", "/s", "/t", "0"])
        completion_task = 0
    elif completion_task == 2:
        subprocess.Popen(get_config()["custom_command"])
        completion_task = 0

class Backend:
    @staticmethod
    def set_progress_percent(percent):
        global completion_task
        logger.log(f"set_progress_percent({percent})")

        if sys.platform != "win32":
            return False

        steam_hwnd = None
        for wnd in pygetwindow.getWindowsWithTitle("Steam"):
            if wnd.title == "Steam":
                steam_hwnd = wnd._hWnd

        if steam_hwnd is None:
            return False

        if percent == -1:
            taskbar.SetProgressState(steam_hwnd, TBPFlag.noProgress)
        elif percent == -2:
            taskbar.SetProgressState(steam_hwnd, TBPFlag.paused)
        elif percent == 100:
            taskbar.SetProgressState(steam_hwnd, TBPFlag.noProgress)
            ctypes.windll.user32.FlashWindow(steam_hwnd, True)
            run_completion_task()
        else:
            taskbar.SetProgressState(steam_hwnd, TBPFlag.normal)
            taskbar.setProgressValue(steam_hwnd, percent, MAX_PROGRESS)
        return True

    @staticmethod
    def get_use_old_detection():
        use_old_detection = get_config()["use_old_detection"]
        logger.log(f"get_use_old_detection() -> {use_old_detection}")
        return use_old_detection

    @staticmethod
    def set_completion_task(new_value):
        global completion_task
        logger.log(f"set_completion_task({new_value})")
        completion_task = new_value
        return True

class Plugin:
    def _front_end_loaded(self):
        logger.log("Frontend loaded")

    def _load(self):
        logger.log("Backend loaded")
        logger.log(f"Plugin base dir: {PLUGIN_BASE_DIR}")
        Millennium.ready()

    def _unload(self):
        logger.log("Unloading")
