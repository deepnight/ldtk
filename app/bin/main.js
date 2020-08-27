'use strict';
const { app, BrowserWindow, dialog, ipcMain } = require('electron');
const { autoUpdater } = require('electron-updater');

var hasDownloadedUpdate = false;
var isInstallingUpdate = false;

// *** Main app *****************************************************

app.on('window-all-closed', () => {
	if (process.platform !== 'darwin') app.quit();
});

let mainWindow = null;
app.on('ready', () => {
	mainWindow = new BrowserWindow({
		webPreferences: { nodeIntegration:true },
		fullscreenable: true,
		autoHideMenuBar: true,
		show: false,
		title: "L-Ed",
	});
	mainWindow.loadURL(`file://${__dirname}/app.html`);
	mainWindow.on('closed', () => { mainWindow = null; });


	mainWindow.maximize();

	// Window close button
    mainWindow.on('close', function(ev) {
		if( !isInstallingUpdate ) {
			ev.preventDefault();
			mainWindow.webContents.send("winClose");
		}
    });
});



// *** Async invoke() handlers *****************************************************

ipcMain.handle("loadFile", async function(event, options) {
	console.log(options);
	var filePaths = dialog.showOpenDialogSync(null, options);
	return filePaths===undefined ? null : filePaths[0];
});

ipcMain.handle("saveAs", async function(event, options) {
	var filePaths = dialog.showSaveDialogSync(null, options);
	return filePaths===undefined ? null : filePaths;
});

ipcMain.handle("exit", async function(event) {
	app.exit();
});

ipcMain.handle("setFullScreen", function(event,args) {
	mainWindow.setFullScreen(args);
});

ipcMain.handle("setWinTitle", function(event,args) {
	mainWindow.title = args;
});

ipcMain.handle("checkUpdate", function(event,args) {
	console.log("checking...");
	autoUpdater.checkForUpdates();
	autoUpdater.on('update-available', (info) => {
		mainWindow.webContents.send('updateFound');
	})
	autoUpdater.on('update-downloaded', (info) => {
		mainWindow.webContents.send('updateReady');
		hasDownloadedUpdate = true;
	})
});

ipcMain.handle("installUpdate", function(event) {
	console.log("install");
	isInstallingUpdate = true;
	autoUpdater.quitAndInstall();
});


// *** Sync send() handlers *****************************************************

ipcMain.on("getCwd", function(event) {
	event.returnValue = process.cwd();
});

ipcMain.on("getAppDir", function(event) {
	event.returnValue = app.getAppPath();
});

