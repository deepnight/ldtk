package page;

import hxd.Key;

class Home extends Page {
	public static var ME : Home;

	public function new() {
		super();

		ME = this;
		var changeLog = Const.getChangeLog();
		loadPageTemplate("home", {
			app: Const.APP_NAME,
			appVer: Const.getAppVersion(),
			latestVer: changeLog.latest.version,
			latestDesc: changeLog.latest.title==null ? L.t._("Read latest changes") : '"'+changeLog.latest.title+'"',
			deepnightUrl: Const.DEEPNIGHT_DOMAIN,
			discordUrl: Const.DISCORD_URL,
			docUrl: Const.DOCUMENTATION_URL,
			websiteUrl : Const.HOME_URL,
			issueUrl : Const.ISSUES_URL,
			jsonUrl: Const.JSON_DOC_URL,
			email: Const.getContactEmail(),
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
		jPage.find(".load").click( (_)->onLoad() );
		jPage.find(".samples").click( (_)->onLoadSamples() );
		jPage.find(".loadOgmo").click( (ev)->onImportOgmo() );
		jPage.find(".new").click( (_)->if( !cd.hasSetS("newLock",0.2) ) onNew() );

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

		jPage.find("button.update").click((_)->{
			showLatestUpdate();
		});

		// Notify app update
		if( settings.v.lastKnownVersion!=Const.getAppVersion() ) {
			var prev = settings.v.lastKnownVersion;
			settings.v.lastKnownVersion = Const.getAppVersion();
			App.ME.settings.save();

			showLatestUpdate(true);
		}

		jPage.find("button.settings").click( function(ev) {
			new ui.modal.dialog.EditAppSettings();
		});

		updateRecents();
	}

	function showLatestUpdate(isNewUpdate=false) {
		var w = new ui.Modal();
		w.canBeClosedManually = !isNewUpdate;
		var latest = Const.getChangeLog().latest;
		var ver = new Version( Const.getAppVersion() );
		w.loadTemplate("appUpdated", {
			ver: latest.version.numbers,
			app: Const.APP_NAME,
			title: latest.title==null ? "" : '&ldquo;&nbsp;'+latest.title+'&nbsp;&rdquo;',
			md: latest.allNoteLines.join("\n"),
		});

		w.jContent.find(".changelog").click( (_)->N.notImplemented() );
		w.jContent.find(".close").click( (_)->w.close() );
	}


	function updateRecents() {
		ui.Tip.clear();
		var uniqueColorMix = 0x6066d3;

		// Clean up invalid paths
		settings.v.recentProjects = settings.v.recentProjects.filter( (p)->{
			if( p==null || p.length==0 )
				return false;

			var fp = dn.FilePath.fromFile(p);
			return fp!=null && fp.directory!=null && fp.fileWithExt!=null;
		});
		settings.v.recentDirs = settings.v.recentDirs.filter( (p)->{
			if( p==null || p.length==0 )
				return false;

			var fp = dn.FilePath.fromDir(p);
			return fp!=null && fp.directory!=null;
		});
		settings.save();



		var recents = settings.v.recentProjects.copy();


		// Automatically detect backups
		var i = 0;
		while( i<recents.length ) {
			var fp = dn.FilePath.fromFile(recents[i]);
			var backup = fp.clone();
			backup.fileName+=Const.BACKUP_NAME_SUFFIX;
			if( !App.ME.recentProjectsContains(backup.full) && JsTools.fileExists(backup.full) )
				recents.insert(i+1, backup.full);
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
		if( recents.length>0 )
			jRecentFiles.append('<li class="title">Recent projects</li>');

		var i = recents.length-1;
		C.initUniqueColors(12, uniqueColorMix);
		while( i>=0 ) {
			var filePath = recents[i];
			var isBackupFile = filePath.indexOf( Const.BACKUP_NAME_SUFFIX )>=0;
			var li = new J('<li/>');

			try {
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
					App.ME.loadProject(filePath);
				});

				if( !JsTools.fileExists(filePath) )
					li.addClass("missing");

				if( isBackupFile )
					li.addClass("crash");

				// Backups button
				if( ui.ProjectSaving.hasBackupFiles(filePath) ) {
					var all = ui.ProjectSaving.listBackupFiles(filePath);
					if( all.length>0 ) {
						var jBackups = new J('<button class="backups gray"/>');
						jBackups.appendTo(li);
						jBackups.append('<span class="icon history"/>');
						jBackups.click( (ev:js.jquery.Event)->{
							ev.stopPropagation();
							// List all backup files
							var ctx = new ui.modal.ContextMenu(ev);
							var crashBackups = [];
							for( b in all ) {
								if( b.crash )
									crashBackups.push(b.backup);

								ctx.add({
									label: ui.ProjectSaving.isCrashFile(b.backup.full) ? Lang.t._("Crash recovery"): Lang.relativeDate(b.date),
									className: b.crash ? "crash" : null,
									sub: Lang.date(b.date),
									cb: ()->App.ME.loadProject(b.backup.full)
								});
							}

							if( crashBackups.length>0 )
								ctx.add({
									label: L.t._("Delete all crash recovery files"),
									className: "warning",
									cb: ()->{
										new ui.modal.dialog.Confirm(
											L.t._("Delete all crash recovery files project ::name::?", { name: fp.fileName}),
											true,
											()->{
												for(fp in crashBackups)
													JsTools.removeFile(fp.full);
												updateRecents();
											}
										);
									}
								});
						});
					}
				}

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
						cond: ()->!isBackupFile,
						cb: ()->{
							App.ME.unregisterRecentProject(filePath);
							updateRecents();
						}
					},
					{
						label: L.t._("Delete this BACKUP file"),
						cond: ()->isBackupFile,
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


				li.appendTo(jRecentFiles);
			}

			catch( e:Dynamic ) {
				App.LOG.error("Problem with recent file: "+filePath);
				li.remove();
			}


			i--;
		}


		// Trim common parts in dirs
		var dirs = settings.v.recentDirs.map( dir->dn.FilePath.fromDir(dir) );
		dirs.reverse();
		var trim = 0;
		var same = true;
		while( same && dirs.length>1 ) {
			for(i in 1...dirs.length) {
				if( dirs[0].full.charAt(trim) != dirs[i].full.charAt(trim) ) {
					same = false;
					break;
				}
			}
			if( same )
				trim++;
		}
		if( dirs.length==1 && dirs[0].directory!=null )
			trim = dirs[0].full.lastIndexOf( dirs[0].slash() )+1;


		// List dirs
		var jRecentDirs = jPage.find("ul.recentDirs");
		jRecentDirs.empty();
		if( dirs.length>0 )
			jRecentDirs.append('<li class="title">Recent folders</li>');
		C.initUniqueColors(12, uniqueColorMix);
		for(fp in dirs) {
			var li = new J('<li/>');
			try {

				if( !JsTools.fileExists(fp.directory) )
					li.addClass("missing");

				if( App.ME.isInAppDir(fp.full,true) )
					li.addClass("sample");

				var shortFp = dn.FilePath.fromDir( fp.directory.substr(trim) );
				var col = C.toWhite( C.pickUniqueColorFor( shortFp.getDirectoryArray()[0] ), 0.3 );
				li.append( JsTools.makePath( shortFp.full, col ) );
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
						label: L.t._("Locate folder"),
						cond: null,
						cb: JsTools.exploreToFile.bind(fp.directory, false),
					},
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

				li.appendTo(jRecentDirs);

			}
			catch(e:Dynamic) {
				App.LOG.error("Problem with recent dir: "+fp.full);
				li.remove();
			}
		}

		JsTools.parseComponents(jRecentFiles);
	}


	public function onLoad(?openPath:String) {
		if( openPath==null )
			openPath = App.ME.getDefaultDialogDir();
		dn.electron.Dialogs.open(["."+Const.FILE_EXTENSION,".json"], openPath, function(filePath) {
			App.ME.loadProject(filePath);
		});
	}


	public function onImportOgmo() {
		var dir = App.ME.getDefaultDialogDir();

		#if debug
		dir = "C:/projects/LDtk/tests/ogmo"; // HACK remove this hard-coded path
		#end

		dn.electron.Dialogs.open([".ogmo"], dir, function(filePath) {
			var i = new importer.OgmoProject(filePath);
			new ui.modal.dialog.LockMessage(L.t._("Importing OGMO 3 project..."), ()->{
				var p = i.load();
				i.log.printAllToLog(App.LOG);
				if( p!=null ) {
					new ui.ProjectSaving(this, p, (ok)->{
						N.success("Success!");
						App.ME.loadProject(p.filePath.full);
					});
				}
				else {
					new ui.modal.dialog.LogPrint(i.log);
					new ui.modal.dialog.Message(L.t._("Failed to import this Ogmo project. If you really need this, feel free to send me the Ogmo project file so I can check and fix the updater (see contact link)."));
				}
			});
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
			var data = ui.ProjectSaving.prepareProjectSavingData(p);
			new ui.ProjectSaving(this, p, (success)->{
				if( success ) {
					N.msg("New project created: "+p.filePath.full);
					App.ME.loadPage( ()->new Editor(p) );
				}
				else {
					N.error("Couldn't create this project file!");
				}
			});
		});
	}


	override function onKeyPress(keyCode:Int) {
		super.onKeyPress(keyCode);

		if( App.ME.isLocked() )
			return;

		switch keyCode {
			case K.W, K.Q:
				if( App.ME.isCtrlDown() )
					App.ME.exit();

			case K.ENTER:
				jPage.find("ul.recentFiles li:not(.title):first").click();

			// Open settings
			case K.F12 if( !App.ME.hasAnyToggleKeyDown() ):
				if( !ui.Modal.isOpen(ui.modal.dialog.EditAppSettings) )
					new ui.modal.dialog.EditAppSettings();

			case K.ESCAPE:
				if( jPage.find(".changelogsWrapper").hasClass("fullscreen") )
					jPage.find("button.fullscreen").click();
		}
	}

}
