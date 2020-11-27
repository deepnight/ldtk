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
				title: "LDtk",
				icon: __dirname+"/appIcon.png",
				backgroundColor: '#1e2229'
			});

			mainWindow.on('closed', function() {
				mainWindow = null;
			});

			// Menu
			#if debug
			enableDebugMenu();
			#else
			mainWindow.setMenu(null);
			#end

			// Prepare splash window
			#if !debug
			var splash = new electron.main.BrowserWindow({
				width: 600,
				height: 400,
				alwaysOnTop: true,
				transparent: true,
				frame: false,
			});
			splash.loadURL('file://$__dirname/splash.html');
			#end

			// Load app page
			var p = mainWindow.loadURL('file://$__dirname/app.html');
			#if debug
			mainWindow.maximize();
			#else
			p.then( (_)->{
				// Display window when ready
				mainWindow.maximize();
				splash.destroy();
			});
			#end

			// Misc bindings
			dn.electron.Dialogs.initMain(mainWindow);
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

		IpcMain.on("getArgs", function(event) {
			event.returnValue = process.argv;
		});

		IpcMain.on("getAppResourceDir", function(event) {
			event.returnValue = App.getAppPath();
		});

		IpcMain.on("getExeDir", function(event) {
			event.returnValue = App.getPath("exe");
		});

		IpcMain.on("getUserDataDir", function(event) {
			event.returnValue = App.getPath("userData");
		});
	}


	#if debug
	// Create a custom debug menu
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
