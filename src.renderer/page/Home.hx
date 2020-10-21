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
			deepnightUrl: Const.DEEPNIGHT_URL,
			jsonDocUrl: Const.JSON_DOC_URL,
			docUrl: Const.DOCUMENTATION_URL,
			websiteUrl : Const.WEBSITE_URL,
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

	function updateRecents() {
		ui.Tip.clear();

		var jRecentList = jPage.find("ul.recents");
		jRecentList.empty();

		var recents = App.ME.session.recentProjects;


		// Trim common path parts
		var trimmedPaths = recents.copy();
		if( trimmedPaths.length==1 ) {
			trimmedPaths[0] = dn.FilePath.fromFile( trimmedPaths[0] ).fileWithExt;
		}
		else if( trimmedPaths.length>1 ) {
			var splitPaths = trimmedPaths.map( function(p) return dn.FilePath.fromFile(p).getDirectoryAndFileArray() );

			var same = true;
			var trim = 0;
			while( same ) {
				for( i in 1...splitPaths.length )
					if( trim>=splitPaths[0].length || splitPaths[0][trim] != splitPaths[i][trim] ) {
						same = false;
						break;
					}
				if( same )
					trim++;
			}

			for(i in 0...trim)
			for(p in splitPaths)
				p.shift();

			trimmedPaths = splitPaths.map( function(p) return p.join("/") );
		}

		var i = recents.length-1;
		while( i>=0 ) {
			var p = recents[i];
			var li = new J('<li/>');
			li.appendTo(jRecentList);

			if( i==recents.length-1 )
				li.append( JsTools.createKey(K.ENTER) );

			// var jRemove = new J('<button class="remove dark">x</button>');
			// jRemove.attr("title",Lang.t._("Remove from history"));
			// var remIdx = i;
			// jRemove.click( function(_) {
			// 	App.ME.unregisterRecentProject(p);
			// 	updateRecents();
			// });
			// li.append( jRemove );

			li.append( JsTools.makePath(trimmedPaths[i], C.fromStringLight(dn.FilePath.fromFile(trimmedPaths[i]).directory)) );
			// li.append( JsTools.makeExploreLink(p) );

			li.click( function(ev) loadProject(p) );

			if( !JsTools.fileExists(p) )
				li.addClass("missing");

			ui.modal.ContextMenu.addTo(li, [
				{
					label: L.t._("Locate file"),
					cb: JsTools.exploreToFile.bind(p),
				},
				{
					label: L.t._("Remove from history"),
					cb: ()->{
						App.ME.unregisterRecentProject(p);
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
			]);
			i--;
		}

		JsTools.parseComponents(jRecentList);
	}


	public function onLoad() {
		dn.electron.Dialogs.open([".json"], App.ME.getDefaultDialogDir(), function(filePath) {
			loadProject(filePath);
		});
	}

	public function onLoadSamples() {
		var path = JsTools.getExeDir()+"/samples";
		dn.electron.Dialogs.open([".json"], path, function(filePath) {
			loadProject(filePath);
		});
	}

	function loadProject(filePath:String) {
		if( !JsTools.fileExists(filePath) ) {
			N.error("File not found: "+filePath);
			App.ME.unregisterRecentProject(filePath);
			updateRecents();
			return false;
		}

		// Parse
		var json = null;
		var p = #if !debug try #end {
			var raw = JsTools.readFileString(filePath);
			json = haxe.Json.parse(raw);
			data.Project.fromJson(json);
		}
		#if !debug
		catch(e:Dynamic) {
			N.error( Std.string(e) );
			null;
		}
		#end

		if( p==null ) {
			N.error("Couldn't read project file!");
			return false;
		}

		// Open it
		App.ME.loadPage( ()->new page.Editor(p, filePath) );
		N.success("Loaded project: "+dn.FilePath.extractFileWithExt(filePath));
		return true;
	}

	public function onNew() {
		dn.electron.Dialogs.saveAs([".json"], App.ME.getDefaultDialogDir(), function(filePath) {
			var fp = dn.FilePath.fromFile(filePath);
			fp.extension = "json";

			var p = data.Project.createEmpty();
			var data = JsTools.prepareProjectFile(p);
			JsTools.writeFileBytes(fp.full, data.bytes);

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
