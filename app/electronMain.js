'use strict';
const electron = require('electron');
let mainWindow = null;

electron.app.on('window-all-closed', () => {
	if (process.platform !== 'darwin') electron.app.quit();
});

electron.app.on('ready', () => {
	mainWindow = new electron.BrowserWindow({
		webPreferences: { nodeIntegration:true }
	});
	mainWindow.loadURL(`file://${__dirname}/app.html`);
	mainWindow.on('closed', () => { mainWindow = null; });
});

