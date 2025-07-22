# Taskbar Download progress

A Millennium plugin that displays the Steam download status on the Windows taskbar

## Features
- Displays the Steam download status on the Windows taskbar
    - This functionality is only supported on Windows
- Shutdown or run a command when a download completes
    - Right click the download indicator to use
- Pause or unpause all downloads
    - Right click the download indicator to use

## Configuration
- `<STEAM>\plugins\steam-librarian\config.json`

## Prerequisites
- [Millennium](https://steambrew.app/)

## Known issues:
- First startup is slow because of dependency installation

## Contributors

<a href="https://github.com/luthor112/steam-taskbar-progress/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=luthor112/steam-taskbar-progress" />
</a>

Made with [contrib.rocks](https://contrib.rocks).

## Troubleshooting

- If the download progress is not picked up by the plugin, try setting `use_old_detection` to `true` in `config.json`