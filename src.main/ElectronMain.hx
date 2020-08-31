import electron.main.App;
import electron.main.IpcMain;
import js.Node.__dirname;
import js.Node.process;

class ElectronMain {
	// Boot
	static function main() {
		var hasDownloadedUpdate = false;
		var isInstallingUpdate = false;

		var mainWindow : electron.main.BrowserWindow = null;
		App.on('ready', function() {
			// Init window
			mainWindow = new electron.main.BrowserWindow({
				webPreferences: { nodeIntegration:true },
				fullscreenable: true,
				autoHideMenuBar: true,
				show: false,
				title: "L-Ed",
			});
			mainWindow.loadURL('file://$__dirname/app.html');
			mainWindow.on('closed', function() {
				mainWindow = null;
			});
			mainWindow.maximize();

			dn.electron.Dialogs.initMain();
		});

		App.on('window-all-closed', function() {
			App.quit();
		});


		// *** invoke/handle *****************************************************

		IpcMain.handle("appReady", function(ev) {
			// Window close button
			mainWindow.on('close', function(ev) {
				if( !isInstallingUpdate ) {
					ev.preventDefault();
					mainWindow.webContents.send("winClose");
				}
			});
		});

		IpcMain.handle("exitApp", function(event) {
			App.exit();
		});

		IpcMain.handle("setFullScreen", function(event,args) {
			mainWindow.setFullScreen(args);
		});

		IpcMain.handle("setWinTitle", function(event,args) {
			mainWindow.title = args;
		});


		// *** sendSync/on *****************************************************

		IpcMain.on("getCwd", function(event) {
			event.returnValue = process.cwd();
		});

		IpcMain.on("getAppDir", function(event) {
			event.returnValue = App.getAppPath();
		});


		// *** electron-updater handlers *****************************************************

		var autoUpdater : electronUpdater.AutoUpdater = js.node.Require.require("electron-updater").autoUpdater;
		var checking = false;
		IpcMain.handle("checkUpdate", function(event,args) {
			checking = true;
			js.html.Console.log("Checking for updates...");
			autoUpdater.checkForUpdates();
			autoUpdater.on('update-available', function(info) {
				checking = false;
				js.html.Console.log("Update found!");
				mainWindow.webContents.send('updateChecked');
				mainWindow.webContents.send('updateFound', info.version);
			});
			autoUpdater.on('error', function(_) {
				if( checking )
					mainWindow.webContents.send('updateError');
				checking = false;
			});
			autoUpdater.on('update-not-available', function(info) {
				checking = false;
				mainWindow.webContents.send('updateChecked');
			});
			autoUpdater.on('update-downloaded', function(info) {
				js.html.Console.log("Update ready!");
				mainWindow.webContents.send('updateReady');
				hasDownloadedUpdate = true;
			});
		});

		IpcMain.handle("installUpdate", function(event) {
			js.html.Console.log("Installing update...");
			isInstallingUpdate = true;
			autoUpdater.quitAndInstall();
		});


	}
}
