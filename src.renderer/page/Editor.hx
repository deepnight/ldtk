package page;

class Editor extends Page {
	public static var ME : Editor;

	public var jMainPanel(get,never) : J; inline function get_jMainPanel() return new J("#mainPanel");
	public var jEditOptions(get,never) : J; inline function get_jEditOptions() return new J("#editingOptions");
	public var jInstancePanel(get,never) : J; inline function get_jInstancePanel() return new J("#instancePanel");
	public var jLayerList(get,never) : J; inline function get_jLayerList() return new J("#layers");
	public var jPalette(get,never) : J; inline function get_jPalette() return jMainPanel.find("#mainPaletteWrapper");
	var jMouseCoords : js.jquery.JQuery;

	public var settings(get,never) : AppSettings; inline function get_settings() return App.ME.settings;

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
	var worldTool : WorldTool;
	var panTool : tool.PanView;
	public var curTool(get,never) : tool.LayerTool<Dynamic>;
	public var selectionTool: tool.SelectionTool;
	var allLayerTools : Map<Int,tool.LayerTool<Dynamic>> = new Map();
	var specialTool : Null< Tool<Dynamic> >; // if not null, will be used instead of default tool
	var doNothingTool : tool.lt.DoNothing;

	public var needSaving = false;
	public var worldMode(default,null) = false;

	public var camera : display.Camera;
	public var worldRender : display.WorldRender;
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

		worldRender = new display.WorldRender();
		levelRender = new display.LevelRender();
		camera = new display.Camera();
		rulers = new display.Rulers();

		selectionTool = new tool.SelectionTool();
		doNothingTool = new tool.lt.DoNothing();
		worldTool = new WorldTool();
		panTool = new tool.PanView();

		showCanvas();
		initUI();
		updateCanvasSize();

		selectProject(p);
		setCompactMode( settings.compactMode, true );
		dn.Process.resizeAll();
	}

	function saveLocked() {
		return ui.modal.Progress.hasAny();
	}

	function initUI() {
		jMouseCoords = App.ME.jBody.find("xml.mouseCoords").clone().children().first();
		App.ME.jBody.append(jMouseCoords);

		// Edit buttons
		jMainPanel.find("button.editProject").click( function(_) {
			if( ui.Modal.isOpen(ui.modal.panel.EditProject) )
				ui.Modal.closeAll();
			else
				new ui.modal.panel.EditProject();
		});

		jMainPanel.find("button.world").click( function(_) {
			if( ui.Modal.isOpen(ui.modal.panel.WorldPanel) )
				ui.Modal.closeAll();
			else
				new ui.modal.panel.WorldPanel();
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
			if( ui.Modal.isOpen(ui.modal.panel.Help) )
				ui.Modal.closeAll();
			else
				onHelp();
		});


		// Option checkboxes
		linkOption( jEditOptions.find("li.singleLayerMode"), ()->settings.singleLayerMode, (v)->setSingleLayerMode(v) );
		linkOption( jEditOptions.find("li.grid"), ()->settings.grid, (v)->setGrid(v) );
		linkOption( jEditOptions.find("li.emptySpaceSelection"), ()->settings.emptySpaceSelection, (v)->setEmptySpaceSelection(v) );
		linkOption(
			jEditOptions.find("li.tileStacking"),
			()->settings.tileStacking,
			(v)->setTileStacking(v),
			()->curLayerDef!=null && curLayerDef.type==Tiles
		);

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
		var tilesetChanged = false;
		for(td in project.defs.tilesets)
			if( reloadTileset(td, true) )
				tilesetChanged = true;

		ge.emit(ProjectSelected);

		// Tileset image hot-reloading
		for( td in project.defs.tilesets )
			watcher.watchTileset(td);

		for( ed in project.defs.externalEnums )
			watcher.watchEnum(ed);

		selectionTool.clear();
		checkAutoLayersCache( (anychange)->{
			if( anychange )
				needSaving = true;
		});

		needSaving = tilesetChanged;
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


	public function reloadEnum(ed:data.def.EnumDef) {
		importer.HxEnum.load(ed.externalRelPath, true);
	}

	public function reloadTileset(td:data.def.TilesetDef, isInitialLoading=false) {
		if( !td.hasAtlasPath() )
			return false;

		var oldRelPath = td.relPath;
		App.LOG.fileOp("Reloading tileset: "+td.relPath);
		var result = td.reloadImage( getProjectDir() );
		App.LOG.fileOp(" -> Reload result: "+result);
		App.LOG.fileOp(" -> pixelData: "+(td.hasValidPixelData() ? "Ok" : "need rebuild"));

		var changed = false;
		switch result {
			case FileNotFound:
				changed = true;
				new ui.modal.dialog.LostFile( oldRelPath, function(newAbsPath) {
					var newRelPath = makeRelativeFilePath(newAbsPath);
					td.importAtlasImage( getProjectDir(), newRelPath );
					td.buildPixelData( ge.emit.bind(TilesetDefPixelDataCacheRebuilt(td)) );
					ge.emit( TilesetDefChanged(td) );
					levelRender.invalidateAll();
				});

			case RemapLoss:
				changed = true;
				var name = dn.FilePath.fromFile(td.relPath).fileWithExt;
				new ui.modal.dialog.Warning( Lang.t._("The image ::file:: was updated, but the new version is smaller than the previous one.\nSome tiles might have been lost in the process. It is recommended to check this carefully before saving this project!", { file:name } ) );

			case TrimmedPadding:
				changed = true;
				var name = dn.FilePath.fromFile(td.relPath).fileWithExt;
				new ui.modal.dialog.Message( Lang.t._("\"::file::\" image was modified but it was SMALLER than the old version.\nLuckily, the tileset had some PADDING, so I was able to use it to compensate the difference.\nSo everything is ok, have a nice day ♥️", { file:name } ), "tile" );

			case Ok:
				if( !isInitialLoading ) {
					changed = true;
					var name = dn.FilePath.fromFile(td.relPath).fileWithExt;
					N.success(Lang.t._("Tileset image ::file:: updated.", { file:name } ) );
				}

			case RemapSuccessful:
				changed = true;
				var name = dn.FilePath.fromFile(td.relPath).fileWithExt;
				new ui.modal.dialog.Message( Lang.t._("Tileset image \"::file::\" was reloaded and is larger than the old one.\nTiles coordinates were remapped, everything is ok :)", { file:name } ), "tile" );
		}

		// Rebuild "opaque tiles" cache
		if( !td.hasValidPixelData() || !isInitialLoading || result!=Ok ) {
			changed = true;
			td.buildPixelData( ge.emit.bind(TilesetDefPixelDataCacheRebuilt(td)) );
		}

		ge.emit( TilesetDefChanged(td) );
		return changed;
	}


	public inline function hasInputFocus() {
		return App.ME.jBody.find("input:focus, textarea:focus").length>0;
	}

	override function onKeyPress(keyCode:Int) {
		super.onKeyPress(keyCode);

		if( ui.Modal.hasAnyUnclosable() )
			return;

		switch keyCode {
			case K.ESCAPE:
				if( hasInputFocus() ) {
					// BUG jquery crashes on blur if element is removed in  the process
					// see: https://github.com/jquery/jquery/issues/4417
					try App.ME.jBody.find("input:focus, textarea:focus").blur()
					catch(e:Dynamic) {}
				}
				else if( specialTool!=null )
					clearSpecialTool();
				else if( ui.Modal.hasAnyOpen() ) {
					ui.Modal.closeLatest();
				}
				else if( selectionTool.any() ) {
					ui.EntityInstanceEditor.close();
					selectionTool.clear();
				}
				else if( ui.EntityInstanceEditor.isOpen() )
					ui.EntityInstanceEditor.close();

			case K.TAB:
				if( !ui.Modal.hasAnyOpen() )
					setCompactMode( !settings.compactMode );

			case K.Z:
				if( !hasInputFocus() && !ui.Modal.hasAnyOpen() && App.ME.isCtrlDown() )
					curLevelHistory.undo();

			case K.Y:
				if( !hasInputFocus() && !ui.Modal.hasAnyOpen() && App.ME.isCtrlDown() )
					curLevelHistory.redo();

			case K.S:
				if( !hasInputFocus() && App.ME.isCtrlDown() )
					if( App.ME.isShiftDown() )
						onSave(true);
					else
						onSave();

			case K.F if( !hasInputFocus() && !App.ME.hasAnyToggleKeyDown() ):
				camera.fit();

			case K.R if( !hasInputFocus() && !App.ME.hasAnyToggleKeyDown() && curLayerInstance.def.isAutoLayer() ):
				levelRender.toggleAutoLayerRendering(curLayerInstance);
				N.quick( "Auto-layer rendering: "+L.onOff( levelRender.autoLayerRenderingEnabled(curLayerInstance) ));

			case K.R if( !hasInputFocus() && App.ME.isShiftDown() ):
				var state : Null<Bool> = null;
				for(li in curLevel.layerInstances)
					if( li.def.isAutoLayer() ) {
						if( state==null )
							state = !levelRender.autoLayerRenderingEnabled(li);
						levelRender.setAutoLayerRendering(li, state);
					}
				N.quick( "All auto-layers rendering: "+L.onOff(state));

			case K.W if( App.ME.isCtrlDown() ):
				onClose();

			case K.Q if( App.ME.isCtrlDown() ):
				App.ME.exit();

			case K.E if( !hasInputFocus() && !App.ME.hasAnyToggleKeyDown() ):
				setEmptySpaceSelection( !settings.emptySpaceSelection );

			case K.T if( !hasInputFocus() && !App.ME.hasAnyToggleKeyDown() ):
				setTileStacking( !settings.tileStacking );

			case K.A if( !hasInputFocus() && !App.ME.hasAnyToggleKeyDown() ):
				setSingleLayerMode( !settings.singleLayerMode );

			case K.A if( !hasInputFocus() && App.ME.isCtrlDown() && !App.ME.isShiftDown() ):
				if( settings.singleLayerMode )
					selectionTool.selectAllInLayers(curLevel, [curLayerInstance]);
				else
					selectionTool.selectAllInLayers(curLevel, curLevel.layerInstances);

				if( !selectionTool.isEmpty() ) {
					if( settings.singleLayerMode )
						N.quick( L.t._("Selected all in layer") );
					else
						N.quick( L.t._("Selected all") );
				}
				else
					N.error("Nothing to select");

			case K.G if( !hasInputFocus() && !App.ME.hasAnyToggleKeyDown() ):
				setGrid( !settings.grid );

			case K.H if( !hasInputFocus() ):
				onHelp();

			case k if( k>=48 && k<=57 && !hasInputFocus() ):
				var idx = k==48 ? 9 : k-49;
				if( idx < curLevel.layerInstances.length )
					selectLayerInstance( curLevel.layerInstances[idx] );

			case k if( k>=K.F1 && k<=K.F6 && !hasInputFocus() ):
				jMainPanel.find("#mainBar .buttons button:nth-of-type("+(k-K.F1+1)+")").click();

			#if debug

			case K.T if( App.ME.isAltDown() && !hasInputFocus() ):
				if( cd.has("debugTools") )
					cd.unset("debugTools");
				else
					cd.setS("debugTools", Const.INFINITE);

			case K.P if( App.ME.isCtrlDown() && App.ME.isShiftDown() && !hasInputFocus() ):
				N.msg("Rebuilding pixel caches...");
				for(td in project.defs.tilesets)
					td.buildPixelData( ge.emit.bind(TilesetDefPixelDataCacheRebuilt(td)) );

			case K.A if( App.ME.isCtrlDown() && App.ME.isShiftDown() && !hasInputFocus() ):
				N.msg("Rebuilding auto layers...");
				for(l in project.levels)
				for(li in l.layerInstances)
					li.autoTilesCache = null;
				checkAutoLayersCache( (_)->N.success("Done") );

			case K.U if( !hasInputFocus() && App.ME.isShiftDown() && App.ME.isCtrlDown() ):
				dn.electron.ElectronUpdater.emulate();

			#end
		}

		// Propagate to tools
		if( !hasInputFocus() && !ui.Modal.hasAnyOpen() ) {
			worldTool.onKeyPress(keyCode);
			panTool.onKeyPress(keyCode);

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

	public function resetTools() {
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

			var layerX = levelX - li.pxTotalOffsetX;
			var layerY = levelY - li.pxTotalOffsetY;
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
					if( li.hasAnyGridTile(cx,cy) )
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
				if( ld==curLayerDef && ge!=null && settings.singleLayerMode ) // prioritize active layer
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

		panTool.startUsing(m, e.button);

		if( !panTool.isRunning() ) {
			worldTool.onMouseDown(m, e.button);

			if( !worldTool.isTakingPriority() ) {
				if( App.ME.isAltDown() || selectionTool.isOveringSelection(m) && e.button==0 )
					selectionTool.startUsing( m, e.button );
				else if( isSpecialToolActive() )
					specialTool.startUsing( m, e.button )
				else
					curTool.startUsing( m, e.button );

				rulers.onMouseDown( m, e.button );
			}
		}
	}

	function onMouseUp() {
		var m = getMouse();

		panTool.stopUsing(m);
		worldTool.onMouseUp(m);

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
		panTool.onMouseMove(m);
		if( !panTool.isRunning() ) {
			worldTool.onMouseMove(m);
			if( !worldTool.isTakingPriority() ) {
				if( App.ME.isAltDown() || selectionTool.isRunning() || selectionTool.isOveringSelection(m) && !curTool.isRunning() )
					selectionTool.onMouseMove(m);
				else if( isSpecialToolActive() )
					specialTool.onMouseMove(m);
				else
					curTool.onMouseMove(m);
				rulers.onMouseMove(m);
			}
		}

		// Mouse coords infos
		if( ui.Modal.hasAnyOpen() )
			jMouseCoords.hide();
		else {
			jMouseCoords.show();

			// Coordinates
			if( curLayerInstance!=null )
				jMouseCoords.find(".grid").text('Grid = ${m.cx},${m.cy}');
			else
				jMouseCoords.find(".grid").hide();
			jMouseCoords.find(".pixels").text('Level = ${m.levelX},${m.levelY}');
			if( curTool.getRunningRectCWid(m)>0 || selectionTool.getRunningRectCWid(m)>0 ) {
				var wid = ( curTool.isRunning() ? curTool : selectionTool ).getRunningRectCWid(m);
				var hei = ( curTool.isRunning() ? curTool : selectionTool ).getRunningRectCHei(m);
				jMouseCoords.find(".grid").append(' / ${wid} x $hei');
			}

			// Overed element infos in footer
			var jElement = jMouseCoords.find(".element");
			jElement.removeAttr("style").empty();
			inline function _colorizeElement(c:UInt) {
				jElement.css("color", C.intToHex( C.toWhite( c, 0.66 ) ));
				jElement.css("background-color", C.intToHex( C.toBlack( c, 0.5 ) ));
			}
			var overed = getGenericLevelElementAt(m.levelX, m.levelY, settings.singleLayerMode);
			switch overed {
				case null:
				case GridCell(li, cx, cy):
					if( li.hasAnyGridValue(cx,cy) )
						switch li.def.type {
							case IntGrid:
								var v = li.getIntGrid(cx,cy);
								_colorizeElement( li.def.getIntGridValueColor(v) );
								jElement.text('${ li.def.getIntGridValueDisplayName(v) } (IntGrid)');

							case Tiles:
								var stack = li.getGridTileStack(cx,cy);
								if( stack.length==1 )
									jElement.text('Tile ${ stack[0].tileId }');
								else
									jElement.text('Tiles ${ stack.map(t->t.tileId).join(", ") }');

							case Entities:
							case AutoLayer:
						}

				case Entity(li, ei):
					_colorizeElement( ei.getSmartColor(false) );
					jElement.text('${ ei.def.identifier } (Entity)');

				case PointField(li, ei, fi, arrayIdx):
					_colorizeElement( ei.getSmartColor(false) );
					jElement.text('${ ei.def.identifier }.${ fi.def.identifier } (Entity point)');
			}
		}
	}

	function onMouseWheel(e:hxd.Event) {
		var m = getMouse();
		camera.deltaZoomTo( m.levelX, m.levelY, -e.wheelDelta*0.1 );
		camera.cancelAutoScrolling();
		camera.cancelAutoZoom();
	}

	public function selectLevel(l:data.Level) {
		if( curLevel!=null )
			worldRender.invalidateWorldLevel(curLevel);

		curLevelId = l.uid;
		if( !worldMode )
			camera.autoScrollToLevel( curLevel );
		ge.emit( LevelSelected(l) );
	}

	public function selectLayerInstance(li:data.inst.LayerInstance, notify=true) {
		if( curLayerDefUid==li.def.uid )
			return;

		if( notify )
			N.quick(li.def.identifier, JsTools.createLayerTypeIcon2(li.def.type));

		curLayerDefUid = li.def.uid;
		ge.emit(LayerInstanceSelected);

		setGrid(settings.grid, false); // update checkbox
	}

	function layerSupportsFreeMode() {
		return switch curLayerDef.type {
			case IntGrid: false;
			case AutoLayer: false;
			case Entities: true;
			case Tiles: false;
		}
	}


	public function isSnappingToGrid() {
		return settings.grid || !layerSupportsFreeMode();
	}


	function linkOption( jOpt:js.jquery.JQuery, getter:()->Bool, setter:Bool->Void, ?isSupported:Void->Bool ) {
		var p = createChildProcess( (p)->{
			// Loop
			if( jOpt.parents("body").length==0 ) {
				p.destroy();
				return;
			}

			if( jOpt.hasClass("active") && !getter() )
				jOpt.removeClass("active");

			if( !jOpt.hasClass("active") && getter() )
				jOpt.addClass("active");

			if( isSupported!=null ) {
				if( jOpt.hasClass("unsupported") && isSupported() )
					jOpt.removeClass("unsupported");

				if( !jOpt.hasClass("unsupported") && !isSupported() )
					jOpt.addClass("unsupported");
			}
		});

		p.name = "Option watcher ("+jOpt.attr("class")+")";

		// Init
		if( getter() )
			jOpt.addClass("active");
		else
			jOpt.removeClass("active");

		jOpt.off(".option").on("click.option", (ev)->{
			setter( !getter() );
		});
	}

	public function setWorldMode(v:Bool) {
		project.reorganizeWorld();
		worldMode = v;
		ui.EntityInstanceEditor.close();
		ge.emit( WorldMode(worldMode) );
	}

	public function setGrid(v:Bool, notify=true) {
		settings.grid = v;
		App.ME.saveSettings();
		selectionTool.clear();
		levelRender.applyGridVisibility();
		if( notify )
			N.quick( "Grid: "+L.onOff( settings.grid ));
	}

	public function setSingleLayerMode(v:Bool) {
		settings.singleLayerMode = v;
		App.ME.saveSettings();
		levelRender.applyAllLayersVisibility();
		selectionTool.clear();
		N.quick( "Single layer mode: "+L.onOff( settings.singleLayerMode ));
	}

	public function setEmptySpaceSelection(v:Bool) {
		settings.emptySpaceSelection = v;
		App.ME.saveSettings();
		selectionTool.clear();
		N.quick( "Select empty spaces: "+L.onOff( settings.emptySpaceSelection ));
	}

	public function setTileStacking(v:Bool) {
		settings.tileStacking = v;
		App.ME.saveSettings();
		selectionTool.clear();
		N.quick( "Tile stacking: "+L.onOff( settings.tileStacking ));
	}

	public function setCompactMode(v:Bool, init=false) {
		settings.compactMode = v;
		if( !init )
			App.ME.saveSettings();

		if( settings.compactMode )
			App.ME.jPage.addClass("compactPanel");
		else
			App.ME.jPage.removeClass("compactPanel");

		updateCanvasSize();
		updateAppBg();
		if( !init )
			N.quick("Compact UI: "+L.onOff(settings.compactMode));
	}



	function onHelp() {
		new ui.modal.panel.Help();
	}

	public function onClose(?bt:js.jquery.JQuery) {
		ui.Modal.closeAll();
		if( needSaving )
			new ui.modal.dialog.UnsavedChanges( bt, App.ME.loadPage.bind( ()->new Home() ) );
		else
			App.ME.loadPage( ()->new Home() );
	}

	public function onSave(saveAs=false, ?bypasses:Map<String,Bool>, ?onComplete:Void->Void) {
		if( saveLocked() )
			return;

		if( bypasses==null )
			bypasses = new Map();

		// Save as...
		if( saveAs ) {
			var oldDir = getProjectDir();

			dn.electron.Dialogs.saveAs(["."+Const.FILE_EXTENSION, ".json"], getProjectDir(), function(filePath:String) {
				this.projectFilePath = filePath;
				var newDir = getProjectDir();
				App.LOG.fileOp("Remap project paths: "+oldDir+" => "+newDir);
				project.remapAllRelativePaths(oldDir, newDir);
				bypasses.set("missing",true);
				onSave(false, bypasses, onComplete);
			});
			return;
		}

		// Check sample file
		if( !bypasses.exists("sample") && App.ME.isSample(projectFilePath, true) ) {
			bypasses.set("sample",true);
			new ui.modal.dialog.Choice(
				Lang.t._("The file you're trying to save is a ::app:: sample map.\nAny change to it will be lost during automatic updates, so it's NOT recommended to modify it.", { app:Const.APP_NAME }),
				true,
				[
					{ label:"Save to another file", cb:onSave.bind(true, bypasses, onComplete) },
					{ label:"Ignore", className:"gray", cb:onSave.bind(false, bypasses, onComplete) },
				]
			);
			return;
		}

		// Check missing file
		if( !bypasses.exists("missing") && !JsTools.fileExists(projectFilePath) ) {
			needSaving = true;
			new ui.modal.dialog.Confirm(
				null,
				Lang.t._("The project file is no longer in ::path::. Save to this path anyway?", { path:projectFilePath }),
				onSave.bind(true, bypasses, onComplete)
			);
			return;
		}

		// Check crash backups
		if( projectFilePath.indexOf(Const.CRASH_NAME_SUFFIX)>=0 ) {
			needSaving = true;
			new ui.modal.dialog.Confirm(
				Lang.t._("This file seems to be a CRASH BACKUP. Do you want to save your changes to the original file instead?"),
				()->{
					// Remove backup
					JsTools.removeFile(projectFilePath);
					App.ME.unregisterRecentProject(projectFilePath);
					// Save
					projectFilePath = StringTools.replace(projectFilePath, Const.CRASH_NAME_SUFFIX, "");
					updateTitle();
					onSave(bypasses, onComplete);
				}
			);
			return;
		}

		// Pre-save operations followed by actual saving
		ge.emit(BeforeProjectSaving);
		createChildProcess( (p)->{
			if( !saveLocked() ) {
				checkAutoLayersCache( (anyChange)->{
					App.LOG.fileOp('Saving $projectFilePath...');
					var data = JsTools.prepareProjectFile(project);
					JsTools.writeFileBytes(projectFilePath, data.bytes);

					var size = dn.Lib.prettyBytesSize(data.bytes.length);
					App.LOG.fileOp('Saved $size.');

					var fileName = dn.FilePath.extractFileWithExt(projectFilePath);
					if( project.exportTiled ) {
						var e = new exporter.Tiled();
						e.addExtraLogger( App.LOG, "TiledExport" );
						e.run( project, projectFilePath );
						if( e.hasErrors() )
							N.error('Saved $fileName ($size) but Tiled export has errors.');
						else
							N.success('Saved $fileName ($size) and Tiled files.');
					}
					else
						N.success('Saved $fileName ($size)');

					App.ME.registerRecentProject(projectFilePath);

					updateTitle();

					this.needSaving = false;
					ge.emit(ProjectSaved);

					if( onComplete!=null )
						onComplete();
				});
				p.destroy();
			}
		}, true);
	}

	function onGlobalEvent(e:GlobalEvent) {
		// Logging
		if( e==null )
			App.LOG.error("Received null global event!");
		else if( e!=ViewportChanged && e!=LayerInstanceChanged ) {
			var extra : Dynamic = null;
			switch e {
				case WorldMode(active):
				case ViewportChanged:
				case ProjectSelected:
				case ProjectSettingsChanged:
				case BeforeProjectSaving:
				case ProjectSaved:
				case LevelSelected(l):
				case LevelSettingsChanged(l):
				case LevelAdded(l):
				case LevelRemoved(l):
				case LevelResized(l):
				case LevelRestoredFromHistory(l):
				case LevelSorted:
				case LayerDefAdded:
				case LayerDefConverted:
				case LayerDefRemoved(defUid):
				case LayerDefChanged:
				case LayerDefSorted:
				case LayerRuleChanged(rule): extra = rule.uid;
				case LayerRuleAdded(rule): extra = rule.uid;
				case LayerRuleRemoved(rule): extra = rule.uid;
				case LayerRuleSeedChanged:
				case LayerRuleSorted:
				case LayerRuleGroupAdded:
				case LayerRuleGroupRemoved(rg): extra = rg.uid;
				case LayerRuleGroupChanged(rg): extra = rg.uid;
				case LayerRuleGroupChangedActiveState(rg): extra = rg.uid;
				case LayerRuleGroupSorted:
				case LayerRuleGroupCollapseChanged:
				case LayerInstanceSelected:
				case LayerInstanceChanged:
				case LayerInstanceVisiblityChanged(li): extra = li.layerDefUid;
				case LayerInstanceRestoredFromHistory(li): extra = li.layerDefUid;
				case LayerInstanceAutoRenderingChanged(li): extra = li.layerDefUid;
				case TilesetDefChanged(td): extra = td.uid;
				case TilesetDefAdded(td): extra = td.uid;
				case TilesetDefRemoved(td): extra = td.uid;
				case TilesetSelectionSaved(td): extra = td.uid;
				case TilesetDefPixelDataCacheRebuilt(td): extra = td.uid;
				case EntityInstanceAdded(ei): extra = ei.defUid;
				case EntityInstanceRemoved(ei): extra = ei.defUid;
				case EntityInstanceChanged(ei): extra = ei.defUid;
				case EntityInstanceFieldChanged(ei): extra = ei.defUid;
				case EntityDefAdded:
				case EntityDefRemoved:
				case EntityDefChanged:
				case EntityDefSorted:
				case EntityFieldAdded(ed): extra = ed.uid;
				case EntityFieldRemoved(ed): extra = ed.uid;
				case EntityFieldDefChanged(ed): extra = ed.uid;
				case EntityFieldSorted:
				case EnumDefAdded:
				case EnumDefRemoved:
				case EnumDefChanged:
				case EnumDefSorted:
				case EnumDefValueRemoved:
				case ToolOptionChanged:
			}
			App.LOG.add( "event", e.getName() + (extra==null ? "" : " "+Std.string(extra)) );
		}


		// Check if events changes the NeedSaving flag
		switch e {
			case WorldMode(_):
			case ViewportChanged:
			case LayerInstanceSelected:
			case LevelSelected(_):
			case LayerInstanceVisiblityChanged(_):
			case LayerInstanceAutoRenderingChanged(_):
			case ToolOptionChanged:
			case BeforeProjectSaving:
			case ProjectSaved:

			case _:
				needSaving = true;
		}


		// Use event
		switch e {
			case WorldMode(active):

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

			case LayerDefConverted:
				updateLayerList();
				resetTools();
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

			case LevelSettingsChanged(l):
				updateGuide();

			case LevelAdded(l):
			case LevelRemoved(l):
			case LevelResized(l):
			case LevelSorted:

			case LevelSelected(l):
				updateLayerList();
				updateGuide();
				clearSpecialTool();
				selectionTool.clear();
				updateTool();
				if( !levelHistory.exists(l.uid) )
					levelHistory.set(l.uid, new LevelHistory(l.uid) );

			case LayerInstanceRestoredFromHistory(_), LevelRestoredFromHistory(_):
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
			case TilesetDefPixelDataCacheRebuilt(td):

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

		// Broadcast to LevelHistory
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
		dn.Process.resizeAll();
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

		if( project.defs.layers.length==0 ) {
			jGuide.append( _createGuideBlock([], null, Lang.t._("Need at least 1 layer")) );
		}
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
				new ui.modal.panel.EditAllAutoLayerRules(li);
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

	public inline function getMouse() : Coords {
		return new Coords();
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

		#if debug
		if( cd.has("debugTools") ) {
			App.ME.debug("-- Tools ----------------------------------------");
			App.ME.debug("  "+worldTool, true);
			App.ME.debug("  "+panTool, true);
			App.ME.debug("  "+selectionTool, true);
			for(t in allLayerTools)
				App.ME.debug("  "+t, true);
		}
		#end
	}
}
