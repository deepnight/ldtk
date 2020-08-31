import electron.main.App;
import electron.main.IpcMain;
import js.Node.__dirname;
import js.Node.process;

class ElectronMain {
	// Boot
	static function main() {
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
			dn.electron.ElectronUpdater.initMain(mainWindow);
		});

		App.on('window-all-closed', function() {
			App.quit();
		});


		// *** invoke/handle *****************************************************

		IpcMain.handle("appReady", function(ev) {
			// Window close button
			mainWindow.on('close', function(ev) {
				if( !dn.electron.ElectronUpdater.isIntalling ) {
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


	}
}
