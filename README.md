# Taskbar Download progress

A Millennium plugin that displays the Steam download status on the Windows taskbar

## Features
- Displays the Steam download status on the Windows taskbar
    - This functionality is only supported on Windows

## Configuration
- `<STEAM>\plugins\steam-librarian\config.json`

## Prerequisites
- [Millennium](https://steambrew.app/)

## Known issues:
- First startup is slow because of the dependencies

## Troubleshooting

- If the download progress is not picked up by the plugin, try setting `use_old_detection` to `true` in `config.json`