import Millennium, PluginUtils # type: ignore
logger = PluginUtils.Logger()

import sys

if sys.platform == "win32":
    import pygetwindow
    import PyTaskbar

class Backend:
    @staticmethod
    def set_progress_percent(percent):
        logger.log(f"set_progress_percent({percent})")

        if sys.platform != "win32":
            return False

        steam_hwnd = None
        for wnd in pygetwindow.getWindowsWithTitle("Steam"):
            if wnd.title == "Steam":
                steam_hwnd = wnd._hWnd

        if steam_hwnd is None:
            return False

        progress = PyTaskbar.Progress(steam_hwnd)
        progress.init()

        if percent == -1:
            progress.setProgress(0)
            progress.setState('normal')
        elif percent == 100:
            progress.setProgress(0)
            progress.setState('done')
        else:
            progress.setProgress(percent)
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
