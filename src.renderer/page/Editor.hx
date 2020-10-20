package page;

class Editor extends Page {
	public static var ME : Editor;

	public var jMainPanel(get,never) : J; inline function get_jMainPanel() return new J("#mainPanel");
	public var jInstancePanel(get,never) : J; inline function get_jInstancePanel() return new J("#instancePanel");
	public var jLayerList(get,never) : J; inline function get_jLayerList() return new J("#layers");
	public var jPalette(get,never) : J; inline function get_jPalette() return jMainPanel.find("#mainPaletteWrapper");
	var jMouseCoords : js.jquery.JQuery;

	public var curLevel(get,never) : data.Level;
		inline function get_curLevel() return project.getLevel(curLevelId);

	public var curLayerDef(get,never) : Null<data.def.LayerDef>;
		inline function get_curLayerDef() return project.defs.getLayerDef(curLayerDefUid);

	public var curLayerInstance(get,never) : Null<data.inst.LayerInstance>;
		function get_curLayerInstance() return curLayerDef==null ? null : curLevel.getLayerInstance(curLayerDef);


	public var ge : GlobalEventDispatcher;
	public var watcher : misc.FileWatcher;
	public var project : data.Project;
	public var projectFilePath : String;
	public var curLevelId : Int;
	var curLayerDefUid : Int;

	// Tools
	public var curTool(get,never) : tool.LayerTool<Dynamic>;
	public var selectionTool: tool.SelectionTool;
	var allLayerTools : Map<Int,tool.LayerTool<Dynamic>> = new Map();
	var specialTool : Null< Tool<Dynamic> >; // if not null, will be used instead of default tool
	var doNothingTool : tool.lt.DoNothing;

	var gridSnapping = true;
	public var needSaving = false;
	public var singleLayerMode(default,null) = false;
	public var emptySpaceSelection(default,null) = true;

	public var levelRender : display.LevelRender;
	public var rulers : display.Rulers;
	var bg : h2d.Bitmap;
	public var cursor : ui.Cursor;

	var levelHistory : Map<Int,LevelHistory> = new Map();
	public var curLevelHistory(get,never) : LevelHistory;
		inline function get_curLevelHistory() return levelHistory.get(curLevelId);


	public function new(p:data.Project, path:String) {
		super();

		loadPageTemplate("editor");

		ME = this;
		createRoot(parent.root);
		projectFilePath = path;
		App.ME.registerRecentProject(path);

		// Events
		App.ME.jBody
			.on("mouseup.client", function(_) onMouseUp() )
			.on("mouseleave.client", function(_) onMouseUp() );

		Boot.ME.s2d.addEventListener( onHeapsEvent );

		ge = new GlobalEventDispatcher();
		ge.addGlobalListener( onGlobalEvent );

		watcher = new misc.FileWatcher();

		cursor = new ui.Cursor();
		cursor.canChangeSystemCursors = true;

		levelRender = new display.LevelRender();
		rulers = new display.Rulers();

		selectionTool = new tool.SelectionTool();
		doNothingTool = new tool.lt.DoNothing();

		initUI();
		updateCanvasSize();

		selectProject(p);
		needSaving = false;
	}

	function initUI() {
		jMouseCoords = new J('<div id="mouseCoords"/>');
		App.ME.jBody.append(jMouseCoords);

		// Edit buttons
		jMainPanel.find("button.editProject").click( function(_) {
			if( ui.Modal.isOpen(ui.modal.panel.EditProject) )
				ui.Modal.closeAll();
			else
				new ui.modal.panel.EditProject();
		});

		jMainPanel.find("button.levelList").click( function(_) {
			if( ui.Modal.isOpen(ui.modal.panel.LevelList) )
				ui.Modal.closeAll();
			else
				new ui.modal.panel.LevelList();
		});

		jMainPanel.find("button.editLayers").click( function(_) {
			if( ui.Modal.isOpen(ui.modal.panel.EditLayerDefs) )
				ui.Modal.closeAll();
			else
				new ui.modal.panel.EditLayerDefs();
		});

		jMainPanel.find("button.editEntities").click( function(_) {
			if( ui.Modal.isOpen(ui.modal.panel.EditEntityDefs) )
				ui.Modal.closeAll();
			else
				new ui.modal.panel.EditEntityDefs();
		});

		jMainPanel.find("button.editTilesets").click( function(_) {
			if( ui.Modal.isOpen(ui.modal.panel.EditTilesetDefs) )
				ui.Modal.closeAll();
			else
				new ui.modal.panel.EditTilesetDefs();
		});

		jMainPanel.find("button.editEnums").click( function(_) {
			if( ui.Modal.isOpen(ui.modal.panel.EditEnums) )
				ui.Modal.closeAll();
			else
				new ui.modal.panel.EditEnums();
		});


		jMainPanel.find("button.close").click( function(ev) onClose(ev.getThis()) );


		jMainPanel.find("button.showHelp").click( function(_) {
			onHelp();
		});


		// Option checkboxes
		var chk = jMainPanel.find("input#singleLayerMode")
			.prop("checked", singleLayerMode)
			.change( function(ev) {
				setSingleLayerMode( ev.getThis().prop("checked") );
			});
		if( singleLayerMode )
			chk.parent().addClass("checked");

		var chk = jMainPanel.find("input#emptySpaceSelection")
			.prop("checked", emptySpaceSelection)
			.change( function(ev) {
				setEmptySpaceSelection( ev.getThis().prop("checked") );
			});
		if( emptySpaceSelection )
			chk.parent().addClass("checked");

		var chk = jMainPanel.find("input#gridSnapping")
			.prop("checked", gridSnapping)
			.change( function(ev) {
				setGridSnapping( ev.getThis().prop("checked") );
			});
		if( gridSnapping )
			chk.parent().addClass("checked");

		// Space bar blocking
		new J(js.Browser.window).off().keydown( function(ev) {
			var e = new J(ev.target);
			if( ev.keyCode==K.SPACE && !e.is("input") && !e.is("textarea") )
				ev.preventDefault();
		});
	}


	public function getProjectDir() {
		return dn.FilePath.fromFile( projectFilePath ).directory;
	}

	public function makeRelativeFilePath(filePath:String) {
		var relativePath = dn.FilePath.fromFile( filePath );
		relativePath.makeRelativeTo( getProjectDir() );
		return relativePath.full;
	}

	public function makeAbsoluteFilePath(relPath:String) {
		var fp = dn.FilePath.fromFile(relPath);
		return fp.hasDriveLetter()
			? fp.full
			: dn.FilePath.fromFile( getProjectDir() +"/"+ relPath ).full;
	}

	public function selectProject(p:data.Project) {
		watcher.clearAllWatches();
		ui.modal.Dialog.closeAll();

		project = p;
		project.tidy();

		// Check external enums
		for( relPath in project.defs.getExternalEnumPaths() ) {
			if( !JsTools.fileExists( makeAbsoluteFilePath(relPath) ) ) {
				// File not found
				new ui.modal.dialog.LostFile(relPath, function(newAbsPath) {
					var newRel = makeRelativeFilePath(newAbsPath);
					importer.HxEnum.load(newRel, true);
				});
			}
			else {
				// Verify checksum
				var f = JsTools.readFileString( makeAbsoluteFilePath(relPath) );
				var checksum = haxe.crypto.Md5.encode(f);
				for(ed in project.defs.getAllExternalEnumsFrom(relPath) )
					if( ed.externalFileChecksum!=checksum ) {
						new ui.modal.dialog.ExternalFileChanged(relPath, function() {
							importer.HxEnum.load(relPath, true);
						});
						break;
					}
			}
		}


		curLevelId = project.levels[0].uid;
		curLayerDefUid = -1;

		// Pick 1st layer in current level
		if( project.defs.layers.length>0 ) {
			for(li in curLevel.layerInstances) {
				selectLayerInstance(li,false);
				break;
			}
		}

		levelHistory = new Map();
		levelHistory.set( curLevelId, new LevelHistory(curLevelId) );

		// Load tilesets
		for(td in project.defs.tilesets)
			reloadTileset(td, true);

		ge.emit(ProjectSelected);

		// Tileset image hot-reloading
		for( td in project.defs.tilesets )
			watcher.watchTileset(td);

		selectionTool.clear();
		checkAutoLayersCache( (anychange)->{
			if( anychange )
				needSaving = true;
		});
	}


	public function checkAutoLayersCache(onDone:(anyChange:Bool)->Void) {
		var ops = [];

		for(l in project.levels)
		for(li in l.layerInstances)
			if( li.def.isAutoLayer() && li.autoTilesCache==null )
				ops.push({
					label: l.identifier+"."+li.def.identifier,
					cb: li.applyAllAutoLayerRules,
				});

		if( ops.length>0 )
			new ui.modal.Progress("Updating auto-layers...", ops, onDone.bind(true));
		else if( onDone!=null )
			onDone(false);
	}


	public function reloadTileset(td:data.def.TilesetDef, silentOk=false) {
		if( !td.hasAtlasPath() )
			return;

		var oldRelPath = td.relPath;
		var result = td.reloadImage( getProjectDir() );

		switch result {
			case FileNotFound:
				new ui.modal.dialog.LostFile( oldRelPath, function(newAbsPath) {
					var newRelPath = makeRelativeFilePath(newAbsPath);
					td.importAtlasImage( getProjectDir(), newRelPath );
					ge.emit( TilesetDefChanged(td) );
					levelRender.invalidateAll();
				});

			case RemapLoss:
				var name = dn.FilePath.fromFile(td.relPath).fileWithExt;
				new ui.modal.dialog.Warning( Lang.t._("The image ::file:: was updated, but the new version is smaller than the previous one.\nSome tiles might have been lost in the process. It is recommended to check this carefully before saving this project!", { file:name } ) );

			case TrimmedPadding:
				var name = dn.FilePath.fromFile(td.relPath).fileWithExt;
				new ui.modal.dialog.Message( Lang.t._("\"::file::\" image was modified but it was SMALLER than the old version.\nLuckily, the tileset had some PADDING, so I was able to use it to compensate the difference.\nSo everything is ok, have a nice day ♥️", { file:name } ), "tile" );

			case Ok:
				if( !silentOk ) {
					var name = dn.FilePath.fromFile(td.relPath).fileWithExt;
					N.success(Lang.t._("Tileset image ::file:: updated.", { file:name } ) );
				}

			case RemapSuccessful:
				var name = dn.FilePath.fromFile(td.relPath).fileWithExt;
				new ui.modal.dialog.Message( Lang.t._("Tileset image \"::file::\" was reloaded and is larger than the old one.\nTiles coordinates were remapped, everything is ok :)", { file:name } ), "tile" );
		}

		ge.emit(TilesetDefChanged(td));
	}

	inline function hasInputFocus() {
		return App.ME.jBody.find("input:focus, textarea:focus").length>0;
	}

	override function onKeyPress(keyCode:Int) {
		super.onKeyPress(keyCode);

		if( ui.Modal.hasAnyUnclosable() )
			return;

		switch keyCode {
			case K.ESCAPE:
				if( hasInputFocus() )
					App.ME.jBody.find(":focus").blur();
				else if( ui.modal.ContextMenu.isOpen() )
					ui.modal.ContextMenu.ME.close();
				else if( specialTool!=null )
					clearSpecialTool();
				else if( ui.Modal.hasAnyOpen() )
					ui.Modal.closeAll();
				else if( selectionTool.any() ) {
					ui.EntityInstanceEditor.close();
					selectionTool.clear();
				}
				else if( ui.EntityInstanceEditor.isOpen() )
					ui.EntityInstanceEditor.close();

			case K.TAB:
				if( !ui.Modal.hasAnyOpen() ) {
					App.ME.jPage.toggleClass("compactPanel");
					updateCanvasSize();
					updateAppBg();
				}

			case K.Z:
				if( !hasInputFocus() && !ui.Modal.hasAnyOpen() && App.ME.isCtrlDown() )
					curLevelHistory.undo();

			case K.Y:
				if( !hasInputFocus() && !ui.Modal.hasAnyOpen() && App.ME.isCtrlDown() )
					curLevelHistory.redo();

			case K.S:
				if( !hasInputFocus() && App.ME.isCtrlDown() )
					if( App.ME.isShiftDown() )
						onSaveAs();
					else
						onSave();

			case K.F if( !hasInputFocus() && !App.ME.hasAnyToggleKeyDown() ):
				levelRender.fit();

			case K.R if( !hasInputFocus() && !App.ME.hasAnyToggleKeyDown() && curLayerInstance.def.isAutoLayer() ):
				levelRender.toggleAutoLayerRendering(curLayerInstance);
				N.quick( "Auto-layer rendering: "+( levelRender.autoLayerRenderingEnabled(curLayerInstance) ? "ON" : "off" ));

			case K.R if( !hasInputFocus() && App.ME.isShiftDown() ):
				var state : Null<Bool> = null;
				for(li in curLevel.layerInstances)
					if( li.def.isAutoLayer() ) {
						if( state==null )
							state = !levelRender.autoLayerRenderingEnabled(li);
						levelRender.setAutoLayerRendering(li, state);
					}
				N.quick( "All auto-layers rendering: "+( state ? "ON" : "off" ));

			case K.W if( App.ME.isCtrlDown() ):
				onClose();

			case K.Q if( App.ME.isCtrlDown() ):
				App.ME.exit();

			case K.E if( !hasInputFocus() && !App.ME.hasAnyToggleKeyDown() ):
				setEmptySpaceSelection( !emptySpaceSelection );

			case K.A if( !hasInputFocus() && !App.ME.hasAnyToggleKeyDown() ):
				setSingleLayerMode( !singleLayerMode );

			case K.A if( !hasInputFocus() && App.ME.isCtrlDown() ):
				if( singleLayerMode )
					selectionTool.selectAllInLayers(curLevel, [curLayerInstance]);
				else
					selectionTool.selectAllInLayers(curLevel, curLevel.layerInstances);

				if( !selectionTool.isEmpty() ) {
					if( singleLayerMode )
						N.quick( L.t._("Selected all in layer") );
					else
						N.quick( L.t._("Selected all") );
				}
				else
					N.error("Nothing to select");

			case K.L if( !hasInputFocus() && !App.ME.hasAnyToggleKeyDown() && layerSupportsFreeMode() ):
				setGridSnapping( !gridSnapping );

			case K.G if( !hasInputFocus() && !App.ME.hasAnyToggleKeyDown() ):
				levelRender.toggleGrid();
				N.quick( "Show grid: "+( levelRender.isGridVisible() ? "ON" : "off" ));

			case K.H if( !hasInputFocus() ):
				onHelp();

			case k if( k>=48 && k<=57 && !hasInputFocus() ):
				var idx = k==48 ? 9 : k-49;
				if( idx < curLevel.layerInstances.length )
					selectLayerInstance( curLevel.layerInstances[idx] );

			case k if( k>=K.F1 && k<=K.F6 && !hasInputFocus() ):
				jMainPanel.find("#mainBar .buttons button:nth-of-type("+(k-K.F1+1)+")").click();

			#if debug

			case K.T:
				if( !hasInputFocus() ) {
					// var t = haxe.Timer.stamp();
					// var json = curLevel.toJson();
					// App.ME.debug("level.toJson() => "+dn.M.pretty(haxe.Timer.stamp()-t, 3)+"s");

					// var t = haxe.Timer.stamp();
					// for( li in curLevel.layerInstances )
						// li.applyAllAutoLayerRules();
					// App.ME.debug("all curLevel rules => "+dn.M.pretty(haxe.Timer.stamp()-t, 3)+"s");
					// for(l in project.levels)
					// for(li in l.layerInstances)
					// 	li.autoTilesCache = null;
					// N.debug("cleared caches");
				}

			case K.U if( !hasInputFocus() && App.ME.isShiftDown() && App.ME.isCtrlDown() ):
				dn.electron.ElectronUpdater.emulate();

			#end
		}

		// Propagate to tools
		if( !hasInputFocus() && !ui.Modal.hasAnyOpen() ) {
			if( isSpecialToolActive() )
				specialTool.onKeyPress(keyCode);
			else {
				selectionTool.onKeyPress(keyCode);
				curTool.onKeyPress(keyCode);
			}
		}
	}


	function get_curTool() : tool.LayerTool<Dynamic> {
		if( curLayerDef==null )
			return doNothingTool;

		if( !allLayerTools.exists(curLayerDef.uid) ) {
			var t : tool.LayerTool<Dynamic> = switch curLayerDef.type {
				case AutoLayer: new tool.lt.DoNothing();
				case IntGrid: new tool.lt.IntGridTool();
				case Entities: new tool.lt.EntityTool();
				case Tiles: new tool.lt.TileTool();
			}
			t.initPalette();
			allLayerTools.set( curLayerInstance.layerDefUid, t );
		}

		return allLayerTools.get( curLayerDef.uid );
	}

	function resetTools() {
		for(t in allLayerTools)
			t.destroy();
		allLayerTools = new Map();
		updateTool();
	}

	function updateTool() {
		// clearSelection();
		for(t in allLayerTools)
			t.pause();

		if( ui.modal.ToolPalettePopOut.isOpen() )
			ui.modal.ToolPalettePopOut.ME.close();

		cursor.set(None);
		curTool.onToolActivation();
	}

	public function clearSpecialTool() {
		if( specialTool!=null ) {
			specialTool.destroy();
			specialTool = null;
			updateTool();
		}
	}

	public inline function isSpecialToolActive(?tClass:Class<Tool<Dynamic>>) {
		return specialTool!=null && !specialTool.destroyed
			&& ( tClass==null || Std.is(specialTool, tClass) );
	}

	public function setSpecialTool(t:Tool<Dynamic>) {
		clearSpecialTool();
		specialTool = t;
		updateTool();
	}

	public function getGenericLevelElementAt(levelX:Int, levelY:Int, limitToActiveLayer=false) : Null<GenericLevelElement> {
		function getElement(li:data.inst.LayerInstance) {
			var ge : GenericLevelElement = null;

			if( !levelRender.isLayerVisible(li) )
				return null;

			var layerX = levelX - li.pxOffsetX;
			var layerY = levelY - li.pxOffsetY;
			var cx = Std.int( layerX / li.def.gridSize );
			var cy = Std.int( layerY / li.def.gridSize );

			switch li.def.type {
				case IntGrid:
					if( li.getIntGrid(cx,cy)>=0 )
						ge = GenericLevelElement.GridCell( li, cx, cy );

				case AutoLayer:

				case Entities:
					for(ei in li.entityInstances) {
						if( ei.isOver(layerX, layerY, 0) )
							ge = GenericLevelElement.Entity(li, ei);
						else {
							// Points
							for(fi in ei.fieldInstances) {
								if( fi.def.type!=F_Point )
									continue;
								for(i in 0...fi.getArrayLength()) {
									var pt = fi.getPointGrid(i);
									if( pt!=null && cx==pt.cx && cy==pt.cy )
										ge = GenericLevelElement.PointField(li, ei, fi, i);
								}
							}
						}
					}

				case Tiles:
					if( li.getGridTile(cx,cy)!=null )
						ge = GenericLevelElement.GridCell(li, cx, cy);
			}
			return ge;
		}


		if( limitToActiveLayer )
			return getElement(curLayerInstance);
		else {
			// Search in all layers
			var all = project.defs.layers.copy();
			all.reverse();
			var best = null;
			for(ld in all) {
				var ge = getElement( curLevel.getLayerInstance(ld) );
				if( ld==curLayerDef && ge!=null && singleLayerMode ) // prioritize active layer
					return ge;

				if( ge!=null )
					best = ge;
			}

			return best;
		}
	}

	function onHeapsEvent(e:hxd.Event) {
		switch e.kind {
			case EPush: onMouseDown(e);
			case ERelease: onMouseUp();
			case EMove: onMouseMove(e);
			case EOver:
			case EOut: onMouseUp();
			case EWheel: onMouseWheel(e);
			case EFocus:
			case EFocusLost: onMouseUp();
			case EKeyDown:
			case EKeyUp:
			case EReleaseOutside: onMouseUp();
			case ETextInput:
			case ECheck:
		}
	}

	function onMouseDown(e:hxd.Event) {
		var m = getMouse();
		if( App.ME.isAltDown() || selectionTool.isOveringSelection(m) && e.button==0 )
			selectionTool.startUsing( m, e.button );
		else if( isSpecialToolActive() )
			specialTool.startUsing( m, e.button )
		else
			curTool.startUsing( m, e.button );

		rulers.onMouseDown( m, e.button );
	}

	function onMouseUp() {
		var m = getMouse();

		// Tool updates
		if( selectionTool.isRunning() )
			selectionTool.stopUsing( m );
		else if( isSpecialToolActive() && specialTool.isRunning() )
			specialTool.stopUsing( m );
		else if( curTool.isRunning() )
			curTool.stopUsing( m );

		rulers.onMouseUp( m );
	}

	function onMouseMove(e:hxd.Event) {
		var m = getMouse();

		// Tool updates
		if( App.ME.isAltDown() || selectionTool.isRunning() || selectionTool.isOveringSelection(m) && !curTool.isRunning() )
			selectionTool.onMouseMove(m);
		else if( isSpecialToolActive() )
			specialTool.onMouseMove(m);
		else
			curTool.onMouseMove(m);
		rulers.onMouseMove(m);

		// Mouse coords infos
		jMouseCoords.empty();
		if( curLayerInstance!=null )
			jMouseCoords.append('<span>Grid = ${m.cx},${m.cy}</span>');
		// jMouseCoords.append('<span>Layer = ${m.layerX},${m.layerY}</span>');
		jMouseCoords.append('<span>Level = ${m.levelX},${m.levelY}</span>');

		// Overed element infos in footer
		var overed = getGenericLevelElementAt(m.levelX, m.levelY, singleLayerMode);
		switch overed { // TODO move that to SelectionTool
			case null:
			case GridCell(li, cx, cy):
				if( li.hasAnyGridValue(cx,cy) )
					switch li.def.type {
						case IntGrid:
							var v = li.getIntGrid(cx,cy);
							var c = C.intToHex( C.toWhite( li.def.getIntGridValueColor(v), 0.66 ) );
							jMouseCoords.prepend('<span style="color:$c">${ li.def.getIntGridValueDisplayName(v) } (IntGrid)</span>');

						case Tiles:
							jMouseCoords.prepend('<span>${ li.getGridTile(cx,cy) } (Tile)</span>');

						case Entities:
						case AutoLayer:
					}

			case Entity(li, ei):
				var c = C.intToHex( C.toWhite( ei.def.color, 0.66 ) );
				jMouseCoords.prepend('<span style="color:$c">${ ei.def.identifier } (Entity)</span>');

			case PointField(li, ei, fi, arrayIdx):
				var c = C.intToHex( C.toWhite( ei.def.color, 0.66 ) );
				jMouseCoords.prepend('<span style="color:$c">${ ei.def.identifier }.${ fi.def.identifier } (Entity point)</span>');
		}
	}

	function onMouseWheel(e:hxd.Event) {
		var m = getMouse();
		var oldLevelX = m.levelX;
		var oldLevelY = m.levelY;

		levelRender.deltaZoom( -e.wheelDelta*0.1 );
		ge.emit(ViewportChanged);

		levelRender.focusLevelX += ( oldLevelX - m.levelX );
		levelRender.focusLevelY += ( oldLevelY - m.levelY );
	}

	public function selectLevel(l:data.Level) {
		if( curLevelId==l.uid )
			return;

		curLevelId = l.uid;
		ge.emit(LevelSelected);
	}

	public function selectLayerInstance(li:data.inst.LayerInstance, notify=true) {
		if( curLayerDefUid==li.def.uid )
			return;

		if( notify )
			N.quick(li.def.identifier, JsTools.createLayerTypeIcon2(li.def.type));

		curLayerDefUid = li.def.uid;
		ge.emit(LayerInstanceSelected);

		setGridSnapping(gridSnapping, false); // update checkbox
	}

	function layerSupportsFreeMode() {
		return switch curLayerDef.type {
			case IntGrid: false;
			case AutoLayer: false;
			case Entities: true;
			case Tiles: false;
		}
	}

	public function getGridSnapping() {
		return gridSnapping || !layerSupportsFreeMode();
	}

	public function setGridSnapping(v:Bool, notify=true) {
		gridSnapping= v;

		var chk = jMainPanel.find("input#gridSnapping").prop("checked", v);
		if( v || !layerSupportsFreeMode() )
			chk.parent().addClass("checked");
		else
			chk.parent().removeClass("checked");

		if( layerSupportsFreeMode() ) {
			chk.prop("disabled",false);
			chk.parent().removeClass("unsupported");
		}
		else {
			chk.prop("disabled",true);
			chk.parent().addClass("unsupported");
		}

		selectionTool.clear();
		levelRender.invalidateBg();
		if( notify )
			N.quick( "Grid lock: "+( gridSnapping ? "ON" : "off" ));
	}

	public function setSingleLayerMode(v:Bool) {
		singleLayerMode = v;
		var chk = jMainPanel.find("input#singleLayerMode").prop("checked", v);
		if( v )
			chk.parent().addClass("checked");
		else
			chk.parent().removeClass("checked");
		levelRender.applyAllLayersVisibility();
		selectionTool.clear();
		N.quick( "Single layer mode: "+( singleLayerMode ? "ON" : "off" ));
	}

	public function setEmptySpaceSelection(v:Bool) {
		emptySpaceSelection = v;
		var chk = jMainPanel.find("input#emptySpaceSelection").prop("checked", v);
		if( v )
			chk.parent().addClass("checked");
		else
			chk.parent().removeClass("checked");
		selectionTool.clear();
		N.quick( "Select empty spaces: "+( emptySpaceSelection ? "ON" : "off" ));
	}

	function onHelp() {
		ui.Modal.closeAll();
		var m = new ui.Modal();
		m.loadTemplate("help","helpWindow", {
			appUrl: Const.WEBSITE_URL,
			docUrl: Const.DOCUMENTATION_URL,
			app: Const.APP_NAME,
			ver: Const.getAppVersion(),
		});

		m.jContent.find("dt").each( function(idx, e) {
			var jDt = new J(e);
			var jKeys = JsTools.parseKeys( jDt.text() );
			jDt.empty().append(jKeys);
		});
	}

	function onClose(?bt:js.jquery.JQuery) {
		ui.Modal.closeAll();
		if( needSaving )
			new ui.modal.dialog.UnsavedChanges( bt, App.ME.loadPage.bind( ()->new Home() ) );
		else
			App.ME.loadPage( ()->new Home() );
	}

	public function onSave(?bypassMissing=false, ?onComplete:Void->Void) {
		// var neededSaving = needSaving;
		if( !bypassMissing && !JsTools.fileExists(projectFilePath) ) {
			needSaving = true;
			new ui.modal.dialog.Confirm(
				Lang.t._("The project file is no longer in ::path::. Save to this path anyway?", { path:projectFilePath }),
				onSave.bind(true)
			);
			return;
		}

		ge.emit(BeforeProjectSaving);
		checkAutoLayersCache( (anyChange)->{
			var data = JsTools.prepareProjectFile(project);
			JsTools.writeFileBytes(projectFilePath, data.bytes);

			if( project.exportTiled ) {
				var e = new exporter.Tiled();
				e.run( project, projectFilePath );
			}

			App.ME.registerRecentProject(projectFilePath);

			N.success("Saved to "+dn.FilePath.extractFileWithExt(projectFilePath));
			updateTitle();

			this.needSaving = false;
			ge.emit(ProjectSaved);

			if( onComplete!=null )
				onComplete();
		});
	}

	public function onSaveAs() {
		var oldDir = getProjectDir();

		dn.electron.Dialogs.saveAs([".json"], getProjectDir(), function(filePath:String) {
			this.projectFilePath = filePath;
			var newDir = getProjectDir();
			App.LOG.fileOp("Remap project paths: "+oldDir+" => "+newDir);
			project.remapAllRelativePaths(oldDir, newDir);
			onSave(true);
		});
	}

	function onGlobalEvent(e:GlobalEvent) {
		switch e {
			case ViewportChanged:
			case LayerInstanceSelected:
			case LevelSelected:
			case LayerInstanceVisiblityChanged(_):
			case LayerInstanceAutoRenderingChanged(_):
			case ToolOptionChanged:
			case BeforeProjectSaving:
			case ProjectSaved:

			case _:
				needSaving = true;
		}


		switch e {
			case ViewportChanged:

			case EnumDefAdded, EnumDefRemoved, EnumDefChanged, EnumDefSorted, EnumDefValueRemoved:

			case LayerInstanceChanged:

			case EntityFieldDefChanged(ed):
			case EntityFieldSorted:
			case EntityDefSorted:
			case EntityInstanceFieldChanged(ei):

			case EntityInstanceAdded(ei):
			case EntityInstanceRemoved(ei):
			case EntityInstanceChanged(ei):

			case ToolOptionChanged:

			case LayerInstanceSelected:
				updateTool();
				updateLayerList();
				updateGuide();

			case LayerInstanceAutoRenderingChanged(li):

			case LayerInstanceVisiblityChanged(li):
				selectionTool.clear();
				updateLayerList();

			case EntityFieldAdded(ed), EntityFieldRemoved(ed):
				updateTool();

			case LayerDefAdded, LayerDefRemoved(_):
				updateLayerList();
				updateTool();

			case LayerRuleChanged(r):
			case LayerRuleAdded(r):
			case LayerRuleRemoved(r):
			case LayerRuleSorted:
			case LayerRuleSeedChanged:

			case LayerRuleGroupChanged(rg):
			case LayerRuleGroupChangedActiveState(rg):
			case LayerRuleGroupAdded:
			case LayerRuleGroupRemoved(rg):
			case LayerRuleGroupSorted:
			case LayerRuleGroupCollapseChanged:

			case BeforeProjectSaving:
			case ProjectSaved:

			case ProjectSelected:
				updateAppBg();
				updateLayerList();
				updateGuide();
				Tool.clearSelectionMemory();
				clearSpecialTool();
				updateTool();

			case LevelSettingsChanged:
				updateGuide();

			case LevelAdded:
			case LevelRemoved:
			case LevelResized:
			case LevelSorted:

			case LevelSelected:
				updateLayerList();
				updateGuide();
				clearSpecialTool();
				selectionTool.clear();
				updateTool();
				if( !levelHistory.exists(curLevelId) )
					levelHistory.set(curLevelId, new LevelHistory(curLevelId) );

			case LayerInstanceRestoredFromHistory(_), LevelRestoredFromHistory:
				selectionTool.clear();
				clearSpecialTool();
				updateAppBg();
				updateLayerList();
				updateGuide();
				updateTool();

			case TilesetDefRemoved(_):
				updateLayerList(); // for rule-based layers
				updateTool();
				updateGuide();

			case TilesetDefChanged(_), EntityDefChanged, EntityDefAdded, EntityDefRemoved:
				updateTool();
				updateGuide();

			case TilesetSelectionSaved(td):

			case TilesetDefAdded(td):

			case ProjectSettingsChanged:
				updateAppBg();

			case LayerDefChanged:
				if( curLayerDef==null && project.defs.layers.length>0 )
					selectLayerInstance( curLevel.getLayerInstance(project.defs.layers[0]) );
				resetTools();
				updateLayerList();

			case LayerDefSorted:
				if( curLayerDef==null && project.defs.layers.length>0 )
					selectLayerInstance( curLevel.getLayerInstance(project.defs.layers[0]) );
				updateTool();
				updateGuide();
				updateLayerList();
		}

		if( curLevelHistory!=null )
			curLevelHistory.manualOnGlobalEvent(e);

		updateTitle();
	}

	function updateCanvasSize() {
		var panelWid = jMainPanel.outerWidth();
		App.ME.jCanvas.show();
		App.ME.jCanvas.css("left", panelWid+"px");
		App.ME.jCanvas.css("width", "calc( 100vw - "+panelWid+"px )");
	}

	function updateAppBg() {
		if( bg!=null )
			bg.remove();

		bg = new h2d.Bitmap( h2d.Tile.fromColor(project.bgColor) );
		root.add(bg, Const.DP_BG);
		onAppResize();
	}

	override function onAppResize() {
		super.onAppResize();

		updateCanvasSize();

		if( bg!=null ) {
			bg.scaleX = canvasWid();
			bg.scaleY = canvasHei();
		}
		ge.emit(ViewportChanged);
	}

	public inline function canvasWid() {
		return App.ME.jCanvas.outerWidth() * js.Browser.window.devicePixelRatio;
	}

	public inline function canvasHei() {
		return App.ME.jCanvas.outerHeight() * js.Browser.window.devicePixelRatio;
	}

	function updateTitle() {
		App.ME.setWindowTitle(
			dn.FilePath.extractFileName(projectFilePath)
			+ ( needSaving ? " [UNSAVED]" : "" )
			+ ( curLevel!=null ? "  @ "+curLevel.identifier : "" )
		);
		// jMainPanel.find("h2#levelName").text( curLevel.getName() );
	}

	public function updateGuide() {
		var jGuide = new J("#guide");
		jGuide.empty();

		function _createGuideBlock(?keys:Array<Int>, mouseIconId:Null<String>, label:dn.data.GetText.LocaleString) {
			var block = new J('<span/>');
			block.appendTo(jGuide);

			if( keys!=null )
				for(kid in keys)
					block.append( JsTools.createKey(kid) );

			if( mouseIconId!=null )
				block.append( JsTools.createIcon(mouseIconId) );

			block.append(label);
			return block;
		}

		if( project.defs.layers.length==0 )
			jGuide.append( _createGuideBlock([], null, Lang.t._("You should start by adding at least ONE layer from the Layer panel.")) );
		else if( curLayerDef!=null ) {
			switch curLayerDef.type {
				case IntGrid:
					_createGuideBlock([K.SHIFT], "mouseLeft", L.t._("Rectangle"));
					_createGuideBlock([K.ALT], "mouseLeft", L.t._("Pick"));

				case AutoLayer:

				case Entities:
					_createGuideBlock([K.ALT], "mouseLeft", L.t._("Pick"));
					_createGuideBlock([K.CTRL,K.ALT], "mouseLeft", L.t._("Copy"));
					// _createGuideBlock([K.CTRL], null, L.t._("(while moving) Free mode"));

				case Tiles:
					_createGuideBlock([K.SHIFT], "mouseLeft", L.t._("Rectangle"));
					_createGuideBlock([K.ALT], "mouseLeft", L.t._("Pick"));
					// _createGuideBlock([K.SHIFT,K.ALT], "mouseLeft", L.t._("Pick saved selection"));
			}
		}
	}

	public function updateLayerList() {
		jLayerList.empty();

		var idx = 1;
		for(ld in project.defs.layers) {
			var li = curLevel.getLayerInstance(ld);
			var e = App.ME.jBody.find("xml.layer").clone().children().wrapAll("<li/>").parent();
			jLayerList.append(e);

			if( li==curLayerInstance )
				e.addClass("active");

			if( !levelRender.isLayerVisible(li) )
				e.addClass("hidden");

			e.find(".index").text( Std.string(idx++) );

			// Icon
			var jIcon = e.find(">.layerIcon");
			jIcon.append( JsTools.createLayerTypeIcon2(li.def.type) );

			// Name
			var name = e.find(".name");
			name.text(li.def.identifier);
			e.click( function(_) {
				selectLayerInstance(li);
			});

			// Rules button
			var rules = e.find(".rules");
			if( li.def.isAutoLayer() )
				rules.show();
			else
				rules.hide();
			rules.click( function(ev:js.jquery.Event) {
				if( ui.Modal.closeAll() )
					return;
				ev.preventDefault();
				ev.stopPropagation();
				selectLayerInstance(li);
				new ui.modal.panel.EditAllAutoLayerRules();
			});

			// Visibility button
			var vis = e.find(".vis");
			vis.find(".icon").addClass( levelRender.isLayerVisible(li) ? "visible" : "hidden" );
			vis.click( function(ev) {
				if( ui.Modal.closeAll() )
					return;
				ev.stopPropagation();
				levelRender.toggleLayer(li);
			});

		}
	}


	public function isCurrentLayerVisible() {
		return curLayerInstance!=null && levelRender.isLayerVisible(curLayerInstance);
	}

	public inline function getMouse() : MouseCoords {
		return new MouseCoords();
	}

	override function onDispose() {
		super.onDispose();

		if( ME==this )
			ME = null;

		watcher = null;

		ge.dispose();
		ge = null;

		jMouseCoords.remove();

		App.ME.jCanvas.hide();
		Boot.ME.s2d.removeEventListener(onHeapsEvent);
		Tool.clearSelectionMemory();
		ui.TilesetPicker.clearScrollMemory();

		App.ME.jBody.off(".client");
	}


	override function postUpdate() {
		super.postUpdate();
		ge.onEndOfFrame();
	}

	override function update() {
		super.update();
	}
}
