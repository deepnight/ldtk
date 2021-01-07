package page;

import hxd.Key;

class Home extends Page {
	public static var ME : Home;

	public function new() {
		super();

		ME = this;
		loadPageTemplate("home", {
			app: Const.APP_NAME,
			appVer: Const.getAppVersion(),
			deepnightUrl: Const.DEEPNIGHT_DOMAIN,
			discordUrl: Const.DISCORD_URL,
			docUrl: Const.DOCUMENTATION_URL,
			websiteUrl : Const.HOME_URL,
			issueUrl : Const.ISSUES_URL,
			appChangelog: StringTools.htmlEscape( Const.APP_CHANGELOG_MD),
			jsonChangelog: StringTools.htmlEscape( Const.JSON_CHANGELOG_MD ),
			jsonFormat: StringTools.htmlEscape( Const.JSON_FORMAT_MD ),
		});
		App.ME.setWindowTitle();

		jPage.find(".changelogs code").each( function(idx,e) {
			var jCode = new J(e);
			if( (~/sample/i).match( jCode.text().toLowerCase() ) ) {
				var jLink = new J('<a href="#" class="discreet">${jCode.text()}</a>');
				jLink.click( function(ev:js.jquery.Event) {
					ev.preventDefault();
					onLoadSamples();
				});
				jCode.replaceWith(jLink);
			}
		});

		// Buttons
		jPage.find(".load").click( function(ev) {
			onLoad();
		});

		jPage.find(".samples").click( function(ev) {
			onLoadSamples();
		});

		jPage.find(".new").click( function(ev) {
			onNew();
		});

		// Debug menu
		#if debug
		jPage.find("button.settings").show().click( function(ev) {
			openDebugMenu();
		});
		#end

		jPage.find(".buy").click( (ev)->{
			var w = new ui.Modal();
			w.loadTemplate("buy", {
				app: Const.APP_NAME,
				itchUrl: Const.ITCH_IO_BUY_URL,
				gitHubSponsorUrl: Const.GITHUB_SPONSOR_URL,
			});
			w.jContent.find("[data-link]").click((ev:js.jquery.Event)->{
				var jButton = ev.getThis();
				var url = jButton.attr("data-link");
				electron.Shell.openExternal(url);
			});
		});

		var jFullscreenBt = jPage.find("button.fullscreen");
		var jChangelogs = jPage.find(".changelogsWrapper");

		jFullscreenBt.click( function(ev) {
			jChangelogs.toggleClass("fullscreen");
			var btIcon = jFullscreenBt.find(".icon");
			btIcon.removeClass();
			if( jChangelogs.hasClass("fullscreen") )
				btIcon.addClass("icon fullscreen_exit");
			else
				btIcon.addClass("icon fullscreen");
		});

		// jPage.find(".exit").click( function(ev) {
		// 	App.ME.exit(true);
		// });

		updateRecents();
	}

	#if debug
	function openDebugMenu() {
		var m = new ui.Modal();

		var jButton = new J('<button>Settings dir</button>');
		jButton.appendTo(m.jContent);
		jButton.click( (_)->JsTools.exploreToFile(JsTools.getSettingsDir(), false) );

		// Update all sample files
		var jButton = new J('<button>Update all samples</button>');
		jButton.click((_)->{
			m.close();
			var path = JsTools.getSamplesDir();
			var files = js.node.Fs.readdirSync(path);
			var log = new dn.Log();
			log.printOnAdd = true;
			var ops = [];
			for(f in files) {
				var fp = dn.FilePath.fromFile(path+"/"+f);
				if( fp.extension!="ldtk" )
					continue;

				ops.push({
					label: fp.fileName,
					cb: ()->{
						// Loading
						log.fileOp(fp.fileName+"...");
						log.general(" -> Loading...");
						try {
							var raw = JsTools.readFileString(fp.full);
							log.general(" -> Parsing...");
							var json = haxe.Json.parse(raw);
							var p = data.Project.fromJson(fp.full, json);

							// Tilesets
							log.general(" -> Updating tileset data...");
							for(td in p.defs.tilesets) {
								td.reloadImage(fp.directory);
								td.buildPixelData(()->{}, true);
							}

							// Auto layer rules
							log.general(" -> Updating auto-rules cache...");
							for(l in p.levels)
							for(li in l.layerInstances) {
								if( !li.def.isAutoLayer() )
									continue;
								li.applyAllAutoLayerRules();
							}

							log.general(" -> Saving "+fp.fileName+"...");
							var data = JsTools.prepareProjectFile(p);
							JsTools.writeFileString(fp.full, data.projectJson);
						}
						catch(e:Dynamic) {
							new ui.modal.dialog.Message("Failed on "+fp.fileName);
						}
					}
				});
			}
			new ui.modal.Progress("Updating samples", 1, ops);
		});
		m.jContent.append(jButton);
	}
	#end

	function updateRecents() {
		ui.Tip.clear();

		var recents = App.ME.settings.recentProjects.copy();

		// Automatically detects crash backups
		var i = 0;
		while( i<recents.length ) {
			var fp = dn.FilePath.fromFile(recents[i]);
			var crash = fp.clone();
			crash.fileName+=Const.CRASH_NAME_SUFFIX;
			if( !App.ME.recentProjectsContains(crash.full) && JsTools.fileExists(crash.full) ) {
				recents.insert(i+1, crash.full);
				// i++;
			}
			i++;
		}



		// Trim common path parts
		var trimmedPaths = recents.copy();

		// List drive letters
		var driveLetters = new Map();
		for(path in trimmedPaths ) {
			var d = dn.FilePath.fromFile(path).getDriveLetter();
			driveLetters.set(d,d);
		}

		// Trim paths beginnings, grouped by drive
		var splitPaths = trimmedPaths.map( function(p) return dn.FilePath.fromFile(p).getDirectoryAndFileArray() );
		for(d in driveLetters) {
			// List path indexes in original array
			var sameDriveIndexes = [];
			for(i in 0...trimmedPaths.length)
				if( dn.FilePath.fromFile( trimmedPaths[i] ).getDriveLetter() == d )
					sameDriveIndexes.push(i);

			// Trim while beginning is the same
			var trimMore = true;
			var trim = 0;
			while( trimMore ) {
				var firstIdx = sameDriveIndexes[0];
				for( idx in sameDriveIndexes )
					if( trim>=splitPaths[idx].length-2 || splitPaths[idx][trim] != splitPaths[firstIdx][trim] ) {
						trimMore = false;
						break;
					}
				if( trimMore )
					trim++;
			}

			// Apply trimming to array
			while( trim>0 ) {
				for( idx in sameDriveIndexes )
					splitPaths[idx].shift();
				trim--;
			}
		}
		trimmedPaths = splitPaths.map( arr->arr.join("/") );



		// List files
		var jRecentFiles = jPage.find("ul.recentFiles");
		jRecentFiles.empty();

		var i = recents.length-1;
		C.initUniqueColors();
		while( i>=0 ) {
			var filePath = recents[i];
			var isCrashFile = filePath.indexOf( Const.CRASH_NAME_SUFFIX )>=0;
			var li = new J('<li/>');
			li.appendTo(jRecentFiles);


			var fp = dn.FilePath.fromFile(filePath);
			var col = C.pickUniqueColorFor( dn.FilePath.fromDir(trimmedPaths[i]).getDirectoryArray()[0] );
			if( App.ME.isInAppDir(filePath,true) )
				li.addClass("sample");

			var jName = new J('<span class="fileName">${fp.fileName}</span>');
			jName.appendTo(li);
			jName.css("color", C.intToHex( C.toWhite(col, 0.7) ));

			var jDir = JsTools.makePath(trimmedPaths[i], C.toWhite(col, 0.3));
			// var jDir = new J('<span class="dir">${trimmedPaths[i]}</span>');
			jDir.appendTo(li);
			// jDir.css("color", C.intToHex( C.toWhite(col, 0.3) ));

			li.click( function(ev) {
				if( !App.ME.loadProject(filePath) )
					updateRecents();
			});

			if( !JsTools.fileExists(filePath) )
				li.addClass("missing");

			if( isCrashFile )
				li.addClass("crash");

			ui.modal.ContextMenu.addTo(li, [
				{
					label: L.t._("Load from this folder"),
					cond: null,
					cb: onLoad.bind( dn.FilePath.fromFile(filePath).directory ),
				},
				{
					label: L.t._("Locate file"),
					cond: null,
					cb: JsTools.exploreToFile.bind(filePath, true),
				},
				{
					label: L.t._("Remove from history"),
					cond: ()->!isCrashFile,
					cb: ()->{
						App.ME.unregisterRecentProject(filePath);
						updateRecents();
					}
				},
				{
					label: L.t._("Delete this crash backup file"),
					cond: ()->isCrashFile,
					cb: ()->{
						JsTools.removeFile(filePath);
						App.ME.unregisterRecentProject(filePath);
						updateRecents();
					}
				},
				{
					label: L.t._("Clear all history"),
					cond: null,
					cb: ()->{
						App.ME.clearRecentProjects();
						updateRecents();
					}
				},
			]);
			i--;
		}


		// Trim common parts
		var dirs = App.ME.settings.recentDirs.map( dir->dn.FilePath.fromDir(dir) );
		dirs.reverse();
		var trim = 0;
		var same = true;
		while( same && dirs.length>1 ) {
			for(i in 1...dirs.length) {
				if( dirs[0].directory.charAt(trim) != dirs[i].directory.charAt(trim) ) {
					same = false;
					break;
				}
			}
			if( same )
				trim++;
		}

		// List dirs
		var jRecentDirs = jPage.find("ul.recentDirs");
		jRecentDirs.empty();
		C.initUniqueColors();
		for(fp in dirs) {
			var li = new J('<li/>');
			li.appendTo(jRecentDirs);

			if( !JsTools.fileExists(fp.directory) )
				li.addClass("missing");

			li.append( JsTools.makePath( fp.directory.substr(trim) ) );
			li.click( (_)->{
				if( JsTools.fileExists(fp.directory) )
					onLoad(fp.directory);
				else {
					App.ME.unregisterRecentDir(fp.directory);

					// Try to open parent
					fp.removeLastDirectory();
					if( JsTools.fileExists(fp.directory) )
						onLoad(fp.directory);
					else
						N.error("Removed lost folder from history");

					updateRecents();
				}
			});

			ui.modal.ContextMenu.addTo(li, [
				{
					label: L.t._("Remove from history"),
					cond: null,
					cb: ()->{
						App.ME.unregisterRecentDir(fp.directory);
						updateRecents();
					}
				},
				{
					label: L.t._("Clear all folder history"),
					cond: null,
					cb: ()->{
						App.ME.clearRecentDirs();
						updateRecents();
					}
				},
			]);
		}

		JsTools.parseComponents(jRecentFiles);
	}


	public function onLoad(?openPath:String) {
		if( openPath==null )
			openPath = App.ME.getDefaultDialogDir();
		dn.electron.Dialogs.open(["."+Const.FILE_EXTENSION,".json"], openPath, function(filePath) {
			if( !App.ME.loadProject(filePath) )
				updateRecents();
		});
	}

	public function onLoadSamples() {
		dn.electron.Dialogs.open(["."+Const.FILE_EXTENSION], JsTools.getSamplesDir(), function(filePath) {
			App.ME.loadProject(filePath);
		});
	}

	public function onNew() {
		dn.electron.Dialogs.saveAs(["."+Const.FILE_EXTENSION], App.ME.getDefaultDialogDir(), function(filePath) {
			var fp = dn.FilePath.fromFile(filePath);
			fp.extension = "ldtk";

			var p = data.Project.createEmpty(fp.full);
			var data = JsTools.prepareProjectFile(p);
			JsTools.writeFileString(p.filePath.full, data.projectJson);

			N.msg("New project created: "+p.filePath.full);
			App.ME.loadPage( ()->new Editor(p) );
		});
	}


	override function onKeyPress(keyCode:Int) {
		super.onKeyPress(keyCode);

		switch keyCode {
			case K.W, K.Q:
				if( App.ME.isCtrlDown() )
					App.ME.exit();

			case K.ENTER:
				jPage.find("ul.recentFiles li:first").click();

			case K.ESCAPE:
				if( jPage.find(".changelogsWrapper").hasClass("fullscreen") )
					jPage.find("button.fullscreen").click();
		}
	}

}
