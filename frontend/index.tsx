import { callable, IconsModule, definePlugin, pluginSelf, DownloadItem } from '@steambrew/client';

const setTaskbarProgressPercentage = callable<[{ percent: number }], boolean>('set_progress_percent');

async function onDownloadOverview(event: any) {
	console.log("[steam-taskbar-progress] onDownloadOverview:", event);
	const state: string = event.update_state;

	console.log('[steam-taskbar-progress] Appid: ', event.update_appid);

	if (event.update_appid === 0) {
		console.log('[steam-taskbar-progress] Ignoring appid 0');
		return;
	}

	if (event.paused) {
		console.log('[steam-taskbar-progress] Download paused');
		await setTaskbarProgressPercentage({ percent: -2 });
		return;
	}

	if (state === 'Downloading' || state === 'Updating' || state === 'Patching' || state === 'Installing') {
		const percent: number = (event as any).overall_percent_complete;

		console.log('[steam-taskbar-progress] Download percentage:', percent);
		await setTaskbarProgressPercentage({ percent });
		pluginSelf.current_download_appid = event.update_appid;
		return;
	}

	console.log('[steam-taskbar-progress] No download in progress');
	await setTaskbarProgressPercentage({ percent: -1 });
}

async function onDownloadItems(isDownloading: boolean, downloadItems: any) {
	//void isDownloading;
	console.log("[steam-taskbar-progress] onDownloadItems isDownloading:", isDownloading);
	console.log("[steam-taskbar-progress] onDownloadItems downloadItems:", downloadItems);

	const current_app_item = downloadItems.find((el: any) => (el.item_data[0] as DownloadItem).appid === pluginSelf.current_download_appid);
	if (current_app_item) {
		const current_app = current_app_item.item_data[0] as DownloadItem;
		if (current_app.completed) {
			await setTaskbarProgressPercentage({ percent: 100 });
			pluginSelf.current_download_appid = 0;
		}
	}
}

export default definePlugin(async () => {
	console.log('[steam-taskbar-progress] Frontend startup');
	SteamClient.Downloads.RegisterForDownloadOverview(onDownloadOverview);
	SteamClient.Downloads.RegisterForDownloadItems(onDownloadItems);

	return {
		title: 'Taskbar Download progress',
		icon: <IconsModule.Settings />,
	};
});
