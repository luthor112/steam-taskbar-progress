import { callable, Millennium } from "@steambrew/client";

// Backend functions
const set_progress_percent = callable<[{ percent: number }], boolean>('Backend.set_progress_percent');

export default async function PluginMain() {
    console.log("[steam-taskbar-progress] frontend startup");

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
