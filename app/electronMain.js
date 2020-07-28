'use strict';
const {app, BrowserWindow, dialog, ipcMain} = require('electron');
const url = require('url')
const path = require('path')
let mainWindow = null;

// *** Main app *****************************************************

app.on('window-all-closed', () => {
	if (process.platform !== 'darwin') app.quit();
});

app.on('ready', () => {
	mainWindow = new BrowserWindow({
		webPreferences: { nodeIntegration:true }
	});
	mainWindow.loadURL(`file://${__dirname}/app.html`);
	mainWindow.on('closed', () => { mainWindow = null; });
});



// *** Dialog handlers *****************************************************

ipcMain.handle("loadFile", async function(event) {
	var filePaths = dialog.showOpenDialogSync();
	return filePaths===undefined ? null : filePaths[0];
});

