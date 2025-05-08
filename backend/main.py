import Millennium, PluginUtils # type: ignore
logger = PluginUtils.Logger()

import json
import os
import sys

if sys.platform == "win32":
    import pygetwindow
    import PyTaskbar

warning_status = False
last_steam_hwnd = 0
progress = None

def get_config():
    with open(os.path.join(PLUGIN_BASE_DIR, "config.json"), "rt") as fp:
        return json.load(fp)

class Backend:
    @staticmethod
    def set_progress_percent(percent):
        global warning_status
        global last_steam_hwnd
        global progress
        logger.log(f"set_progress_percent({percent})")

        if sys.platform != "win32":
            return False

        steam_hwnd = None
        for wnd in pygetwindow.getWindowsWithTitle("Steam"):
            if wnd.title == "Steam":
                steam_hwnd = wnd._hWnd

        if steam_hwnd is None:
            last_steam_hwnd = 0
            return False

        if steam_hwnd != last_steam_hwnd:
            progress = PyTaskbar.Progress(steam_hwnd)
            progress.init()
            last_steam_hwnd = steam_hwnd

        if percent == -1:
            progress.setProgress(0)
            progress.setState('normal')
            warning_status = False
        elif percent == -2:
            progress.setState('warning')
            warning_status = True
        elif percent == 100:
            progress.setProgress(0)
            progress.setState('done')
            warning_status = False
        else:
            if warning_status:
                progress.setState('normal')
                warning_status = False
            progress.setProgress(percent)
        return True

    @staticmethod
    def get_use_old_detection():
        use_old_detection = get_config()["use_old_detection"]
        logger.log(f"get_use_old_detection() -> {use_old_detection}")
        return use_old_detection

class Plugin:
    def _front_end_loaded(self):
        logger.log("Frontend loaded")

    def _load(self):
        logger.log("Backend loaded")
        logger.log(f"Plugin base dir: {PLUGIN_BASE_DIR}")
        Millennium.ready()

    def _unload(self):
        logger.log("Unloading")
