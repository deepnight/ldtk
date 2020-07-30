'use strict';
const { app, BrowserWindow, dialog, ipcMain } = require('electron');

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
	});
	mainWindow.maximize();
	mainWindow.loadURL(`file://${__dirname}/app.html`);
	mainWindow.on('closed', () => { mainWindow = null; });
});



// *** Async handlers *****************************************************

ipcMain.handle("loadFile", async function(event) {
	var filePaths = dialog.showOpenDialogSync();
	return filePaths===undefined ? null : filePaths[0];
});

ipcMain.handle("exit", async function(event) {
	app.exit();
});

ipcMain.handle("setFullScreen", function(event,args) {
	mainWindow.setFullScreen(args);
});


// *** Sync handlers *****************************************************

ipcMain.on("getAppCwd", function(event) {
	event.returnValue = app.getAppPath();
});
