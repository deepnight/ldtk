import electron.renderer.IpcRenderer;
#if debug
import page.CrashReport; // force compilation in debug
#end

class App extends dn.Process {
	public static var ME : App;
	public static var LOG : dn.Log = new dn.Log(5000);
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
	var jsKeyDowns : Map<Int,Bool> = new Map();
	var heapsKeyDowns : Map<Int,Bool> = new Map();
	public var args: dn.Args;
	var mouseButtonDowns : Map<Int,Bool> = new Map();
	public var focused(default,null) = true;
	var jsMetaKeyDown = false;
	public var overCanvas(default,null) = false;
	public var hasGlContext(default,null) = false;

	public var clipboard : data.Clipboard;

	var requestedCpuEndTime = 0.;
	public var pendingUpdate : Null<{ ver:String, github:Bool }>;

	public var keyBindings : Array<KeyBinding> = [];
	var debugFlags : Map<DebugFlag,Bool> = new Map();

	public function new() {
		super();

		// Init logging
		LOG.logFilePath = JsTools.getLogPath();
		LOG.trimFileLines();
		LOG.emptyEntry();
		LOG.emptyEntry();
		LOG.tagColors.set("update", "#6fed76");
		LOG.tagColors.set("cache", "#edda6f");
		LOG.tagColors.set("tidy", "#8ed1ac");
		LOG.tagColors.set("save", "#ff6f14");
		LOG.tagColors.set("import", "#ffcc00");
		#if debug
		// LOG.printOnAdd = true;
		#end
		LOG.add("BOOT","App started");
		LOG.add("BOOT","Version: "+Const.getAppVersionStr()+" (build "+Const.getAppBuildId()+")");
		LOG.add("BOOT","ExePath: "+JsTools.getExeDir());
		LOG.add("BOOT","Assets: "+JsTools.getAssetsDir());
		LOG.add("BOOT","ExtraFiles: "+JsTools.getExtraFilesDir());
		LOG.add("BOOT","CWD: "+Sys.getCwd());
		LOG.add("BOOT","Display: "+ET.getScreenWidth()+"x"+ET.getScreenHeight());

		// App arguments
		args = ET.getArgs();
		LOG.add("BOOT", args.toString());
		LOG.flushToFile();
		LOG.flushOnAdd = true; // disabled after App init sequence

		// Init
		ME = this;
		createRoot(Boot.ME.s2d);
		lastKnownMouse = { pageX:0, pageY:0 }
		jCanvas.hide();
		jCanvas.mouseenter( _->overCanvas = true );
		jCanvas.mouseleave( _->overCanvas = false );
		var canvas = Std.downcast(jCanvas.get(0), js.html.CanvasElement);
		hasGlContext = canvas.getContextWebGL()!=null || canvas.getContextWebGL2()!=null;
		canvas.addEventListener("webglcontextlost", (_)->onGlContextLoss());
		clearMiniNotif();
		clipboard = data.Clipboard.createSystem();
		Chrono.COLORS_LOW.col = "#15ff00";
		Chrono.COLORS_LOW.timeThreshold = 0.01;
		Chrono.COLORS_HIGH.col = "#ff0000";
		Chrono.COLORS_HIGH.timeThreshold = 0.30;

		// Init window
		IpcRenderer.on("onWinClose", onWindowCloseButton);
		IpcRenderer.on("onWinMove", onWindowMove);
		IpcRenderer.on("settingsApplied", ()->updateBodyClasses());

		var win = js.Browser.window;
		win.onblur = onWindowBlur;
		win.onfocus = onWindowFocus;
		win.onresize = onAppResize;
		win.onmousemove = onAppMouseMove;
		#if debug
		// Crash layer
		win.onerror = (msg, url, lineNo, columnNo, error:js.lib.Error)->{
			if( jBody.children("#crashed").length==0 )
				jBody.append('<div id="crashed"/>');

			var jCrash = jBody.children("#crashed");
			jCrash.append('<p>$msg</p>');
			var stack = "<p>" + error.stack.split("\n").splice(0,2).join("</p><p>") + "</p>";
			jCrash.append(stack);
			return false;
		}
		#else
		// Redirect to crash page
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
		#end

		// Track mouse buttons
		jDoc.mousedown( onAppMouseDown );
		jDoc.mouseup( onAppMouseUp );
		jDoc.get(0).onwheel = onAppMouseWheel;

		// Keyboard events
		jBody
			.on("keydown", onJsKeyDown )
			.on("keyup", onJsKeyUp );
		Boot.ME.s2d.addEventListener(onHeapsEvent);

		// Init dirs
		var fp = dn.FilePath.fromDir( ET.getAppResourceDir() );
		fp.useSlashes();
		APP_RESOURCE_DIR = fp.directoryWithSlash;

		// Restore settings
		loadSettings();
		settings.save();
		LOG.add("BOOT","AppZoomFactor: "+settings.getAppZoomFactor());

		// Auto updater
		initAutoUpdater();

		// Start
		delayer.addS( ()->{
			// Look for path and level index in args
			var path = getArgPath();
			if( path!=null && !path.isEmpty() && !path.isAbsolute() ) {
				path = dn.FilePath.fromFile(Sys.getCwd() + path.slash() + path.full);
				LOG.add("BOOT", "Fixed path argument: "+path.full);
			}

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
			if( path!=null ) {
				LOG.add("BOOT", 'Loading project from args (${path.full})...');
				loadProject(path.full, levelIndex);
			}
			else if( settings.v.openLastProject && settings.v.lastProject!=null && NT.fileExists(settings.v.lastProject.filePath) ) {
				var path = settings.v.lastProject.filePath;
				LOG.add("BOOT", 'Re-opening last project ($path)...');
				loadProject(path);
			}
			else {
				LOG.add("BOOT", 'Loading Home...');
				loadPage( ()->new page.Home(), true );
			}

			if( !hasGlContext )
				onGlContextLoss();
		}, 0.2);

		LOG.add("BOOT", "Calling appReady...");
		IpcRenderer.invoke("appReady");
		updateBodyClasses();
		LOG.flushOnAdd = false;
		initKeyBindings();
	}


	function initKeyBindings() {
		keyBindings = [];

		var ctrlReg = ~/\bctrl\b/i;
		var shiftReg = ~/\bshift\b/i;
		var altReg = ~/\balt\b/i;
		var macCtrlReg = ~/\bmacctrl\b/i;

		// Parse AppCommands meta
		var meta = haxe.rtti.Meta.getFields(AppCommand);
		var specialKeysRemovalReg = ~/(macctrl|ctrl|shift|alt| |-|\+|\[wasd\]|\[zqsd\]|\[arrows\]|\[win\]|\[linux\]|\[mac\]|\[debug\])/gi;
		for(k in AppCommand.getConstructors()) {
			var cmd = AppCommand.createByName(k);
			var cmdMeta : Dynamic = Reflect.field(meta, k);
			var rawCombos : String = try cmdMeta.k[0] catch(_) null;
			if( rawCombos==null )
				continue;

			rawCombos = rawCombos.toLowerCase();
			for(rawCombo in rawCombos.split(",")) {
				var rawKey = specialKeysRemovalReg.replace(rawCombo, "");
				var keyCode = switch rawKey {
					case "escape": K.ESCAPE;
					case "tab": K.TAB;
					case "pagedown": K.PGDOWN;
					case "pageup": K.PGUP;
					case "up": K.UP;
					case "down": K.DOWN;
					case "left": K.LEFT;
					case "right": K.RIGHT;
					case "enter": K.ENTER;
					case "²": K.QWERTY_TILDE;
					case "`": K.QWERTY_QUOTE;

					case _:
						var fnReg = ~/f([0-9]|1[0-2])$/gi;
						if( rawKey.length==1 && rawKey>="a" && rawKey<="z" )
							K.A + ( rawKey.charCodeAt(0) - "a".code )
						else if( rawKey.length==1 && rawKey>="0" && rawKey<="9" )
							K.NUMBER_0 + ( rawKey.charCodeAt(0) - "0".code )
						else if( fnReg.match(rawKey) )
							K.F1 + Std.parseInt( fnReg.matched(1) ) - 1;
						else
							throw "Unknown key "+rawKey;
				}

				var navKeys : Null<Settings.NavigationKeys> =
					rawCombo.indexOf("[wasd]")>=0 ? Settings.NavigationKeys.Wasd
					: rawCombo.indexOf("[zqsd]")>=0 ? Settings.NavigationKeys.Zqsd
					: rawCombo.indexOf("[arrows]")>=0 ? Settings.NavigationKeys.Arrows
					: null;


				var os : Null<String> =
					rawCombo.indexOf("[win]")>=0 ? "win"
					: rawCombo.indexOf("[linux]")>=0 ? "linux"
					: rawCombo.indexOf("[mac]")>=0 ? "mac"
					: null;


				var kb : KeyBinding = {
					jsDisplayText: rawCombo.indexOf("]")>=0 ? rawCombo.substr(rawCombo.indexOf("]")+1) : rawCombo,
					keyCode: keyCode,
					jsKey: rawKey,
					ctrlCmd: ctrlReg.match(rawCombo),
					macCtrl: macCtrlReg.match(rawCombo),
					shift: shiftReg.match(rawCombo),
					alt: altReg.match(rawCombo),
					navKeys: navKeys,
					os: os,
					debug: rawCombo.indexOf("[debug]")>=0,
					allowInInputs: Reflect.hasField(cmdMeta, "input"),
					command: cmd,
				}
				keyBindings.push(kb);
			}

		}
	}


	public function getFirstRelevantKeyBinding(cmd:AppCommand) : Null<KeyBinding> {
		if( cmd==null )
			return null;

		for(kb in App.ME.keyBindings) {
			if( kb.command!=cmd )
				continue;

			// Check OS
			switch kb.os {
				case null:
				case "win": if( !isWindows() ) continue;
				case "mac": if( !isMac() ) continue;
				case "linux": if( !isLinux() ) continue;
			}

			// Check NavKeys
			if( kb.navKeys!=null && settings.v.navigationKeys!=kb.navKeys )
				continue;

			// Check debug
			#if !debug
			if( kb.debug )
				continue;
			#end

			return kb;
		}

		return null;
	}

	function initAutoUpdater() {
		// Init
		dn.js.ElectronUpdater.initRenderer();
		dn.js.ElectronUpdater.onUpdateCheckStart = function() {
			miniNotif("Looking for update...");
			LOG.add("update", "Looking for update");
		}
		dn.js.ElectronUpdater.onUpdateFound = function(info) {
			LOG.add("update", "Found update: "+info.version+" ("+info.releaseDate+")");
			if( !settings.v.autoInstallUpdates ) {
				pendingUpdate = { ver:info.version, github:true }
				miniNotif('Found update ${info.version}!');
				showUpdateButton(info.version, "download", "Download update", false, ()->{
					N.success('Downloading update ${info.version}...');
					dn.js.ElectronUpdater.download();
				});
			}
		}
		dn.js.ElectronUpdater.onUpdateNotFound = function() miniNotif('App is up-to-date.');
		dn.js.ElectronUpdater.onError = function(err) {
			var errStr = err==null ? null : Std.string(err);
			LOG.add("update", "ERROR: couldn't check for updates. Returned: "+errStr);
			if( errStr.length>40 )
				errStr = errStr.substr(0,40) + "[...]";
			checkManualUpdate();
		}
		dn.js.ElectronUpdater.onUpdateDownloadProgress = (cur,total)->{
			miniNotif('Downloading update: ${Std.int(100*cur/total)}%', true);
		}
		dn.js.ElectronUpdater.onUpdateDownloaded = function(info) {
			LOG.add("update", "Update downloaded: "+info.version);
			miniNotif('Update ${info.version} ready!');
			function _install() {
				LOG.general("Installing update");

				loadPage( ()->new page.Updating() );
				delayer.addS(function() {
					IpcRenderer.invoke("quitAndInstall");
				}, 1);
			}
			if( settings.v.autoInstallUpdates )
				showUpdateButton(info.version, "appUpdate", "Install update", _install);
			else {
				N.success('Update ${info.version} downloaded.');
				showUpdateButton(info.version, "appUpdate", "Proceed to install", true, false, _install);
			}
		}

		// Check now
		checkForUpdate();
	}

	public function checkForUpdate() {
		jBody.find("#updateInstall").empty().hide();

		if( App.isWindows() ) {
			// Windows
			miniNotif("Checking for update...", true);
			if( settings.v.autoInstallUpdates )
				dn.js.ElectronUpdater.checkAndInstall();
			else
				dn.js.ElectronUpdater.checkOnly();
		}
		else {
			// Mac & Linux
			checkManualUpdate();
		}
	}

	function checkManualUpdate() {
		miniNotif("Checking for update (GitHub)...", true);
		LOG.add("update", "Fetching latest version from GitHub...");
		dn.js.ElectronUpdater.fetchLatestGitHubReleaseVersion("deepnight","ldtk", (latest)->{
			if( latest!=null )
				LOG.add("update", "Found "+latest.full);

			if( latest==null ) {
				LOG.error("Failed to fetch latest version from GitHub");
				miniNotif("Couldn't retrieve latest version number from GitHub!", false);
			}
			else if( Version.greater(latest.full, Const.getAppVersionStr(true), false ) ) {
				LOG.add("update", "Update available: "+latest);
				pendingUpdate = { ver:latest.full, github:false }

				showUpdateButton(latest.full, "world", "Update available", false, ()->{
					electron.Shell.openExternal(Const.DOWNLOAD_URL);
				});
			}
			else {
				LOG.add("update", "No new update.");
				miniNotif('App is up-to-date.');
			}
		});
	}


	function showUpdateButton(version:String, icon:String, label:String, checkUnsaved=true, allowCancel=true, proceed:Void->Void) {
		var jWrapper = jBody.find("#updateInstall");
		jWrapper.empty().show();

		// Install
		var jButton = new J('<button class="proceed"/>').appendTo(jWrapper);
		jButton.append('<span class="icon $icon"/>');
		jButton.append('<strong>$label</strong>');
		jButton.append('<em>Version $version</em>');
		jButton.click(function(_) {
			jWrapper.hide();

			if( Editor.exists() && Editor.ME.needSaving && checkUnsaved )
				new ui.modal.dialog.UnsavedChanges(proceed, ()->jWrapper.show());
			else if( !ui.modal.Progress.hasAny() )
				proceed();
		});

		// Ignore
		if( allowCancel && !settings.v.autoInstallUpdates ) {
			var jIgnore = new J('<button class="skip gray"/>');
			jIgnore.appendTo(jWrapper);
			jIgnore.append('<span class="icon close"/>');
			jIgnore.click( _->{
				jWrapper.hide();
			});
		}
	}


	inline function setBodyClassIf(className:String, cond:Void->Bool) {
		if( cond() )
			jBody.addClass(className);
		else
			jBody.removeClass(className);
	}

	public function updateBodyClasses() {
		setBodyClassIf("fullscreen", ET.isFullScreen);
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
		if( ev.keyCode==K.TAB && !ui.Modal.hasAnyOpen() && !hasInputFocus() )
			ev.preventDefault();

		if( ev.keyCode==K.ALT )
			ev.preventDefault();

		if( !isKeyDown(ev.keyCode) )
			onKeyDown(ev.keyCode);
		jsMetaKeyDown = ev.metaKey;
		jsKeyDowns.set(ev.keyCode, true);
		onKeyPress(ev.keyCode);
	}

	function onJsKeyUp(ev:js.jquery.Event) {
		jsMetaKeyDown = false;
		onKeyUp(ev.keyCode);
	}

	function onHeapsKeyDown(ev:hxd.Event) {
		if( !isKeyDown(ev.keyCode) )
			onKeyDown(ev.keyCode);
		heapsKeyDowns.set(ev.keyCode, true);
		onKeyPress(ev.keyCode);
	}

	function onHeapsKeyUp(ev:hxd.Event) {
		onKeyUp(ev.keyCode);
	}

	function onWindowCloseButton() {
		exit(false);
	}

	function onWindowMove() {
	}

	public function isLocked() {
		return ui.ProjectSaver.hasAny() || ui.Modal.hasAnyUnclosable();
	}

	public static function isLinux() return js.node.Os.platform()=="linux";
	public static function isWindows() return js.node.Os.platform()=="win32";
	public static function isMac() return js.node.Os.platform()=="darwin";
	// public static function isWindows() return false;
	// public static function isMac() return true;

	public inline function isKeyDown(keyId:Int) return jsKeyDowns.get(keyId)==true || heapsKeyDowns.get(keyId)==true;
	public inline function isShiftDown() return isKeyDown(K.SHIFT);
	public inline function isCtrlCmdDown() {
		return App.isMac()
			? jsMetaKeyDown || isKeyDown(91) || isKeyDown(93)
			: isKeyDown(K.CTRL);
	}
	public inline function isMacCtrlDown() {
		return App.isMac()
			? isKeyDown(K.CTRL)
			: false;
	}
	public inline function isAltDown() return isKeyDown(K.ALT);
	public inline function hasAnyToggleKeyDown() return isShiftDown() || isCtrlCmdDown() || isMacCtrlDown() || isAltDown();


	var _inputFocusCache : Null<Bool> = null;
	public inline function hasInputFocus() {
		if( _inputFocusCache==null )
			_inputFocusCache = jBody.find("input:focus, textarea:focus").length>0;
		return _inputFocusCache;
	}


	function onKeyDown(keyCode:Int) {
		if( hasPage() && !curPageProcess.isPaused() )
			curPageProcess.onKeyDown(keyCode);
	}


	function onKeyUp(keyCode:Int) {
		jsKeyDowns.remove(keyCode);
		heapsKeyDowns.remove(keyCode);

		if( hasPage() && !curPageProcess.isPaused() )
			curPageProcess.onKeyUp(keyCode);
	}


	function onKeyPress(keyCode:Int) {
		// Propagate to current page
		if( hasPage() && !curPageProcess.isPaused() )
			curPageProcess.onKeyPress(keyCode);

		// Propagate to all modals
		for(m in ui.Modal.ALL)
			if( !m.destroyed && !m.isPaused() )
				m.onKeyPress(keyCode);

		// Check app key bindings
		for(kb in keyBindings) {
			#if( !debug )
			if( kb.debug )
				continue;
			#end

			switch kb.os {
				case null:
				case "win": if( !App.isWindows() ) continue;
				case "linux": if( !App.isLinux() ) continue;
				case "mac": if( !App.isMac() ) continue;
				case _:
			}

			if( kb.keyCode!=keyCode )
				continue;

			if( kb.shift && !App.ME.isShiftDown() || !kb.shift && App.ME.isShiftDown() )
				continue;

			if( kb.ctrlCmd && !App.ME.isCtrlCmdDown() || !kb.ctrlCmd && App.ME.isCtrlCmdDown() )
				continue;

			if( kb.macCtrl && !App.ME.isMacCtrlDown() || !kb.macCtrl && App.ME.isMacCtrlDown() )
				continue;

			if( kb.alt && !App.ME.isAltDown() || !kb.alt && App.ME.isAltDown() )
				continue;

			if( !kb.allowInInputs && hasInputFocus() )
				continue;

			if( kb.navKeys!=null && kb.navKeys!=settings.v.navigationKeys )
				continue;

			executeAppCommand(kb.command);
			break;
		}

		// Misc shortcuts
		switch keyCode {
			// Open debug menu
			case K.D if( isCtrlCmdDown() && isShiftDown() && !hasInputFocus() ):
				new ui.modal.DebugMenu();

			case _:
		}
	}


	public function executeAppCommand(cmd:AppCommand) {
		switch cmd {
			case C_SaveProject:
			case C_SaveProjectAs:
			case C_CloseProject:
			case C_RenameProject:
			case C_Back:
			case C_AppSettings:
			case C_Undo:
			case C_Redo:
			case C_SelectAll:
			case C_ZenMode:
			case C_ShowHelp:
			case C_ToggleWorldMode:
			case C_RunCommand:
			case C_GotoPreviousWorldLayer:
			case C_GotoNextWorldLayer:
			case C_MoveLevelToPreviousWorldLayer:
			case C_MoveLevelToNextWorldLayer:
			case C_OpenProjectPanel:
			case C_OpenLayerPanel:
			case C_OpenEntityPanel:
			case C_OpenEnumPanel:
			case C_OpenTilesetPanel:
			case C_OpenLevelPanel:
			case C_NavUp:
			case C_NavDown:
			case C_NavLeft:
			case C_NavRight:
			case C_ToggleAutoLayerRender:
			case C_ToggleSelectEmptySpaces:
			case C_ToggleTileStacking:
			case C_ToggleSingleLayerMode:
			case C_ToggleDetails:
			case C_ToggleGrid:
			case C_CommandPalette:
			case C_FlipX:
			case C_FlipY:
			case C_ToggleTileRandomMode:
			case C_SaveTileSelection:
			case C_LoadTileSelection:

			case C_ExitApp:
				App.ME.exit();

			case C_HideApp:
				dn.js.ElectronTools.hideWindow();

			case C_MinimizeApp:
				dn.js.ElectronTools.minimize();

			case C_ToggleFullscreen:
				var isFullScreen = ET.isFullScreen();
				if( !isFullScreen )
					N.success("Press F11 to leave fullscreen");
				ET.setFullScreen(!isFullScreen);
				updateBodyClasses();
		}

		// Propagate to current page
		if( hasPage() && !curPageProcess.isPaused() )
			curPageProcess.onAppCommand(cmd);
	}


	public function addMask() {
		removeMask();
		jBody.append('<div id="appMask"/>');
	}

	public function fadeOutMask() {
		jBody.find("#appMask").fadeOut(200);
	}

	public function removeMask() {
		jBody.find("#appMask").remove();
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

	function onGlContextLoss() {
		LOG.error("GL context lost!");
		hasGlContext = false;
		jBody.addClass("noGlCtx");

		var m = Editor.exists()
			? new ui.modal.dialog.Warning( L.t._("The WebGL context was lost!\nDon't worry, it's probably nothing, and no data was lost. You should just save your work and restart the application.") )
			: new ui.modal.dialog.Warning( L.t._("The WebGL context was lost!\nYou need to restart the application.") );
		m.addParagraph( L.t._("If this happens a lot, you should try to update your graphic drivers.") );
	}

	function onAppMouseDown(e:js.jquery.Event) {
		mouseButtonDowns.set(e.button,true);
		if( hasPage() && !curPageProcess.isPaused() )
			curPageProcess.onAppMouseDown();
	}

	function onAppMouseUp(e:js.jquery.Event) {
		mouseButtonDowns.remove(e.button);
		if( hasPage() && !curPageProcess.isPaused() )
			curPageProcess.onAppMouseUp();
	}

	function onAppMouseWheel(e:js.html.WheelEvent) {
		if( hasPage() && !curPageProcess.isPaused() ) {
			var spd = e.ctrlKey ? 0.20 : 0.01;
			var delta = spd * -e.deltaY;
			curPageProcess.onAppMouseWheel(delta);
		}
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

	function onWindowFocus(ev:js.html.Event) {
		if( ev.target!=js.Browser.window )
			return;

		focused = true;
		jsKeyDowns = new Map();
		heapsKeyDowns = new Map();
		jsMetaKeyDown = false;
		if( hasPage() )
			curPageProcess.onAppFocus();
		hxd.System.fpsLimit = -1;
		clipboard.readSystemClipboard();
	}

	function onWindowBlur(ev:js.html.Event) {
		if( !focused || ev.target!=js.Browser.window )
			return;

		focused = false;
		overCanvas = false;
		jsKeyDowns = new Map();
		heapsKeyDowns = new Map();
		jsMetaKeyDown = false;
		if( hasPage() )
			curPageProcess.onAppBlur();
		// Note: FPS limit is done during update
	}

	function onAppResize(ev:js.html.Event) {
		if( hasPage() )
			curPageProcess.onAppResize();
	}


	public inline function requestCpu(full=true) {
		requestedCpuEndTime = haxe.Timer.stamp()+2;
	}


	function loadSettings() {
		LOG.fileOp("Loading settings from "+Settings.getDir()+"...");

		// Load
		settings = new Settings();
		if( settings.v.lastKnownVersion==null )
			LOG.warning("  -> New settings");

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

		hxd.System.fpsLimit = -1;

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
		// No backup files
		if( ui.ProjectSaver.extractBackupInfosFromFileName(path) != null )
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


	public function hasForcedDirColor(dir:String) {
		for(dc in settings.v.recentDirColors)
			if( dc.path==dir )
				return true;
		return false;
	}

	public function getRecentDirColor(dir:String) : dn.Col {
		for(dc in settings.v.recentDirColors)
			if( dc.path==dir )
				return dn.Col.parseHex(dc.col);

		var csum = 0;
		for(c in dir.split(""))
			csum+=c.charCodeAt(0);
		var pal = Const.getNicePalette().filter( c->c.fastLuminance>=0.4 );
		var col = pal[csum%pal.length];
		return col;
	}


	public function forceDirColor(dir:String, ?c:dn.Col) {
		var i = 0;
		while( i < settings.v.recentDirColors.length )
			if( settings.v.recentDirColors[i].path==dir )
				settings.v.recentDirColors.splice(i,1);
			else
				i++;
		if( c!=null ) {
			settings.v.recentDirColors.push({ path: dir, col:c.toHex() });
			settings.save();
		}
	}


	public function clearRecentProjects() {
		settings.v.recentProjects = [];
		settings.save();
	}

	public function loadPage( create:()->Page, checkAndNotifyUpdate=false ) {
		clearCurPage();
		LOG.flushToFile();
		curPageProcess = create();
		curPageProcess.onAppResize();

		// Notify app update
		if( checkAndNotifyUpdate && settings.v.lastKnownVersion!=Const.getAppVersionStr() ) {
			var prev = settings.v.lastKnownVersion;
			settings.v.lastKnownVersion = Const.getAppVersionStr();
			App.ME.settings.save();

			new ui.modal.dialog.Changelog(true);
		}
	}

	public function loadProject(filePath:String, ?levelIndex:Int, ?onComplete:(p:Null<data.Project>)->Void) : Void {
		new ui.ProjectLoader(
			filePath,
			(p)->{
				if( onComplete!=null )
					onComplete(p);
				loadPage( ()->new page.Editor(p, levelIndex), true );
			},
			(err)->{
				// Failed
				if( onComplete!=null )
					onComplete(null);
				LOG.error("Failed to load project: "+filePath+" levelIdx="+levelIndex);
				if( err==ProjectNotFound )
					unregisterRecentProject(filePath);
				loadPage( ()->new page.Home() );
			}
		);
	}

	public inline function clearDebug() {
		var e = jBody.find("#debug");
		if( !e.is(":empty") || e.is(":visible") )
			e.empty().hide();
	}

	public inline function debug(msg:Dynamic, ?c:Null<Int>, clear=false, pre=false) {
		var wrapper = new J("#debug");
		if( clear )
			wrapper.empty();
		wrapper.show();

		var str = StringTools.htmlEscape( Std.string(msg) );
		if( pre )
			str = '<pre>$str</pre>';
		var jLine = new J('<p>$str</p>');
		if( c!=null )
			jLine.css("color", C.intToHex(c));
		jLine.appendTo(wrapper);
	}

	public inline function debugPre(msg:Dynamic, ?color:dn.Col, clear=false) {
		debug(msg, color, clear, true);
	}

	override function onDispose() {
		super.onDispose();
		if( ME==this )
			ME = null;
	}

	public function getDefaultDialogDir() {
		if( settings.v.recentProjects.length==0 )
			return #if debug ET.getAppResourceDir() #else JsTools.getExeDir() #end;

		var last = settings.v.recentProjects[settings.v.recentProjects.length-1];
		return dn.FilePath.fromFile(last).directory;
	}

	public function setWindowTitle(?str:String) {
		var base = Const.APP_NAME+" "+Const.getAppVersionStr();
		if( str==null )
			str = base;
		else
			str = str + "    --    "+base;

		ET.setWindowTitle(str);
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
			ET.exitApp();
		}
	}


	public function setDebugFlag(f:DebugFlag, active=true) {
		clearDebug();
		if( active )
			debugFlags.set(f, true);
		else
			debugFlags.remove(f);
	}

	public function toggleDebugFlag(f:DebugFlag) {
		setDebugFlag(f, !hasDebugFlag(f));
	}

	public inline function hasDebugFlag(f:DebugFlag) {
		return debugFlags.exists(f);
	}


	override function preUpdate() {
		super.preUpdate();
		_inputFocusCache = null;
	}

	override function update() {
		super.update();

		// FPS limit while app isn't focused
		if( haxe.Timer.stamp()<=requestedCpuEndTime ) // Has recent request
			hxd.System.fpsLimit = -1;
		else if( ui.modal.Progress.hasAny() || ui.modal.MetaProgress.exists() ) // progress is running
			hxd.System.fpsLimit = -1;
		else if( !focused ) // App is blurred
			hxd.System.fpsLimit = 2;
		else if( haxe.Timer.stamp()>requestedCpuEndTime+4 ) // last request is long time ago (idling?)
			hxd.System.fpsLimit = Std.int(Const.FPS*0.2);
		else
			hxd.System.fpsLimit = Std.int(Const.FPS*0.5);


		// Process profiling
		if( dn.Process.PROFILING && !cd.hasSetS("profiler",2) ) {
			clearDebug();
			for(i in dn.Process.getSortedProfilerTimes())
				debug(i.key+" => "+M.pretty(i.value,2)+"s");
		}

		// Debug print
		if( hasDebugFlag(F_MainDebug) ) {
			clearDebug();
			debug("-- Misc ----------------------------------------");
			debugPre('Electron: ${Const.getElectronVersion()}');
			debugPre('Detected OS: '+(isWindows()?"Windows":isMac()?"macOs":isLinux()?"Linux":"Unknown ("+js.node.Os.platform()+")"));
			debugPre('FPS=${hxd.System.fpsLimit<=0 ? "100":Std.string(M.round(100*hxd.System.fpsLimit/60))}%');
			debugPre('ElectronThrottling=${dn.js.ElectronTools.isThrottlingEnabled()}');
			debugPre("electronZoom="+M.pretty(ET.getZoom(),2));
			if( Editor.ME!=null ) {
				debugPre("mouse="+Editor.ME.getMouse());
				var cam = Editor.ME.camera;
				debugPre("zoom="+M.pretty(cam.adjustedZoom,2)+" cam="+M.round(cam.width)+"x"+M.round(cam.height)+" pixelratio="+cam.pixelRatio);
				debugPre("  Selection="+Editor.ME.selectionTool.debugContent());
			}

			debugPre("clipboard="+clipboard.name);
			debugPre("keyDown(Heaps)="+heapsKeyDowns);
			debugPre("keyDown(JS)="+jsKeyDowns);
			debugPre("appButtons="
				+ ( isMouseButtonDown(0) ? "[left] " : "" )
				+ ( isMouseButtonDown(2) ? "[right] " : "" )
				+ ( isMouseButtonDown(1) ? "[middle] " : "" )
				+ " toggles="
				+ ( isCtrlCmdDown() ? "[ctrlCmd] " : "" )
				+ ( isMacCtrlDown() ? "[macctrl] " : "" )
				+ ( isShiftDown() ? "[shift] " : "" )
				+ ( isAltDown() ? "[alt] " : "" )
			);

			if( Editor.ME!=null ) {
				final p = Editor.ME.project;
				debugPre("worlds="+p.worlds.length+ (p.worlds.length>0 ? " world[0].levels="+p.worlds[0].levels.length : "") );
				debugPre("curWorld="+Editor.ME.curWorld);
			}

			debug("-- Processes ----------------------------------------");
			for( line in dn.Process.rprintAll().split('\n') )
				debugPre(line);
		}
	}
}
