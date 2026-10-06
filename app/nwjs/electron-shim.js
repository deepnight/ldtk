// nwjs host shim for the LDtk renderer.
//
// The renderer bundle (assets/js/renderer.js) is Electron-agnostic except for
// require("electron") / require("electron-updater") and the IPC channels served
// by ElectronMain (via dn.js.ElectronTools / ElectronDialogs / ElectronUpdater).
// This file provides both modules backed by nwjs APIs and serves those channels
// in-window, so the unmodified renderer runs inside nw (e.g. hosted from Hide).
// The standalone Electron build is unaffected.
(function() {
"use strict";

const nodeRequire = require;
const path = nodeRequire("path");
const fs = nodeRequire("fs");
const os = nodeRequire("os");
const Module = nodeRequire("module");

const q = new URLSearchParams(location.search);
const HOST_DIR = path.dirname(decodeURIComponent(location.pathname));
const APP_DIR = path.dirname(HOST_DIR); // ldtk/app
const ASSETS_DIR = path.join(APP_DIR, "assets");
const PROJECT = q.get("project"); // absolute path of a .ldtk to open
// embedded in a host tab (e.g. a Hide view) instead of owning its nw window:
// window-level ops degrade to in-page/postMessage equivalents
const EMBEDDED = q.get("embed") === "1";

function toHost(msg) {
	// iframe host; harmless no-op under webview (parent === self)
	try { if (window.parent && window.parent !== window) window.parent.postMessage(Object.assign({ ldtk: true }, msg), "*"); } catch (e) {}
}

// Same location as Electron's app.getPath("userData") for LDtk, so settings and
// recent projects are shared with the standalone app
const USER_DATA_DIR =
	process.platform === "win32"
		? path.join(process.env.APPDATA || path.join(os.homedir(), "AppData", "Roaming"), "LDtk")
		: process.platform === "darwin"
			? path.join(os.homedir(), "Library", "Application Support", "LDtk")
			: path.join(process.env.XDG_CONFIG_HOME || path.join(os.homedir(), ".config"), "LDtk");

// In embedded mode nw.Window.get() would return the HOST's window (e.g. Hide
// itself) — never drive it from here
const win = EMBEDDED ? null : nw.Window.get();
let zoomFactor = 1;

// ---- main->renderer event bus ---------------------------------------------
const ipcListeners = new Map();
function emit(channel, ...args) {
	for (const f of ipcListeners.get(channel) || [])
		try { f({}, ...args); } catch (e) { console.error("[shim]", channel, e); }
}

// ---- async file dialogs via nw file inputs ---------------------------------
function fileDialog(opts, save) {
	return new Promise(resolve => {
		const input = document.createElement("input");
		input.type = "file";
		opts = opts || {};
		if (save) input.setAttribute("nwsaveas", opts.defaultPath ? path.basename(opts.defaultPath) : "");
		if (opts.properties && opts.properties.indexOf("openDirectory") >= 0)
			input.setAttribute("nwdirectory", "");
		if (opts.defaultPath) {
			let dir = opts.defaultPath;
			try { if (!fs.statSync(dir).isDirectory()) dir = path.dirname(dir); }
			catch (e) { dir = path.dirname(dir); }
			input.setAttribute("nwworkingdir", dir);
		}
		if (opts.filters) {
			const exts = [];
			for (const f of opts.filters)
				for (const e of f.extensions || [])
					if (e !== "*") exts.push("." + e);
			if (exts.length > 0) input.accept = exts.join(",");
		}
		input.style.display = "none";
		document.body.appendChild(input);
		let done = false;
		const finish = v => { if (!done) { done = true; input.remove(); resolve(v); } };
		input.addEventListener("change", () => finish(input.value || null));
		input.addEventListener("cancel", () => finish(null));
		// no reliable cancel event pre-Chrome 113; also resolve null on refocus without change
		window.addEventListener("focus", () => setTimeout(() => finish(input.value || null), 1000), { once: true });
		input.click();
	});
}

// ---- ElectronTools / ElectronDialogs channels ------------------------------
// sendSync() channels
const sync = {
	getScreenWidth: () => window.screen.width,
	getScreenHeight: () => window.screen.height,
	getZoom: () => zoomFactor,
	getPixelRatio: () => window.devicePixelRatio,
	// dn.Args shifts off the exe path
	getRawArgs: () => (PROJECT ? ["nwjs", PROJECT] : ["nwjs"]),
	getAppResourceDir: () => APP_DIR,
	getExeDir: () => path.dirname(process.execPath),
	getLogDir: () => {
		const d = path.join(USER_DATA_DIR, "logs");
		try { fs.mkdirSync(d, { recursive: true }); } catch (e) {}
		return d;
	},
	getUserDataDir: () => {
		try { fs.mkdirSync(USER_DATA_DIR, { recursive: true }); } catch (e) {}
		return USER_DATA_DIR;
	},
	isFullScreen: () => (EMBEDDED ? !!document.fullscreenElement : !!win.isFullscreen),
	isDevToolsOpened: () => false,
	isThrottlingEnabled: () => false,
	locate: (p, isFile) => {
		try { isFile ? nw.Shell.showItemInFolder(p) : nw.Shell.openItem(p); } catch (e) {}
		return null;
	},
};

// invoke() channels
const handlers = {
	exitApp: () => {
		if (EMBEDDED) { toHost({ type: "exit" }); try { window.close(); } catch (e) {} }
		else win.close(true);
	},
	reloadWindow: () => location.reload(),
	toggleDevTools: () => { if (win) win.showDevTools(); },
	openDevTools: () => { if (win) win.showDevTools(); },
	closeDevTools: () => { try { if (win) win.closeDevTools(); } catch (e) {} },
	setFullScreen: flag => {
		if (EMBEDDED) {
			if (flag) document.documentElement.requestFullscreen().catch(() => {});
			else if (document.fullscreenElement) document.exitFullscreen();
		} else flag ? win.enterFullscreen() : win.leaveFullscreen();
	},
	setWindowTitle: t => {
		document.title = t;
		if (EMBEDDED) toHost({ type: "title", title: t });
		else try { win.title = t; } catch (e) {}
	},
	minimize: () => { if (win) win.minimize(); },
	showWindow: () => { if (win) win.show(); },
	hideWindow: () => { if (win) win.hide(); },
	fatalError: msg => { window.alert("FATAL: " + msg); win.close(true); },
	showError: (title, msg) => window.alert(title + "\n\n" + msg),
	disableThrottling: () => {},
	enableThrottling: () => {},
	openDialog: opts => fileDialog(opts, false),
	saveAsDialog: opts => fileDialog(opts, true),
	// dn.js.ElectronUpdater: pretend the check ran and found nothing
	checkOnly: () => { setTimeout(() => emit("updateNotFound"), 50); },
	checkAndInstall: () => { setTimeout(() => emit("updateNotFound"), 50); },
	download: () => {},
	quitAndInstall: () => {},
};

const ipcRenderer = {
	sendSync(ch, ...a) {
		const f = sync[ch];
		if (!f) { console.warn("[shim] unhandled sendSync:", ch); return null; }
		return f(...a);
	},
	invoke(ch, ...a) {
		const f = handlers[ch] || sync[ch];
		if (!f) { console.warn("[shim] unhandled invoke:", ch); return Promise.resolve(null); }
		return Promise.resolve(f(...a));
	},
	send(ch, ...a) { this.invoke(ch, ...a); },
	on(ch, fn) {
		if (!ipcListeners.has(ch)) ipcListeners.set(ch, []);
		ipcListeners.get(ch).push(fn);
		return this;
	},
	once(ch, fn) {
		const wrap = (...a) => { this.removeListener(ch, wrap); fn(...a); };
		return this.on(ch, wrap);
	},
	removeListener(ch, fn) {
		const l = ipcListeners.get(ch);
		if (l) { const i = l.indexOf(fn); if (i >= 0) l.splice(i, 1); }
		return this;
	},
	removeAllListeners(ch) { ipcListeners.delete(ch); return this; },
};

const clipboard = {
	readText: () => { try { return nw.Clipboard.get().get("text") || ""; } catch (e) { return ""; } },
	writeText: t => { try { nw.Clipboard.get().set(t, "text"); } catch (e) {} },
	write: data => {
		try {
			if (data && data.text != null) nw.Clipboard.get().set(data.text, "text");
			else if (data && data.image != null) nw.Clipboard.get().set(data.image, "png");
		} catch (e) {}
	},
	readImage: () => { try { return nw.Clipboard.get().get("png"); } catch (e) { return null; } },
	availableFormats: () => { try { return nw.Clipboard.get().readAvailableTypes(); } catch (e) { return []; } },
};

const shell = {
	openExternal: url => { try { nw.Shell.openExternal(url); } catch (e) {} },
	showItemInFolder: p => { try { nw.Shell.showItemInFolder(p); } catch (e) {} },
	openPath: p => { try { nw.Shell.openItem(p); } catch (e) {} },
};

const webFrame = {
	setZoomFactor: z => {
		zoomFactor = z;
		// embedded: never touch the host window's zoom, scale our own document
		if (EMBEDDED) document.documentElement.style.zoom = z;
		else try { win.zoomLevel = Math.log(z) / Math.log(1.2); } catch (e) {}
	},
	getZoomFactor: () => zoomFactor,
};

const screenStub = {
	getPrimaryDisplay: () => ({
		size: { width: window.screen.width, height: window.screen.height },
		scaleFactor: window.devicePixelRatio,
	}),
};

// Renderer's top-level destructure also grabs main-process members (app,
// dialog, ipcMain, Menu, powerSaveBlocker); they're never called in-renderer,
// so undefined members are fine.
const electronModule = { ipcRenderer, clipboard, shell, webFrame, screen: screenStub };

const electronUpdaterModule = {
	autoUpdater: {
		on() { return this; },
		checkForUpdates() { return Promise.resolve(null); },
		downloadUpdate() { return Promise.resolve(null); },
		quitAndInstall() {},
		autoDownload: false,
		autoInstallOnAppQuit: false,
		logger: null,
	},
};

// ---- host data bridge -------------------------------------------------------
// The host (e.g. the Hide plugin) can hand over live data — typically its
// unsaved in-memory cdb — so LDtk reads that instead of the stale file:
// 1. same node context (same-process host): global.__hideLdtkBridge =
//    { readFile(absPath) -> String|null }
// 2. cross-process (webview guest): URL params bridgeSrc=<real db path> &
//    bridgeFile=<temp dump path>; reads of bridgeSrc are served from bridgeFile
//    (kept fresh by the host).
const BRIDGE_SRC = q.get("bridgeSrc") ? path.resolve(q.get("bridgeSrc")) : null;
const BRIDGE_FILE = q.get("bridgeFile");

function bridgeRead(p) {
	p = path.resolve(String(p));
	try {
		if (global.__hideLdtkBridge) {
			const v = global.__hideLdtkBridge.readFile(p);
			if (v != null) return v;
		}
	} catch (e) {}
	if (BRIDGE_SRC != null && BRIDGE_FILE != null && p === BRIDGE_SRC) {
		try { return realFs.readFileSync(BRIDGE_FILE, "utf8"); }
		catch (e) { console.error("[shim] bridge file read failed", e); }
	}
	return null;
}

const realFs = fs;
const patchedFs = Object.create(realFs);
patchedFs.readFileSync = function(p, opts) {
	const v = bridgeRead(p);
	if (v != null) return (opts && (opts === "utf8" || opts.encoding)) ? v : Buffer.from(v, "utf8");
	return realFs.readFileSync(p, opts);
};
patchedFs.readFile = function(p, opts, cb) {
	if (typeof opts === "function") { cb = opts; opts = undefined; }
	const v = bridgeRead(p);
	if (v != null) {
		const out = (opts && (opts === "utf8" || opts.encoding)) ? v : Buffer.from(v, "utf8");
		setTimeout(() => cb(null, out), 0);
		return;
	}
	return realFs.readFile(p, opts, cb);
};

// ---- require() override -----------------------------------------------------
// codemirror/sortablejs/simple-color-picker resolve from app/node_modules;
// app.html's final require('./js/jquery.min.js') resolves against assets/
const localRequire = Module.createRequire(path.join(APP_DIR, "package.json"));
window.require = function(name) {
	if (name === "electron") return electronModule;
	if (name === "electron-updater") return electronUpdaterModule;
	if (name === "fs") return patchedFs;
	if (name.startsWith("./") || name.startsWith("../")) return localRequire(path.join(ASSETS_DIR, name));
	return localRequire(name);
};

// ---- window lifecycle -------------------------------------------------------
// LDtk's save-check flow runs on onWinClose and calls exitApp when done
if (!EMBEDDED) {
	let closing = false;
	win.on("close", () => {
		if (closing) { win.close(true); return; }
		closing = true;
		if (ipcListeners.has("onWinClose")) emit("onWinClose");
		else win.close(true);
		// let the flow be cancelled (LastChance modal)
		setTimeout(() => { closing = false; }, 500);
	});
	win.on("move", () => emit("onWinMove"));
}

// ElectronMain maximizes the main window on startup
if (!EMBEDDED) win.maximize();

// ElectronMain sends this after ready-to-show
window.addEventListener("load", () => setTimeout(() => emit("settingsApplied"), 100));
})();
