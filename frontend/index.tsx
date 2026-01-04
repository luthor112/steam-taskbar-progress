import { callable, findClassModule, findModule, Millennium, Menu, MenuItem, showContextMenu, sleep, IconsModule, definePlugin, Field, TextField } from "@steambrew/client";

// Backend functions
const set_progress_percent = callable<[{ percent: number }], boolean>('set_progress_percent');
const set_completion_task = callable<[{ a_new_value: number, b_new_custom_command: string }], boolean>('set_completion_task');

const WaitForElement = async (sel: string, parent = document) =>
    [...(await Millennium.findElement(parent, sel))][0];

var pluginConfig = {
    use_old_detection: false,
    custom_command: ""
};

async function OnPopupCreation(popup: any) {
    console.log("[steam-taskbar-progress] Popup created, checking...");
    if (popup.m_strName === "SP Desktop_uid0") {
        console.log("[steam-taskbar-progress] Main window found");
        const downloadStatusPlace = await WaitForElement(`div.${findModule(e => e.DownloadStatusContent).DownloadStatusContent}`, popup.m_popup.document);

        const oldDetection = pluginConfig.use_old_detection;
        if (oldDetection) {
            const downloadStatusPlaceObserver = new MutationObserver(async (mutationList, observer) => {
                const downloadDetails = downloadStatusPlace.querySelector(`div.${findModule(e => e.DetailedDownloadProgress).DetailedDownloadProgress}`);
                if (downloadDetails) {
                    const downloadProgressBar = await WaitForElement(`div.${findModule(e => e.AnimateProgress).AnimateProgress}`, downloadDetails);
                    const fromPercent = downloadProgressBar.style.cssText.substring(downloadProgressBar.style.cssText.indexOf("--percent:"));
                    const realPercent = Number(fromPercent.substring(11, fromPercent.indexOf(";")))*100;

                    console.log("[steam-taskbar-progress] Porgress bar percentage:", realPercent);
                    await set_progress_percent({ percent: realPercent });
                } else {
                    const queueMessage = downloadStatusPlace.querySelector(`div.${findModule(e => e.Queue).Queue}`);
                    if (queueMessage && queueMessage.textContent.startsWith(findModule(e => e.BottomBar_DownloadsPaused).BottomBar_DownloadsPaused)) {
                        console.log("[steam-taskbar-progress] Download paused");
                        await set_progress_percent({ percent: -2 });
                    } else {
                        console.log("[steam-taskbar-progress] Download disappeared...");
                        await set_progress_percent({ percent: -1 });
                    }
                }
            });
            downloadStatusPlaceObserver.observe(downloadStatusPlace, { childList: true, attributes: true, subtree: true });
            console.log("[steam-taskbar-progress] Using old detection method - observer started");
        }

        // Add menu
        downloadStatusPlace.addEventListener("contextmenu", async () => {
            console.log("[steam-taskbar-progress] Right click detected, showing context menu...");
            showContextMenu(
                <Menu label="Download Options">
                    <MenuItem onClick={async () => {
                        await set_completion_task({ a_new_value: 1, b_new_custom_command: "" });
                    }}> Shutdown after completion </MenuItem>
                    <MenuItem onClick={async () => {
                        await set_completion_task({ a_new_value: 2, b_new_custom_command: pluginConfig.custom_command });
                    }}> Run custom command after completion </MenuItem>
                    <MenuItem onClick={async () => {
                        await set_completion_task({ a_new_value: 0, b_new_custom_command: "" });
                    }}> Do nothing after completion </MenuItem>
                    <MenuItem onClick={async () => {
                        SteamClient.Downloads.EnableAllDownloads(true);
                    }}> Unpause all downloads </MenuItem>
                    <MenuItem onClick={async () => {
                        SteamClient.Downloads.EnableAllDownloads(false);
                    }}> Pause all downloads </MenuItem>
                </Menu>,
                downloadStatusPlace,
                { bForcePopup: true }
            );
        });
        console.log("[steam-taskbar-progress] Registered for right click");
    }
}

const SingleSetting = (props) => {
    const saveConfig = () => {
        localStorage.setItem("luthor112.steam-taskbar-progress.config", JSON.stringify(pluginConfig));
    };

    if (props.type === "bool") {
        return (
            <Field label={props.label} description={props.description} bottomSeparator="standard" focusable>
                <input type="checkbox" defaultChecked={pluginConfig[props.name]} onChange={(e) => { pluginConfig[props.name] = e.currentTarget.checked; saveConfig(); }} />
            </Field>
        );
    } else if (props.type === "text") {
        return (
            <Field label={props.label} description={props.description} bottomSeparator="standard" focusable>
                <TextField defaultValue={pluginConfig[props.name]} onChange={(e: React.ChangeEvent<HTMLInputElement>) => { pluginConfig[props.name] = e.currentTarget.value; saveConfig(); }} />
            </Field>
        );
    }
}

const SettingsContent = () => {
    return (
        <div>
            <SingleSetting name="use_old_detection" type="bool" label="Use old detection method" description="Use the old, observer-based detection" />
            <SingleSetting name="custom_command" type="text" label="Custom command" description="Command to run on download completion" />
        </div>
    );
};

async function pluginMain() {
    console.log("[steam-taskbar-progress] Frontend startup");
    await App.WaitForServicesInitialized();
    await sleep(100);

    while (
        typeof g_PopupManager === 'undefined' ||
        typeof MainWindowBrowserManager === 'undefined'
    ) {
        await sleep(100);
    }

    const storedConfig = JSON.parse(localStorage.getItem("luthor112.steam-taskbar-progress.config"));
    pluginConfig = { ...pluginConfig, ...storedConfig };
    console.log("[steam-taskbar-progress] Merged config:", pluginConfig);

    const doc = g_PopupManager.GetExistingPopup("SP Desktop_uid0");
    if (doc) {
        OnPopupCreation(doc);
    }

    g_PopupManager.AddPopupCreatedCallback(OnPopupCreation);

    const oldDetection = pluginConfig.use_old_detection;
    if (!oldDetection) {
        var current_download_appid = 0;

        SteamClient.Downloads.RegisterForDownloadOverview(async (event) => {
            console.log(event);
            if (event.update_appid === 0) {
                console.log("[steam-taskbar-progress] Ignoring appid 0");
            } else if (event.paused) {
                console.log("[steam-taskbar-progress] Download paused");
                await set_progress_percent({ percent: -2 });
            } else if (event.update_state === "Downloading") {
                console.log("[steam-taskbar-progress] Download percentage:", event.overall_percent_complete);
                await set_progress_percent({ percent: event.overall_percent_complete });
                current_download_appid = event.update_appid;
            } else {
                console.log("[steam-taskbar-progress] No download in progress");
                await set_progress_percent({ percent: -1 });
            }
        });

        SteamClient.Downloads.RegisterForDownloadItems(async (isDownloading, downloadItems) => {
            const current_app = downloadItems.find((el) => el.appid === current_download_appid);
            if (current_app) {
                if (current_app.completed) {
                    await set_progress_percent({ percent: 100 });
                    current_download_appid = 0;
                }
            }
        });

        console.log("[steam-taskbar-progress] Using new detection method - registered for download events");
    }
}

export default definePlugin(async () => {
    await pluginMain();
    return {
		title: "Taskbar Download progress",
		icon: <IconsModule.Settings />,
		content: <SettingsContent />,
	};
});
