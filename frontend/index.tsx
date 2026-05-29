import { callable, findModule, Millennium, sleep, DialogButton, IconsModule, definePlugin, Field, TextField, Toggle } from "@steambrew/client";
import React, { useState, useEffect } from "react";

// Backend functions
const set_progress_percent = callable<[{ percent: number }], boolean>('set_progress_percent');
const get_plugin_status = callable<[{}], string>('get_plugin_status');

const WaitForElement = async (sel: string, parent: Document | Element = document) =>
    [...(await Millennium.findElement(parent as Document, sel))][0];

type PluginConfig = {
    use_old_detection: boolean;
}

var pluginConfig: PluginConfig = {
    use_old_detection: false
};

async function OnPopupCreation(popup: any) {
    await sleep(10000);
    console.log("[steam-taskbar-progress] Popup created, checking...");
    if (popup.m_strName === "SP Desktop_uid0") {
        console.log("[steam-taskbar-progress] Main window found");
        const downloadStatusPlace = await WaitForElement(`div.${findModule(e => e.DownloadStatusContent).DownloadStatusContent}`, popup.m_popup.document);

        const oldDetection = pluginConfig.use_old_detection;
        if (oldDetection) {
            const downloadStatusPlaceObserver = new MutationObserver(async (mutationList, observer) => {
                void mutationList;
                void observer;

                const downloadDetails = downloadStatusPlace.querySelector(`div.${findModule(e => e.DetailedDownloadProgress).DetailedDownloadProgress}`);
                if (downloadDetails) {
                    const downloadProgressBar = await WaitForElement(`div.${findModule(e => e.AnimateProgress).AnimateProgress}`, downloadDetails) as HTMLElement;
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
    }
}

type BoolKeys = {
    [K in keyof PluginConfig]: PluginConfig[K] extends boolean ? K : never
  }[keyof PluginConfig];
  
type StringKeys = {
    [K in keyof PluginConfig]: PluginConfig[K] extends string ? K : never
}[keyof PluginConfig];

type SingleSettingProps =
  | { type: "bool"; name: BoolKeys; label: string; description: string }
  | { type: "text"; name: StringKeys; label: string; description: string };

const SingleSetting = (props: SingleSettingProps) => {
    const [boolValue, setBoolValue] = useState(false);

    const saveConfig = () => {
        localStorage.setItem("luthor112.steam-taskbar-progress.config", JSON.stringify(pluginConfig));
    };

    useEffect(() => {
        if (props.type === "bool") {
            setBoolValue(pluginConfig[props.name]);
        }
    }, []);

    if (props.type === "bool") {
        return (
            <Field label={props.label} description={props.description} bottomSeparator="standard" focusable>
                <Toggle value={boolValue} onChange={(value) => { setBoolValue(value); pluginConfig[props.name] = value; saveConfig(); }} />
            </Field>
        );
    } else if (props.type === "text") {
        return (
            <Field label={props.label} description={props.description} bottomSeparator="standard" focusable>
                <TextField defaultValue={pluginConfig[props.name]} onChange={(e: React.ChangeEvent<HTMLInputElement>) => { (pluginConfig as any)[props.name] = e.currentTarget.value; saveConfig(); }} />
            </Field>
        );
    } else {
        return (
            <div>This should not happen...</div>
        );
    }
}

const SettingsContent = () => {
    return (
        <div>
            <SingleSetting name="use_old_detection" type="bool" label="Use old detection method" description="Use the old, observer-based detection" />
            <DialogButton onClick={async (e) => {
                const statusTag = (e.target as HTMLElement).ownerDocument.createElement("div");
                statusTag.innerText = await get_plugin_status({});
                (e.target as HTMLElement).parentElement!.appendChild(statusTag);
            }}>Query Plugin Status</DialogButton>
        </div>
    );
};

export default definePlugin(async () => {
    console.log("[steam-taskbar-progress] Frontend startup");

    const rawValue = localStorage.getItem("luthor112.steam-taskbar-progress.config");
    const storedConfig: Partial<PluginConfig> = rawValue ? JSON.parse(rawValue) : {};
    pluginConfig = { ...pluginConfig, ...storedConfig };
    console.log("[steam-taskbar-progress] Merged config:", pluginConfig);

    const oldDetection = pluginConfig.use_old_detection;
    if (oldDetection) {
        Millennium.AddWindowCreateHook!(OnPopupCreation);
    } else {
        var current_download_appid = 0;

        SteamClient.Downloads.RegisterForDownloadOverview(async (event) => {
            console.log(event);
            if (event.update_appid === 0) {
                console.log("[steam-taskbar-progress] Ignoring appid 0");
            } else if (event.paused) {
                console.log("[steam-taskbar-progress] Download paused");
                await set_progress_percent({ percent: -2 });
            } else if (event.update_state as string === "Downloading") {
                console.log("[steam-taskbar-progress] Download percentage:", (event as any).overall_percent_complete);
                await set_progress_percent({ percent: (event as any).overall_percent_complete });
                current_download_appid = event.update_appid;
            } else {
                console.log("[steam-taskbar-progress] No download in progress");
                await set_progress_percent({ percent: -1 });
            }
        });

        SteamClient.Downloads.RegisterForDownloadItems(async (isDownloading, downloadItems) => {
            void isDownloading;

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

    return {
		title: "Taskbar Download progress",
		icon: <IconsModule.Settings />,
		content: <SettingsContent />,
	};
});
