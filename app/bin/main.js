'use strict';
const { app, BrowserWindow, dialog, ipcMain } = require('electron');
const { autoUpdater } = require('electron-updater');

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
		ev.preventDefault();
		mainWindow.webContents.send("winClose");
    });
});



// *** Async handlers *****************************************************

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
	autoUpdater.checkForUpdatesAndNotify();
});


// *** Sync handlers *****************************************************

ipcMain.on("getCwd", function(event) {
	event.returnValue = process.cwd();
});

ipcMain.on("getAppDir", function(event) {
	event.returnValue = app.getAppPath();
});

ipcMain.on("getAppResources", function(event) {
	event.returnValue = process.resourcesPath;
});

// *** Auto-updater handlers *****************************************************

autoUpdater.on('update-available', () => {
	mainWindow.webContents.send('update_available');
});

autoUpdater.on('update-downloaded', () => {
	mainWindow.webContents.send('update_downloaded');
});