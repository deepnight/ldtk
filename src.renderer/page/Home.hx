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
						var raw = JsTools.readFileString(fp.full);
						log.general(" -> Parsing...");
						var json = haxe.Json.parse(raw);
						var p = data.Project.fromJson(json);

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
						JsTools.writeFileString(fp.full, data.jsonString);
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

		var jRecentList = jPage.find("ul.recents");
		jRecentList.empty();

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
		var i = recents.length-1;
		C.initUniqueColors();
		while( i>=0 ) {
			var p = recents[i];
			var isCrashFile = p.indexOf( Const.CRASH_NAME_SUFFIX )>=0;
			var li = new J('<li/>');
			li.appendTo(jRecentList);


			if( !App.ME.isInAppDir(p,true) ) {
				var bgCol = C.pickUniqueColorFor( dn.FilePath.fromDir(trimmedPaths[i]).getDirectoryArray()[0] );
				var textCol = C.toWhite(bgCol, 0.3);
				var jPath = new J('<div class="recentPath"/>');
				jPath.appendTo(li);
				var parts = trimmedPaths[i].split("/");
				var j = 0;
				for(d in parts) {
					if( j>0 ) {
						var jSlash = new J('<div class="slash">/</div>');
						jSlash.css({ color: C.intToHex(textCol) });
						jSlash.appendTo(jPath);
					}

					var jPart = new J('<div>$d</div>');
					jPart.appendTo(jPath);
					jPart.css({ color: C.intToHex(textCol) });

					if( j==0 ) {
						jPart.addClass("label");
						jPart.wrapInner('<span/>');
						jPart.find("span").css({ backgroundColor: C.intToHex(bgCol) });
					}
					else if( j<parts.length-1 ) {
						jPart.addClass("dir");
					}
					else if( j==parts.length-1 ) {
						jPart.addClass("file");
						jPart.html( '<span class="name">' + dn.FilePath.extractFileName(p) + '</span>' );
					}

					j++;
				}
			}
			else {
				// Sample file
				var jPath = new J('<div class="recentPath sample"/>');
				jPath.append('<div class="label"><span>${Const.APP_NAME} sample</span></div>');
				jPath.append('<div class="file"><span class="name">${dn.FilePath.extractFileName(p)}</span></div>');
				jPath.appendTo(li);
			}

			li.click( function(ev) {
				if( !App.ME.loadProject(p) )
					updateRecents();
			});

			if( !JsTools.fileExists(p) )
				li.addClass("missing");

			if( isCrashFile )
				li.addClass("crash");

			ui.modal.ContextMenu.addTo(li, [
				{
					label: L.t._("Locate file"),
					cond: null,
					cb: JsTools.exploreToFile.bind(p, true),
				},
				{
					label: L.t._("Remove from history"),
					cond: ()->!isCrashFile,
					cb: ()->{
						App.ME.unregisterRecentProject(p);
						updateRecents();
					}
				},
				{
					label: L.t._("Delete this crash backup file"),
					cond: ()->isCrashFile,
					cb: ()->{
						JsTools.removeFile(p);
						App.ME.unregisterRecentProject(p);
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

		JsTools.parseComponents(jRecentList);
	}


	public function onLoad() {
		dn.electron.Dialogs.open(["."+Const.FILE_EXTENSION,".json"], App.ME.getDefaultDialogDir(), function(filePath) {
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

			var p = data.Project.createEmpty();
			var data = JsTools.prepareProjectFile(p);
			JsTools.writeFileString(fp.full, data.jsonString);

			N.msg("New project created: "+fp.full);
			App.ME.loadPage( ()->new Editor(p, fp.full) );
		});
	}


	override function onKeyPress(keyCode:Int) {
		super.onKeyPress(keyCode);

		switch keyCode {
			case K.W, K.Q:
				if( App.ME.isCtrlDown() )
					App.ME.exit();

			case K.ENTER:
				jPage.find("ul.recents li:first").click();

			case K.ESCAPE:
				if( jPage.find(".changelogsWrapper").hasClass("fullscreen") )
					jPage.find("button.fullscreen").click();
		}
	}

}
