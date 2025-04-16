import { callable, findClassModule, findModule, Millennium } from "@steambrew/client";

// Backend functions
const set_progress_percent = callable<[{ percent: number }], boolean>('Backend.set_progress_percent');

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
    console.log("[steam-taskbar-progress] frontend startup");

    const doc = g_PopupManager.GetExistingPopup("SP Desktop_uid0");
	if (doc) {
		OnPopupCreation(doc);
	}

	g_PopupManager.AddPopupCreatedCallback(OnPopupCreation);
}
