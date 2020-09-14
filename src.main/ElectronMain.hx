import electron.main.App;
import electron.main.IpcMain;
import js.Node.__dirname;
import js.Node.process;

class ElectronMain {
	static var mainWindow : electron.main.BrowserWindow;

	static function main() {

		App.on('ready', function() {
			// Init window
			mainWindow = new electron.main.BrowserWindow({
				webPreferences: { nodeIntegration:true },
				fullscreenable: true,
				show: false,
				title: "L-Ed",
			});

			// Menu
			#if debug
			enableDebugMenu();
			#else
			mainWindow.setMenu(null);
			#end

			// Start renderer part
			mainWindow.maximize();
			mainWindow.loadURL('file://$__dirname/app.html');
			mainWindow.on('closed', function() {
				mainWindow = null;
			});

			// Misc bindings
			dn.electron.Dialogs.initMain();
			dn.electron.ElectronUpdater.initMain(mainWindow);
		});

		// For mac
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

		IpcMain.on("getAppResourceDir", function(event) {
			event.returnValue = App.getAppPath();
		});

		IpcMain.on("getExeDir", function(event) {
			event.returnValue = App.getPath("exe");
		});
	}

	#if debug
	static function enableDebugMenu() {
		var menu = electron.main.Menu.buildFromTemplate([{
			label: "Debug tools",
			submenu: cast [
				{
					label: "Reload",
					click: function() mainWindow.reload(),
					accelerator: "CmdOrCtrl+R",
				},
				{
					label: "Dev tools",
					click: function() mainWindow.webContents.toggleDevTools(),
					accelerator: "CmdOrCtrl+Shift+I",
				},
			]
		}]);

		mainWindow.setMenu(menu);
	}
	#end
}
