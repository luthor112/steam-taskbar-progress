import { callable, findClassModule, findModule, Millennium } from "@steambrew/client";

// Backend functions
const set_progress_percent = callable<[{ percent: number }], boolean>('Backend.set_progress_percent');
const get_use_old_detection = callable<[{}], boolean>('Backend.get_use_old_detection');

const WaitForElement = async (sel: string, parent = document) =>
	[...(await Millennium.findElement(parent, sel))][0];

async function OnPopupCreation(popup: any) {
    if (popup.m_strName === "SP Desktop_uid0") {
        const downloadStatusPlace = await WaitForElement(`div.${findModule(e => e.DownloadStatusContent).DownloadStatusContent}`, popup.m_popup.document);
        const downloadStatusPlaceObserver = new MutationObserver(async (mutationList, observer) => {
            const downloadDetails = downloadStatusPlace.querySelector(`div.${findModule(e => e.DetailedDownloadProgress).DetailedDownloadProgress}`);
            if (downloadDetails) {
                const downloadProgressBar = await WaitForElement(`div.${findModule(e => e.AnimateProgress).AnimateProgress}`, downloadDetails);
                const fromPercent = downloadProgressBar.style.cssText.substring(downloadProgressBar.style.cssText.indexOf("--percent:"));
                const realPercent = Number(fromPercent.substring(11, fromPercent.indexOf(";")))*100;

                console.log("[steam-taskbar-progress] Porgress bar percentage:", realPercent);
                await set_progress_percent({ percent: realPercent });
            } else {
                console.log("[steam-taskbar-progress] Download disappeared...");
                await set_progress_percent({ percent: -1 });
            }
        });
        downloadStatusPlaceObserver.observe(downloadStatusPlace, { childList: true, attributes: true, subtree: true });
    }
}

export default async function PluginMain() {
    console.log("[steam-taskbar-progress] Frontend startup");

    const oldDetection = await get_use_old_detection({});
    console.log("[steam-taskbar-progress] Use old detection method:", oldDetection);

    if (oldDetection) {
        const doc = g_PopupManager.GetExistingPopup("SP Desktop_uid0");
        if (doc) {
            OnPopupCreation(doc);
        }

        g_PopupManager.AddPopupCreatedCallback(OnPopupCreation);
    } else {
        SteamClient.Downloads.RegisterForDownloadOverview(async (event) => {
            if (event.update_state === "Downloading") {
                console.log("[steam-taskbar-progress] Download percentage:", event.overall_percent_complete);
                await set_progress_percent({ percent: event.overall_percent_complete });
            } else {
                console.log("[steam-taskbar-progress] No download in progress");
                await set_progress_percent({ percent: -1 });
            }
        });
    }
}
