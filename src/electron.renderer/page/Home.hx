package page;

import hxd.Key;

class Home extends Page {
	public static var ME : Home;

	var pendingBackupChecks : Array<{ projectFp:dn.FilePath, jTarget:js.jquery.JQuery }> = [];

	public function new() {
		super();

		ME = this;
		var changeLog = Const.getChangeLog();
		var ver = Const.getAppVersionObj();
		loadPageTemplate("home", {
			app: Const.APP_NAME,
			majorVer: ver.major,
			minorVer: ver.minor,
			patchVer: ver.patch,
			buildDate: dn.MacroTools.getHumanBuildDate(),
			latestVer: changeLog.latest.version,
			latestDesc: changeLog.latest.title==null ? L.t._("Release notes") : '"'+changeLog.latest.title+'"',
			deepnightUrl: Const.DEEPNIGHT_DOMAIN,
			discordUrl: Const.DISCORD_URL,
			docUrl: Const.DOCUMENTATION_URL,
			websiteUrl : Const.HOME_URL,
			issueUrl : Const.ISSUES_URL,
			jsonUrl: Const.JSON_DOC_URL,
			email: Const.getContactEmail(),
		});
		App.ME.setWindowTitle();

		// Hide patch version if zero
		if( ver.patch!=0 )
			jPage.find("header .version").addClass("patchRelease");

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
		jPage.find(".samples").click( (_)->{
			if( settings.getUiStateBool(HideSamplesOnHome) )
				showSamples();
			else
				hideSamples();
		});
		jPage.find(".allSamples .hide").click( (_)->hideSamples() );
		jPage.find(".import").click( (ev)->onImport(ev) );
		jPage.find(".new").click( (_)->if( !cd.hasSetS("newLock",0.2) ) onNew() );

		if( !settings.getUiStateBool(HideSamplesOnHome) )
			showSamples(false);

		jPage.find(".support").click( (ev)->{
			var w = new ui.Modal();
			w.setAnchor(MA_Centered);
			w.loadTemplate("support", {
				app: Const.APP_NAME,
				itchUrl: Const.ITCH_IO_BUY_URL,
				gitHubSponsorUrl: Const.GITHUB_SPONSOR_URL,
				steamUrl: Const.STEAM_URL,
			});
			w.jContent.find("[data-link]").click((ev:js.jquery.Event)->{
				var jButton = ev.getThis();
				var url = jButton.attr("data-link");
				electron.Shell.openExternal(url);
			});
		});

		jPage.find("button.update").click((_)->{
			new ui.modal.dialog.Changelog();
		});

		jPage.find("button.settings").click( function(ev) {
			new ui.modal.dialog.EditAppSettings();
		});

		jPage.find("button.exit").click( function(ev) {
			App.ME.exit();
		});

		updateRecents();
		if( settings.v.lastProject!=null ) {
			settings.v.lastProject = null;
			settings.save();
		}

		// Quick search
		new ui.QuickSearch(false, jPage.find(".recentFiles, .recentDirs"), jPage.find(".search"));

		// Samples
		var path = JsTools.getSamplesDir();
		App.LOG.debug("samplesDir="+path);
		var files = NT.readDir(path);
		var jSamples = jPage.find(".allSamples");
		var jScroller = jSamples.children(".scroller");
		jScroller.on( "wheel", (ev:js.html.WheelEvent)->{
			var ev = (cast ev).originalEvent;
			jScroller.scrollLeft( jScroller.scrollLeft() + ev.deltaY );
			ev.preventDefault();
		});
		for(f in files) {
			var fp = dn.FilePath.fromFile(path+"/"+f);
			if( fp.extension!="ldtk" )
				continue;

			var jSample = new J('<div class="sample"/>');
			jSample.appendTo(jScroller);
			jSample.append('<div class="thumb" style="background-image:url($path/thumbs/${fp.fileName}.png)"></div>');
			var name = StringTools.replace( fp.fileName, "_", " " );
			jSample.append('<div class="name">$name</div>');
			jSample.click(_->{
				App.ME.loadProject( fp.full );
			});

			if( App.ME.recentProjectsContains(fp.full) )
				jSample.addClass("seen");
		}
	}


	function updateRecents() : Void {
		ui.Tip.clear();
		pendingBackupChecks = [];

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
			if( !App.ME.recentProjectsContains(backup.full) && NT.fileExists(backup.full) )
				recents.insert(i+1, backup.full);
			i++;
		}


		// List files
		var jRecentFiles = jPage.find("ul.recentFiles");
		jRecentFiles.empty();
		if( recents.length>0 )
			jRecentFiles.append('<li class="title">Recent projects</li>');

		var i = recents.length-1;
		while( i>=0 ) {
			var filePath = recents[i];
			var isBackupFile = filePath.indexOf( Const.BACKUP_NAME_SUFFIX )>=0;
			var jLi = new J('<li/>');

			try {
				var fp = dn.FilePath.fromFile(filePath);
				var col = App.ME.getRecentDirColor(fp.directory);
				if( App.ME.isInAppDir(filePath,true) )
					jLi.addClass("sample");
				if( App.ME.hasForcedDirColor(fp.directory) )
					jLi.css("background-color", col.toCssRgba(0.4));
				// jLi.css("background-color", col.toCssRgba(App.ME.hasForcedDirColor(fp.directory) ? 0.4 : 0.1));

				var jName = new J('<span class="fileName">${fp.fileName}</span>');
				jName.appendTo(jLi);
				jName.css("color", col.toWhite(0.4).toHex());

				var jDir = JsTools.makePath(fp.full, col.toWhite(0.6));
				jDir.appendTo(jLi);

				jLi.click( function(ev) {
					App.ME.loadProject(filePath);
				});

				if( !NT.fileExists(filePath) )
					jLi.addClass("missing");

				if( isBackupFile )
					jLi.addClass("crash");

				// Backups button (async)
				var jBackupWrapper = new J('<div class="backupWrapper"></div>');
				jBackupWrapper.appendTo(jLi);
				jBackupWrapper.append('<div class="icon loading"></div>');
				pendingBackupChecks.push({ projectFp:fp.clone(), jTarget:jBackupWrapper });

				var act : ui.modal.ContextMenu.ContextActions = [
					{
						label: L.t._("Load from this folder"),
						iconId: "open",
						cb: onLoad.bind( dn.FilePath.fromFile(filePath).directory ),
					},
					{
						label: L.t._("Locate file"),
						iconId: "locate",
						cb: JsTools.locateFile.bind(filePath, true),
					},
					{
						label: L.t._("Assign custom color"),
						iconId: "color",
						cb: ()->{
							var cp = new ui.modal.dialog.ColorPicker(Const.getNicePalette(), col);
							cp.onValidate = (c)->{
								App.ME.forceDirColor(fp.directory, c);
								updateRecents();
							}
						},
						separatorBefore: true,
					},
					{
						label: L.t._("Reset assigned color"),
						iconId: "color",
						show: ()->App.ME.hasForcedDirColor(fp.directory),
						cb: ()->{
							App.ME.forceDirColor(fp.directory);
							updateRecents();
						},
					},
					{
						label: L.t._("Remove from history"),
						show: ()->!isBackupFile,
						cb: ()->{
							App.ME.unregisterRecentProject(filePath);
							updateRecents();
						},
						separatorBefore: true,
					},
					{
						label: L._Delete(L.t._("Backup file")),
						show: ()->isBackupFile,
						cb: ()->{
							NT.removeFile(filePath);
							App.ME.unregisterRecentProject(filePath);
							updateRecents();
						}
					},
					{
						label: L.t._("Clear all history"),
						cb: ()->{
							App.ME.clearRecentProjects();
							updateRecents();
						}
					},
				];
				ui.modal.ContextMenu.attachTo(jLi, act );

				jLi.appendTo(jRecentFiles);
			}

			catch( e:Dynamic ) {
				App.LOG.error("Problem with recent file: "+filePath);
				jLi.remove();
			}


			i--;
		}


		// Trim common parts in dirs
		var dirs = settings.v.recentDirs.map( dir->dn.FilePath.fromDir(dir) );
		dirs.reverse();

		// List dirs
		var jRecentDirs = jPage.find("ul.recentDirs");
		jRecentDirs.empty();
		if( dirs.length>0 )
			jRecentDirs.append('<li class="title">Recent folders</li>');
		for(fp in dirs) {
			var jLi = new J('<li/>');
			try {

				if( !NT.fileExists(fp.directory) )
					jLi.addClass("missing");

				if( App.ME.isInAppDir(fp.full,true) )
					jLi.addClass("sample");

				var shortFp = dn.FilePath.fromDir( fp.directory );
				var col = App.ME.getRecentDirColor(fp.directory);
				jLi.css("background-color", col.toCssRgba(App.ME.hasForcedDirColor(fp.directory) ? 0.4 : 0.1));
				jLi.append( JsTools.makePath( shortFp.full, col.toWhite(0.6) ) );
				jLi.click( (_)->{
					if( NT.fileExists(fp.directory) )
						onLoad(fp.directory);
					else {
						App.ME.unregisterRecentDir(fp.directory);

						// Try to open parent
						fp.removeLastDirectory();
						if( NT.fileExists(fp.directory) )
							onLoad(fp.directory);
						else
							N.error("Removed lost folder from history");

						updateRecents();
					}
				});

				var actions : ui.modal.ContextMenu.ContextActions = [
					{
						label: L.t._("New project in this folder"),
						iconId: "new",
						cb: onNew.bind(fp.directory),
					},
					{
						label: L.t._("Locate folder"),
						iconId: "locate",
						cb: JsTools.locateFile.bind(fp.directory, false),
					},
					{
						label: L.t._("Assign custom color"),
						iconId: "color",
						cb: ()->{
							var cp = new ui.modal.dialog.ColorPicker(Const.getNicePalette(), col);
							cp.onValidate = (c)->{
								App.ME.forceDirColor(fp.directory, c);
								updateRecents();
							}
						},
						separatorBefore: true,
					},
					{
						label: L.t._("Reset assigned color"),
						iconId: "color",
						show: ()->App.ME.hasForcedDirColor(fp.directory),
						cb: ()->{
							App.ME.forceDirColor(fp.directory);
							updateRecents();
						},
					},
					{
						label: L.t._("Remove from history"),
						cb: ()->{
							App.ME.unregisterRecentDir(fp.directory);
							updateRecents();
						},
						separatorBefore: true,
					},
					{
						label: L.t._("Clear all folder history"),
						cb: ()->{
							App.ME.clearRecentDirs();
							updateRecents();
						}
					},
				];
				ui.modal.ContextMenu.attachTo(jLi, actions);

				jLi.appendTo(jRecentDirs);

			}
			catch(e:Dynamic) {
				App.LOG.error("Problem with recent dir: "+fp.full);
				jLi.remove();
			}
		}

		JsTools.parseComponents(jRecentFiles);
	}


	public function onLoad(?openPath:String) {
		if( openPath==null )
			openPath = App.ME.getDefaultDialogDir();
		dn.js.ElectronDialogs.openFile(["."+Const.FILE_EXTENSION,".json"], openPath, function(filePath) {
			App.ME.loadProject(filePath);
		});
	}


	function onImport(ev:js.jquery.Event) {
		var ctx = new ui.modal.ContextMenu(ev);
		ctx.addTitle( L.t._("Import a project from another app") );
		ctx.setAnchor( MA_JQuery(new J(ev.target)) );
		ctx.addAction({
			label: L.t._("Ogmo 3 project"),
			cb: ()->onImportOgmo(),
		});
	}

	function onImportOgmo() {
		var dir = settings.getUiDir("ImportOgmo", App.ME.getDefaultDialogDir());

		dn.js.ElectronDialogs.openFile([".ogmo"], dir, function(filePath) {
			settings.storeUiDir("ImportOgmo", dn.FilePath.extractDirectoryWithoutSlash(filePath,true));
			var i = new importer.OgmoLoader(filePath);
			ui.modal.MetaProgress.start("Importing OGMO 3 project...", 3);
			delayer.addS( ()->{
				var p = i.load();
				i.log.printAllToLog(App.LOG);
				if( p!=null ) {
					ui.modal.MetaProgress.advance();
					new ui.ProjectSaver(this, p, (ok)->{
						ui.modal.MetaProgress.advance();
						N.success("Success!");
						App.ME.loadProject(p.filePath.full, (ok)->ui.modal.MetaProgress.completeCurrent());
					});
				}
				else {
					ui.modal.MetaProgress.closeCurrent();
					new ui.modal.dialog.LogPrint(i.log);
					new ui.modal.dialog.Message(L.t._("Failed to import this Ogmo project. If you really need this, feel free to send me the Ogmo project file so I can check and fix the updater (see contact link)."));
				}
			}, 0.1);
		});
	}


	function showSamples(anim=true) {
		jPage.find(".files").addClass("hasSamples");
		if( anim )
			jPage.find(".allSamples").slideDown(100);
		else
			jPage.find(".allSamples").show();
		settings.setUiStateBool( HideSamplesOnHome, false );
	}


	function hideSamples() {
		jPage.find(".files").removeClass("hasSamples");
		jPage.find(".allSamples").slideUp(60);
		settings.setUiStateBool( HideSamplesOnHome, true );
	}


	public function onLoadSamples() {
		dn.js.ElectronDialogs.openFile(["."+Const.FILE_EXTENSION], JsTools.getSamplesDir(), function(filePath) {
			App.ME.loadProject(filePath);
		});
	}

	public function onNew(?openPath:String) {
		if( openPath==null )
			openPath = settings.getUiDir("NewProject", App.ME.getDefaultDialogDir());
		dn.js.ElectronDialogs.saveFileAs(["."+Const.FILE_EXTENSION], openPath, function(filePath) {
			var fp = dn.FilePath.fromFile(filePath);
			fp.extension = "ldtk";
			settings.storeUiDir("NewProject", fp.directory);

			function _createNew() {
				var p = data.Project.createEmpty(fp.full);

				var data = ui.ProjectSaver.prepareProjectSavingData(p);
				new ui.ProjectSaver(this, p, (success)->{
					if( success ) {
						N.msg("New project created: "+p.filePath.full);
						App.ME.loadPage( ()->new Editor(p), true );
					}
					else {
						N.error("Couldn't create this project file!");
					}
				});
			}

			// Check if file isn't in app dir
			if( App.ME.isInAppDir(fp.full, true) ) {
				new ui.modal.dialog.Choice(
					Lang.t._("<strong>WARNING:</strong> you are trying to create a project in the application directory!\n<strong>Any file saved here will be LOST during next app update.</strong>"),
					[
						{ label:"Create somewhere else", cb:onNew.bind(openPath) },
						{ label:"Ignore that (you will lose your project during next update)", className:"gray", cb:_createNew },
					]
				);
				return;
			}
			else
				_createNew();

		});
	}


	override function onKeyPress(keyCode:Int) {
		super.onKeyPress(keyCode);

		if( App.ME.isLocked() )
			return;

		switch keyCode {
			case K.W, K.Q:
				if( App.ME.isCtrlCmdDown() )
					App.ME.exit();

			case K.ENTER if( !ui.Modal.hasAnyOpen() ):
				jPage.find("ul.recentFiles li:not(.title):first").click();

			case K.ESCAPE:
				if( ui.Modal.hasAnyOpen() )
					ui.Modal.closeLatest();
				else if( jPage.find(".changelogsWrapper").hasClass("fullscreen") )
					jPage.find("button.fullscreen").click();

			// Open settings
			case K.F12 if( !App.ME.hasAnyToggleKeyDown() ):
				if( !ui.Modal.isOpen(ui.modal.dialog.EditAppSettings) )
					new ui.modal.dialog.EditAppSettings();
		}
	}


	override function update() {
		super.update();

		// Async lookup of backup dirs
		if( pendingBackupChecks.length>0 && !cd.hasSetS("asyncBackupCheck", 0.15) ) {
			var pb = pendingBackupChecks.shift();
			pb.jTarget.empty();

			// Parse project JSON
			var json : ldtk.Json.ProjectJson = try {
				var raw = NT.readFileString(pb.projectFp.full);
				haxe.Json.parse(raw);
			} catch(_) null;

			if( json!=null ) {
				// Check if backup files exist there
				var backupPath = pb.projectFp.directoryWithSlash + ( json.backupRelPath==null ? pb.projectFp.fileName+"/"+Const.BACKUP_DIR : json.backupRelPath );
				var all = ui.ProjectSaver.listBackupFiles(json.iid, backupPath);
				if( all.length>0 ) {
					var jBackups = new J('<button class="backups gray"/>');
					jBackups.appendTo(pb.jTarget);
					jBackups.append('<span class="icon history"/>');
					jBackups.click( (ev:js.jquery.Event)->{
						ev.stopPropagation();
						// List all backup files
						var ctx = new ui.modal.ContextMenu(ev);
						var crashBackups = [];
						for( b in all ) {
							if( b.crash )
								crashBackups.push(b.backup);

							ctx.addAction({
								label: ui.ProjectSaver.isCrashFile(b.backup.full) ? Lang.t._("Crash recovery"): Lang.relativeDate(b.date),
								className: b.crash ? "crash" : null,
								subText: Lang.date(b.date),
								cb: ()->App.ME.loadProject(b.backup.full, (p:data.Project)->{
									p.backupOriginalFile = pb.projectFp.clone();
								}),
							});
						}

						if( crashBackups.length>0 )
							ctx.addAction({
								label: L.t._("Delete all crash recovery files"),
								className: "warning",
								cb: ()->{
									new ui.modal.dialog.Confirm(
										L.t._("Delete all crash recovery files project ::name::?", { name: pb.projectFp.fileName}),
										true,
										()->{
											for(fp in crashBackups)
												NT.removeFile(fp.full);
											updateRecents();
										}
									);
								}
							});
					});
				}
			}


		}
	}
}
