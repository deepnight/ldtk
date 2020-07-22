const { app, BrowserWindow, dialog, ipcMain } = require('electron')

function createWindow () {
	// Create the browser window.
	const win = new BrowserWindow({
		width: 800,
		height: 600,
		webPreferences: { nodeIntegration: true }
	});

	ipcMain.handle("open-file-dialog", async(event,path) => {
		dialog.showOpenDialog({ title:"hello" });
	});

	// and load the index.html of the app.
	win.loadFile('app.html');

	// Open the DevTools.
	win.webContents.openDevTools();
}

app.whenReady().then( createWindow );