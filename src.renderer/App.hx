import electron.renderer.IpcRenderer;

class App extends dn.Process {
	public static var ME : App;
	public static var LOG : dn.Log = new dn.Log( #if debug 1000 #else 500 #end );
	public static var APP_RESOURCE_DIR = "./"; // with trailing slash
	public static var APP_ASSETS_DIR(get,never) : String;
		static inline function get_APP_ASSETS_DIR() return APP_RESOURCE_DIR+"assets/";

	public var jDoc(get,never) : J; inline function get_jDoc() return new J(js.Browser.document);
	public var jBody(get,never) : J; inline function get_jBody() return new J("body");
	public var jPage(get,never) : J; inline function get_jPage() return new J("#page");
	public var jCanvas(get,never) : J; inline function get_jCanvas() return new J("#webgl");

	public var lastKnownMouse : { pageX:Int, pageY:Int };
	var curPageProcess : Null<Page>;
	public var session : SessionData;
	var keyDowns : Map<Int,Bool> = new Map();


	public function new() {
		super();

		// Init logging
		LOG.logFilePath = JsTools.getExeDir()+"/LEd.log";
		LOG.trimFileLines();
		LOG.emptyEntry();
		#if debug
		LOG.printOnAdd = true;
		#end

		ME = this;
		createRoot(Boot.ME.s2d);
		lastKnownMouse = { pageX:0, pageY:0 }
		jCanvas.hide();
		clearMiniNotif();

		LOG.add("BOOT","App started");
		LOG.tagColors.set("tidy", "#8ed1ac");

		// Init window
		IpcRenderer.on("winClose", onWindowCloseButton);

		var win = js.Browser.window;
		win.onblur = onAppBlur;
		win.onfocus = onAppFocus;
		win.onresize = onAppResize;
		win.onmousemove = onAppMouseMove;
		win.onerror = (msg, url, lineNo, columnNo, error:js.lib.Error)->{
			trace(msg);
			trace(url);
			trace(lineNo);
			trace(columnNo);
			trace(error);
			trace(error.stack);
			new ui.modal.dialog.CrashReport(error);
			return false;
		}

		// Keyboard events
		jBody
			.on("keydown", onJsKeyDown )
			.on("keyup", onJsKeyUp );
		Boot.ME.s2d.addEventListener(onHeapsEvent);

		// Init dirs
		var fp = dn.FilePath.fromDir( JsTools.getAppResourceDir() );
		fp.useSlashes();
		APP_RESOURCE_DIR = fp.directoryWithSlash;

		// Restore last stored project state
		LOG.general("Loading session");
		session = {
			recentProjects: [],
		}
		session = dn.LocalStorage.readObject("session", session);

		// Auto updater
		miniNotif("Checking for update...", true);
		dn.electron.ElectronUpdater.initRenderer();
		dn.electron.ElectronUpdater.onUpdateCheckStart = function() {
			miniNotif("Looking for update...");
			LOG.network("Looking for update");
		}
		dn.electron.ElectronUpdater.onUpdateFound = function(info) {
			LOG.network("Found update: "+info.version+" ("+info.releaseDate+")");
			miniNotif('Downloading ${info.version}...');
		}
		dn.electron.ElectronUpdater.onUpdateNotFound = function() miniNotif('App is up-to-date.');
		dn.electron.ElectronUpdater.onError = function() {
			LOG.error("Couldn't check for updates");
			miniNotif("Can't check for updates");
		}
		dn.electron.ElectronUpdater.onUpdateDownloaded = function(info) {
			LOG.network("Update ready: "+info.version);
			miniNotif('Update ${info.version} ready!');

			var e = jBody.find("#updateInstall");
			e.show();
			var bt = e.find("button");
			bt.off().empty();
			bt.append('<strong>Install update</strong>');
			bt.append('<em>Version ${info.version}</em>');
			bt.click(function(_) {
				function applyUpdate() {
					LOG.general("Installing update");
					bt.remove();

					loadPage( ()->new page.Updating() );
					delayer.addS(function() {
						IpcRenderer.invoke("installUpdate");
					}, 1);
				}

				if( Editor.ME!=null && Editor.ME.needSaving )
					new ui.modal.dialog.UnsavedChanges(applyUpdate);
				else
					applyUpdate();
			});
		}
		dn.electron.ElectronUpdater.checkNow();

		// Start
		loadPage( ()->new page.Home() );

		IpcRenderer.invoke("appReady");
	}


	function onHeapsEvent(e:hxd.Event) {
		switch e.kind {
			case EKeyDown: onHeapsKeyDown(e);
			case EKeyUp: onHeapsKeyUp(e);
			case _:
		}
	}



	function onJsKeyDown(ev:js.jquery.Event) {
		if( ev.keyCode==K.TAB && !ui.Modal.hasAnyOpen() )
			ev.preventDefault();

		if( ev.keyCode==K.ALT )
			ev.preventDefault();

		keyDowns.set(ev.keyCode, true);
		onKeyPress(ev.keyCode);
	}

	function onJsKeyUp(ev:js.jquery.Event) {
		keyDowns.remove(ev.keyCode);
	}

	function onHeapsKeyDown(ev:hxd.Event) {
		keyDowns.set(ev.keyCode, true);
		onKeyPress(ev.keyCode);
	}

	function onHeapsKeyUp(ev:hxd.Event) {
		keyDowns.remove(ev.keyCode);
	}

	function onWindowCloseButton() {
		exit(false);
	}

	public static inline function isMac() return js.Browser.window.navigator.userAgent.indexOf('Mac') != -1;
	public inline function isKeyDown(keyId:Int) return keyDowns.get(keyId)==true;
	public inline function isShiftDown() return keyDowns.get(K.SHIFT)==true;
	public inline function isCtrlDown() return (App.isMac() ? keyDowns.get(K.LEFT_WINDOW_KEY) || keyDowns.get(K.RIGHT_WINDOW_KEY) : keyDowns.get(K.CTRL))==true;
	public inline function isAltDown() return keyDowns.get(K.ALT)==true;
	public inline function hasAnyToggleKeyDown() return isShiftDown() || isCtrlDown() || isAltDown();

	function onKeyPress(keyCode:Int) {
		if( hasPage() )
			curPageProcess.onKeyPress(keyCode);

		switch keyCode {
			case K.L if( isCtrlDown() && isShiftDown() ):
				LOG.printAll();

			#if debug
			case K.T if( isCtrlDown() ):
				// Emulate a crash
				var a : Dynamic = null;
				trace(a.crash);
			#end

			case _:
		}
	}


	public function miniNotif(html:String, persist=false) {
		var e = jBody.find("#miniNotif");
		e.empty()
			.stop(false,true)
			.hide()
			.show()
			.html(html);

		if( !persist )
			e.delay(1000).fadeOut(2000);
	}

	function clearMiniNotif() {
		jBody.find("#miniNotif")
			.stop(false,true)
			.fadeOut(1500);
	}

	function onAppMouseMove(e:js.html.MouseEvent) {
		lastKnownMouse.pageX = e.pageX;
		lastKnownMouse.pageY = e.pageY;
	}

	function onAppFocus(ev:js.html.Event) {
		keyDowns = new Map();
		if( hasPage() )
			curPageProcess.onAppFocus();
	}

	function onAppBlur(ev:js.html.Event) {
		keyDowns = new Map();
		if( hasPage() )
			curPageProcess.onAppBlur();
	}

	function onAppResize(ev:js.html.Event) {
		if( hasPage() )
			curPageProcess.onAppResize();
	}


	public function saveSessionData() {
		dn.LocalStorage.writeObject("session", session);
	}

	function clearCurPage() {
		jPage.empty();
		ui.Tip.clear();

		if( curPageProcess!=null ) {
			curPageProcess.destroy();
			curPageProcess = null;
		}
	}

	public function registerRecentProject(path:String) {
		session.recentProjects.remove(path);
		session.recentProjects.push(path);
		saveSessionData();
		return true;
	}

	public function unregisterRecentProject(path:String) {
		session.recentProjects.remove(path);
		saveSessionData();
	}

	public function clearRecentProjects() {
		session.recentProjects = [];
		saveSessionData();
	}

	public function loadPage( create:()->Page ) {
		clearCurPage();
		curPageProcess = create();
		curPageProcess.onAppResize();
	}

	// public function openEditor(project:data.Project, path:String) {
	// 	LOG.general("Opening Editor");
	// 	clearCurPage();
	// 	curPageProcess = new Editor(project, path);
	// 	curPageProcess.onAppResize();
	// }

	// public function openHome() {
	// 	LOG.general("Opening Home");
	// 	clearCurPage();
	// 	curPageProcess = new page.Home();
	// 	curPageProcess.onAppResize();
	// }

	public function debug(msg:Dynamic, append=false) {
		var wrapper = new J("#debug");
		if( !append )
			wrapper.empty();
		wrapper.show();

		var line = new J("<p/>");
		line.append( Std.string(msg) );
		line.appendTo(wrapper);
	}

	override function onDispose() {
		super.onDispose();
		if( ME==this )
			ME = null;
	}

	public function getDefaultDialogDir() {
		if( session.recentProjects.length==0 )
			return #if debug JsTools.getAppResourceDir() #else JsTools.getExeDir() #end;

		var last = session.recentProjects[session.recentProjects.length-1];
		return dn.FilePath.fromFile(last).directory;
	}

	public function setWindowTitle(?str:String) {
		var base = Const.APP_NAME+" "+Const.getAppVersion();
		if( str==null )
			str = base;
		else
			str = str + "    --    "+base;

		IpcRenderer.invoke("setWinTitle", str);
	}

	public inline function hasPage() {
		return curPageProcess!=null && !curPageProcess.destroyed;
	}

	inline function editorNeedSaving() {
		return Editor.ME!=null && !Editor.ME.destroyed && Editor.ME.needSaving;
	}

	public function exit(force=false) {
		if( !force && editorNeedSaving() ) {
			ui.Modal.closeAll();
			new ui.modal.dialog.UnsavedChanges( exit.bind(true) );
		}
		else {
			if( editorNeedSaving() )
				LOG.fileOp("Exit without saving");
			LOG.trimFileLines();
			LOG.flushToFile();
			IpcRenderer.invoke("exitApp");
		}
	}

	override function update() {
		super.update();

		// Auto flush log every X seconds
		if( !cd.hasSetS("logFlush",10) )
			LOG.flushToFile();
	}
}
