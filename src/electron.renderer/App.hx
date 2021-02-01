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
	public var settings : Settings;
	var keyDowns : Map<Int,Bool> = new Map();
	public var args: dn.Args;
	var mouseButtonDowns : Map<Int,Bool> = new Map();

	public var loadingLog : dn.Log;

	public function new() {
		super();

		// Init logging
		LOG.logFilePath = JsTools.getLogPath();
		LOG.trimFileLines();
		LOG.emptyEntry();
		LOG.tagColors.set("cache", "#edda6f");
		LOG.tagColors.set("tidy", "#8ed1ac");
		LOG.tagColors.set("save", "#ff6f14");
		#if debug
		LOG.printOnAdd = true;
		#end
		LOG.add("BOOT","App started");
		LOG.add("BOOT","Version: "+Const.getAppVersion());
		LOG.add("BOOT","ExePath: "+JsTools.getExeDir());
		LOG.add("BOOT","Resources: "+JsTools.getAppResourceDir());
		LOG.add("BOOT","SamplesPath: "+JsTools.getSamplesDir());
		cd.setS("logFlush",30);

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

		// Track mouse buttons
		jDoc.mousedown( onAppMouseDown );
		jDoc.mouseup( onAppMouseUp );

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
		loadSettings();
		settings.save();

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
			LOG.warning("Couldn't check for updates: "+errStr);
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
				bt.hide();
				function applyUpdate() {
					LOG.general("Installing update");

					loadPage( ()->new page.Updating() );
					delayer.addS(function() {
						IpcRenderer.invoke("installUpdate");
					}, 1);
				}

				if( Editor.ME!=null && Editor.ME.needSaving )
					new ui.modal.dialog.UnsavedChanges(applyUpdate, ()->bt.show());
				else
					applyUpdate();
			});
		}
		dn.electron.ElectronUpdater.checkNow();

		// Start
		delayer.addS( ()->{
			// Look for path and level index in args
			var path = getArgPath();
			var levelIndex : Null<Int> = null;
			if( path!=null && path.extension==Const.LEVEL_EXTENSION ) {
				var indexReg = ~/0*([0-9]+)-.*/gi;
				if( indexReg.match(path.fileName) )
					levelIndex = Std.parseInt( indexReg.matched(1) );
				var dir = path.getLastDirectory();
				path.removeLastDirectory();
				path.fileWithExt = dir+"."+Const.FILE_EXTENSION;
			}
			LOG.add("BOOT", 'Start args: path=$path levelIndex=$levelIndex');

			// Load page
			if( path!=null )
				loadProject(path.full, levelIndex);
			else
				loadPage( ()->new page.Home() );
		}, 0.2);

		IpcRenderer.invoke("appReady");
	}

	function getArgPath() : Null<dn.FilePath> {
		if( args.getLastSoloValue()==null )
			return null;

		var fp = dn.FilePath.fromFile( args.getAllSoloValues().join(" ") );
		if( fp.fileWithExt!=null )
			return fp;

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

	public function isLocked() {
		return ui.ProjectSaving.hasAny() || ui.Modal.hasAnyUnclosable();
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

	public inline function hasInputFocus() {
		return jBody.find("input:focus, textarea:focus").length>0;
	}

	function onKeyPress(keyCode:Int) {
		if( hasPage() )
			curPageProcess.onKeyPress(keyCode);

		for(m in ui.Modal.ALL)
			if( !m.destroyed )
				m.onKeyPress(keyCode);

		switch keyCode {
			// Open debug menu
			#if debug
			case K.D if( App.ME.isCtrlDown() && App.ME.isShiftDown() && !hasInputFocus() ):
				new ui.modal.DebugMenu();
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

	function onAppMouseDown(e:js.jquery.Event) {
		mouseButtonDowns.set(e.button,true);
	}

	function onAppMouseUp(e:js.jquery.Event) {
		mouseButtonDowns.remove(e.button);
	}

	public inline function isMouseButtonDown(btId:Int) {
		return mouseButtonDowns.exists(btId);
	}

	public inline function anyMouseButtonDown() {
		return Lambda.count(mouseButtonDowns)==0;
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
		settings.save();
	}


	function loadSettings() {
		LOG.fileOp("Loading settings from "+Settings.getDir()+"...");

		// Load
		settings = new Settings();

		// Import recent projects to dirs
		if( settings.v.recentDirs==null ) {
			settings.v.recentDirs = [];
			var dones = new Map();
			var i = settings.v.recentProjects.length-1;
			while( i>=0 ) {
				var fp = dn.FilePath.fromFile( settings.v.recentProjects[i] );
				if( !isInAppDir(fp.full,true) && !dones.exists(fp.directory) ) {
					dones.set(fp.directory, true);
					settings.v.recentDirs.insert(0, fp.directory);
				}
				i--;
			}
		}
	}


	function clearCurPage() {
		jPage
			.empty()
			.off()
			.removeClass("locked");

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
		for(p in settings.v.recentDirs)
			if( p==dir )
				return true;
		return false;
	}

	public function registerRecentDir(dir:String) {
		if( dir==null || dir.length==0 || isInAppDir(dir,false) )
			return;
		dir = StringTools.replace(dir, "\\", "/");
		settings.v.recentDirs.remove(dir);
		settings.v.recentDirs.push(dir);
		settings.save();
	}

	public function unregisterRecentDir(dir:String) {
		if( dir==null )
			return;
		dir = StringTools.replace(dir, "\\", "/");
		settings.v.recentDirs.remove(dir);
		settings.save();
	}

	public function clearRecentDirs() {
		settings.v.recentDirs = [];
		settings.save();
	}


	public function recentProjectsContains(path:String) {
		path = StringTools.replace(path, "\\", "/");
		for(p in settings.v.recentProjects)
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
			return fp.directory!=null && fp.directory.indexOf( JsTools.getExeDir() )==0;
		}
	}

	public function registerRecentProject(path:String) {
		// #if !debug
		// if( isInAppDir(path,true) )
		// 	return false;
		// #end

		// No backup files
		if( ui.ProjectSaving.extractBackupInfosFromFileName(path) != null )
			return false;

		path = StringTools.replace(path, "\\", "/");
		settings.v.recentProjects.remove(path);
		settings.v.recentProjects.push(path);
		settings.save();

		var fp = dn.FilePath.fromFile(path);
		registerRecentDir(fp.directory);

		return true;
	}

	public function unregisterRecentProject(path:String) {
		path = StringTools.replace(path, "\\", "/");
		settings.v.recentProjects.remove(path);
		settings.save();
	}

	public function renameRecentProject(oldPath:String, newPath:String) {
		for(i in 0...settings.v.recentProjects.length)
			if( settings.v.recentProjects[i]==oldPath )
				settings.v.recentProjects[i] = newPath;
		settings.save();
	}

	public function clearRecentProjects() {
		settings.v.recentProjects = [];
		settings.save();
	}

	public function loadPage( create:()->Page ) {
		clearCurPage();
		LOG.flushToFile();
		curPageProcess = create();
		curPageProcess.onAppResize();
	}


	public function loadProject(filePath:String, ?levelIndex:Int) : Void {
		ui.ProjectLoader.load(filePath, (?p,?err)->{
			if( p!=null ) {
				loadPage( ()->new page.Editor(p, levelIndex) );
			}
			else {
				// Failed
				LOG.error("Failed to load project: "+filePath+" levelIdx="+levelIndex);
				N.error(switch err {
					case null:
						L.t._("Unknown error");

					case NotFound:
						unregisterRecentProject(filePath);
						L.t._("File not found");

					case JsonParse(err):
						L.t._("Failed to parse project JSON file!");

					case FileRead(err):
						L.t._("Failed to read file on disk!");

					case ProjectInit(err):
						L.t._("Failed to create Project instance!");
				});
				loadPage( ()->new page.Home() );
			}
		});
	}

	public inline function clearDebug() {
		var e = jBody.find("#debug");
		if( !e.is(":empty") || e.is(":visible") )
			e.empty().hide();
	}

	public inline function debug(msg:Dynamic, clear=false) {
		var wrapper = new J("#debug");
		if( clear )
			wrapper.empty();
		wrapper.show();

		var line = new J('<p>${Std.string(msg)}</p>');
		line.appendTo(wrapper);
	}

	override function onDispose() {
		super.onDispose();
		if( ME==this )
			ME = null;
	}

	public function getDefaultDialogDir() {
		if( settings.v.recentProjects.length==0 )
			return #if debug JsTools.getAppResourceDir() #else JsTools.getExeDir() #end;

		var last = settings.v.recentProjects[settings.v.recentProjects.length-1];
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

	public function exit(ignoreUnsaved=false) {
		if( !ignoreUnsaved && editorNeedSaving() ) {
			ui.Modal.closeAll();
			new ui.modal.dialog.UnsavedChanges( exit.bind(true) );
		}
		else {
			if( editorNeedSaving() )
				LOG.general("Exiting without saving.");
			else
				LOG.general("Exiting.");
			LOG.trimFileLines();
			LOG.flushToFile();
			IpcRenderer.invoke("exitApp");
		}
	}

	#if debug
	public function reload() {
		IpcRenderer.invoke("reload");
	}
	#end

	override function update() {
		super.update();

		// Process profiling
		if( dn.Process.PROFILING && !cd.hasSetS("profiler",2) ) {
			clearDebug();
			for(i in dn.Process.getSortedProfilerTimes())
				debug(i.key+" => "+M.pretty(i.value,2)+"s");
		}
	}
}
