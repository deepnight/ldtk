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
	public var settings : AppSettings;
	var keyDowns : Map<Int,Bool> = new Map();
	public var args: dn.Args;

	public var loadingLog : dn.Log;

	public function new() {
		super();

		// Init logging
		LOG.logFilePath = JsTools.getExeDir()+"/LDtk.log";
		LOG.trimFileLines();
		LOG.emptyEntry();
		LOG.tagColors.set("tidy", "#8ed1ac");
		#if debug
		LOG.printOnAdd = true;
		#end
		LOG.add("BOOT","App started");
		LOG.add("BOOT","ExePath: "+JsTools.getExeDir());
		LOG.add("BOOT","Resources: "+JsTools.getAppResourceDir());
		LOG.add("BOOT","SamplesPath: "+JsTools.getSamplesDir());
		LOG.add("BOOT","Settings: "+JsTools.getSettingsDir());

		loadingLog = new dn.Log();
		loadingLog.onAdd = (l)->LOG.addLogEntry(l);

		// App arguments
		var electronArgs : Array<String> = try electron.renderer.IpcRenderer.sendSync("getArgs") catch(_) [];
		electronArgs.shift();
		args = new dn.Args( electronArgs.join(" ") );
		LOG.add("BOOT", args.toString());

		// Init
		ME = this;
		createRoot(Boot.ME.s2d);
		lastKnownMouse = { pageX:0, pageY:0 }
		jCanvas.hide();
		clearMiniNotif();

		// Init window
		IpcRenderer.on("winClose", onWindowCloseButton);

		var win = js.Browser.window;
		win.onblur = onAppBlur;
		win.onfocus = onAppFocus;
		win.onresize = onAppResize;
		win.onmousemove = onAppMouseMove;
		win.onerror = (msg, url, lineNo, columnNo, error:js.lib.Error)->{
			var processes = dn.Process.rprintAll();
			ui.modal.Progress.stopAll();
			for(e in ui.Modal.ALL)
				e.destroy();
			var project : data.Project = Editor.ME!=null && Editor.ME.needSaving ? Editor.ME.project : null;
			var path : String = Editor.ME!=null && Editor.ME.needSaving ? project.filePath.full : null;
			loadPage( ()->new page.CrashReport(error, processes, project, path) );
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

		// Restore settings
		dn.LocalStorage.BASE_PATH = JsTools.getSettingsDir();
		dn.LocalStorage.SUB_FOLDER_NAME = null;
		loadSettings();
		saveSettings();

		// Auto updater
		miniNotif("Checking for update...", true);
		dn.electron.ElectronUpdater.initRenderer();
		dn.electron.ElectronUpdater.onUpdateCheckStart = function() {
			miniNotif("Looking for update...");
			LOG.network("Looking for update");
		}
		dn.electron.ElectronUpdater.onUpdateFound = function(info) {
			LOG.network("Found update: "+info.version+" ("+info.releaseDate+")");
			miniNotif('Downloading ${info.version}...', true);
		}
		dn.electron.ElectronUpdater.onUpdateNotFound = function() miniNotif('App is up-to-date.');
		dn.electron.ElectronUpdater.onError = function(err) {
			var errStr = err==null ? null : Std.string(err);
			LOG.error("Couldn't check for updates: "+errStr);
			if( errStr.length>40 )
				errStr = errStr.substr(0,40) + "[...]";
			miniNotif('Auto-updater failed: "$errStr"', 2);
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
		delayer.addS( ()->{
			var path = getArgPath();
			if( path==null || !loadProject(path) )
				loadPage( ()->new page.Home() );
		}, 0.2);

		IpcRenderer.invoke("appReady");
	}

	function getArgPath() : Null<String> {
		if( args.getLastSoloValue()==null )
			return null;

		var fp = dn.FilePath.fromFile( args.getAllSoloValues().join(" ") );
		if( fp.fileWithExt!=null )
			return fp.full;

		return null;
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

	// public static inline function isMac() return js.Browser.window.navigator.userAgent.indexOf('Mac') != -1;
	public static inline function isLinux() return js.node.Os.platform()=="linux";
	public static inline function isWindows() return js.node.Os.platform()=="win32";
	public static inline function isMac() return js.node.Os.platform()=="darwin";

	public inline function isKeyDown(keyId:Int) return keyDowns.get(keyId)==true;
	public inline function isShiftDown() return keyDowns.get(K.SHIFT)==true;
	public inline function isCtrlDown() return (App.isMac() ? keyDowns.get(K.LEFT_WINDOW_KEY) || keyDowns.get(K.RIGHT_WINDOW_KEY) : keyDowns.get(K.CTRL))==true;
	public inline function isAltDown() return keyDowns.get(K.ALT)==true;
	public inline function hasAnyToggleKeyDown() return isShiftDown() || isCtrlDown() || isAltDown();

	function onKeyPress(keyCode:Int) {
		if( hasPage() )
			curPageProcess.onKeyPress(keyCode);

		for(m in ui.Modal.ALL)
			if( !m.destroyed )
				m.onKeyPress(keyCode);

		switch keyCode {
			case K.L if( isCtrlDown() && isShiftDown() ):
				LOG.printAll();

			// Emulate a crash
			#if debug
			case K.T if( isCtrlDown() && isShiftDown() ):
				LOG.warning("Emulating crash...");
				var a : Dynamic = null;
				a.crash = 5;
			#end

			#if debug
			case K.P if( isCtrlDown() && isShiftDown() ):
				App.LOG.general( "\n"+dn.Process.rprintAll() );
				App.LOG.flushToFile();
			#end

			case _:
		}
	}


	public function addMask() {
		jBody.find("#appMask").remove();
		jBody.append('<div id="appMask"/>');
	}

	public function fadeOutMask() {
		jBody.find("#appMask").fadeOut(200);
	}

	public function miniNotif(html:String, fadeDelayS=0.5, persist=false) {
		var e = jBody.find("#miniNotif");
		delayer.cancelById("miniNotifFadeOut");
		e.empty()
			.stop(false,true)
			.hide()
			.show()
			.html(html);

		if( !persist )
			delayer.addS( "miniNotifFadeOut", ()->e.fadeOut(2000), fadeDelayS );
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


	public inline function changeSettings(doChange:Void->Void) {
		doChange();
		saveSettings();
	}

	public function loadSettings() {
		LOG.fileOp("Loading settings from "+JsTools.getSettingsDir()+"...");

		// Migrate old JS sessionData
		if( js.Browser.window.localStorage.getItem("session")!=null ) {
			LOG.fileOp("Migrating old session to settings files...");
			var raw = js.Browser.window.localStorage.getItem("session");
			var old : AppSettings =
				try haxe.Unserializer.run(raw)
				catch( err:Dynamic ) null;
			if( old!=null )
				try {
					if( old.recentProjects!=null )
						for(i in 0...old.recentProjects.length)
							old.recentProjects[i] = StringTools.replace(old.recentProjects[i], "\\", "/");
					dn.LocalStorage.writeObject("settings", true, old);
				} catch(e:Dynamic) {}

			js.Browser.window.localStorage.removeItem("session");
		}

		settings = dn.LocalStorage.readObject("settings", true, {
			recentProjects: [],
			recentDirs: null,
			compactMode: false,
			grid: true,
			singleLayerMode: false,
			emptySpaceSelection: false,
			tileStacking: false,
		});

		// Import recent projects to dirs
		if( settings.recentDirs==null ) {
			settings.recentDirs = [];
			var dones = new Map();
			var i = settings.recentProjects.length-1;
			while( i>=0 ) {
				var fp = dn.FilePath.fromFile( settings.recentProjects[i] );
				if( !dones.exists(fp.directory) ) {
					dones.set(fp.directory, true);
					settings.recentDirs.insert(0, fp.directory);
				}
				i--;
			}
			trace(settings.recentDirs);
		}
	}

	public function saveSettings() {
		dn.LocalStorage.writeObject("settings", true, settings);
	}

	function clearCurPage() {
		jPage.empty();
		ui.Tip.clear();

		if( curPageProcess!=null ) {
			curPageProcess.destroy();
			curPageProcess = null;
		}
	}

	public function recentDirsContains(dir:String) {
		if( dir==null )
			return false;
		dir = StringTools.replace(dir, "\\", "/");
		for(p in settings.recentDirs)
			if( p==dir )
				return true;
		return false;
	}

	public function registerRecentDir(dir:String) {
		if( dir==null )
			return;
		dir = StringTools.replace(dir, "\\", "/");
		settings.recentDirs.remove(dir);
		settings.recentDirs.push(dir);
		saveSettings();
	}

	public function unregisterRecentDir(dir:String) {
		if( dir==null )
			return;
		dir = StringTools.replace(dir, "\\", "/");
		settings.recentDirs.remove(dir);
		saveSettings();
	}

	public function clearRecentDirs() {
		settings.recentDirs = [];
		saveSettings();
	}


	public function recentProjectsContains(path:String) {
		path = StringTools.replace(path, "\\", "/");
		for(p in settings.recentProjects)
			if( p==path )
				return true;
		return false;
	}

	public inline function isInAppDir(path:String, isFile:Bool) {
		if( path==null )
			return false;
		else {
			var fp = isFile ? dn.FilePath.fromFile(path) : dn.FilePath.fromDir(path);
			fp.useSlashes();
			return fp.directory.indexOf( JsTools.getExeDir() )==0;
		}
	}

	public function registerRecentProject(path:String) {
		// #if !debug
		// if( isInAppDir(path,true) )
		// 	return false;
		// #end

		path = StringTools.replace(path, "\\", "/");
		settings.recentProjects.remove(path);
		settings.recentProjects.push(path);
		saveSettings();

		var fp = dn.FilePath.fromFile(path);
		registerRecentDir(fp.directory);

		return true;
	}

	public function unregisterRecentProject(path:String) {
		path = StringTools.replace(path, "\\", "/");
		settings.recentProjects.remove(path);
		saveSettings();
	}

	public function renameRecentProject(oldPath:String, newPath:String) {
		for(i in 0...settings.recentProjects.length)
			if( settings.recentProjects[i]==oldPath )
				settings.recentProjects[i] = newPath;
		saveSettings();
	}

	public function clearRecentProjects() {
		settings.recentProjects = [];
		saveSettings();
	}

	public function loadPage( create:()->Page ) {
		clearCurPage();
		curPageProcess = create();
		curPageProcess.onAppResize();
	}

	public function loadProject(filePath:String) {
		loadingLog.clear();
		if( !JsTools.fileExists(filePath) ) {
			N.error("File not found: "+filePath);
			loadingLog.error("File not found: "+filePath);
			unregisterRecentProject(filePath);
			return false;
		}

		// Parse
		loadingLog.fileOp('Loading project $filePath...');
		var json = null;
		var p = #if !debug try #end {
			var raw = JsTools.readFileString(filePath);
			json = haxe.Json.parse(raw);
			data.Project.fromJson(filePath, json);
		}
		#if !debug
		catch(e:Dynamic) {
			loadingLog.error( Std.string(e) );
			null;
		}
		#end

		// Load separate files
		if( p.externalLevels ) {
			var idx = 0;
			for(l in p.levels) {
				var path = p.makeAbsoluteFilePath(l.externalRelPath);
				if( !JsTools.fileExists(path) ) {
					// TODO better lost level management
					loadingLog.error("Level file not found "+l.externalRelPath);
					p.levels.splice(idx,1);
					idx--;
				}
				else {
					// Parse level
					try {
						loadingLog.fileOp("Loading external level "+l.externalRelPath+"...");
						var raw = JsTools.readFileString(path);
						var lJson = haxe.Json.parse(raw);
						var l = data.Level.fromJson(p, lJson);
						p.levels[idx] = l;
					}
					catch(e:Dynamic) {
						// TODO better lost level management
						loadingLog.error("Error while parsing level file "+l.externalRelPath);
						p.levels.splice(idx,1);
						idx--;
					}
				}
				idx++;
			}
		}

		if( p==null ) {
			loadingLog.error("Couldn't read project file!");
			return false;
		}

		// Open it
		loadingLog.fileOp("Done.");
		loadPage( ()->new page.Editor(p) );

		// Display errors
		if( loadingLog.containsAnyCriticalEntry() ) {
			new ui.modal.dialog.LogPrint(loadingLog, L.t._("Error while loading project"));
			Editor.ME.needSaving = true;
		}
		return true;
	}

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
		if( settings.recentProjects.length==0 )
			return #if debug JsTools.getAppResourceDir() #else JsTools.getExeDir() #end;

		var last = settings.recentProjects[settings.recentProjects.length-1];
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
