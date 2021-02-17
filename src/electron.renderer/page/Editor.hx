package page;

class Editor extends Page {
	public static var ME : Editor;

	public var jMainPanel(get,never) : J; inline function get_jMainPanel() return new J("#mainPanel");
	public var jEditOptions(get,never) : J; inline function get_jEditOptions() return new J("#editingOptions");
	public var jInstancePanel(get,never) : J; inline function get_jInstancePanel() return new J("#instancePanel");
	public var jLayerList(get,never) : J; inline function get_jLayerList() return new J("#layers");
	public var jPalette(get,never) : J; inline function get_jPalette() return jMainPanel.find("#mainPaletteWrapper");
	var jMouseCoords : js.jquery.JQuery;

	public var curLevel(get,never) : data.Level;
		inline function get_curLevel() return project.getLevel(curLevelId);

	public var curLayerDef(get,never) : Null<data.def.LayerDef>;
		inline function get_curLayerDef() return project!=null ? project.defs.getLayerDef(curLayerDefUid) : null;

	public var curLayerInstance(get,never) : Null<data.inst.LayerInstance>;
		function get_curLayerInstance() return curLayerDef==null ? null : curLevel.getLayerInstance(curLayerDef);


	public var ge : GlobalEventDispatcher;
	public var watcher : misc.FileWatcher;
	public var project : data.Project;
	public var curLevelId : Int;
	var curLayerDefUid : Int;

	// Tools
	public var worldTool : WorldTool;
	var panTool : tool.PanView;
	var resizeTool : Null<tool.ResizeTool>;
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


	public function new(p:data.Project, ?loadLevelIndex:Int) {
		super();

		loadPageTemplate("editor");

		ME = this;
		createRoot(parent.root);
		App.ME.registerRecentProject(p.filePath.full);

		// Events
		App.ME.jBody
			.on("mouseup.client", function(_) onMouseUp() )
			.on("mouseleave.client", function(_) onMouseUp() );

		Boot.ME.s2d.addEventListener( onHeapsEvent );

		bg = new h2d.Bitmap();
		root.add(bg, Const.DP_BG);

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

		// Auto-load provided level index
		if( loadLevelIndex!=null )
			if( loadLevelIndex>=0 && loadLevelIndex<project.levels.length ) {
				selectLevel( project.levels[loadLevelIndex] );
				camera.fit(true);
			}
			else
				N.error('Invalid level index $loadLevelIndex');

		setCompactMode( settings.v.compactMode, true );
		dn.Process.resizeAll();
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
			setWorldMode(!worldMode);
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
		updateEditOptions();

		// Space bar blocking
		new J(js.Browser.window).off().keydown( function(ev) {
			var e = new J(ev.target);
			if( ev.keyCode==K.SPACE && !e.is("input") && !e.is("textarea") )
				ev.preventDefault();
		});
	}

	public function setPermanentNotification(id:String, ?msg:dn.data.GetText.LocaleString, ?onClick:Void->Void) {
		jPage.find('#permanentNotifications #$id').remove();
		if( msg!=null ) {
			var jLi = new J('<li id="$id">$msg</li>');
			jPage.find("#permanentNotifications").append(jLi);
			if( onClick!=null )
				jLi.click( (_)->onClick() );
			else
				jLi.addClass("noClick");
		}
	}

	public function selectProject(p:data.Project) {
		watcher.clearAllWatches();
		ui.modal.Dialog.closeAll();

		project = p;
		project.tidy();

		var all = ui.ProjectSaving.listBackupFiles(project.filePath.full);

		if( project.isBackup() ) {
			setPermanentNotification("backup", L.t._("This file is a BACKUP: some external files such as images and tilesets are temporarily unavailable, but that's normal. The backup project file isn't stored in the same location as the original file. Click on this message to RESTORE this backup."), ()->{
				onBackupRestore();
			});
		}
		else
			setPermanentNotification("backup");

		// Check external enums
		if( !project.isBackup() )
			for( relPath in project.defs.getExternalEnumPaths() ) {
				if( !JsTools.fileExists( project.makeAbsoluteFilePath(relPath) ) ) {
					// File not found
					new ui.modal.dialog.LostFile(relPath, function(newAbsPath) {
						var newRel = project.makeRelativeFilePath(newAbsPath);
						if( project.remapExternEnums(relPath, newRel) )
							Editor.ME.ge.emit( EnumDefChanged );
						importer.HxEnum.load(newRel, true);
						needSaving = true;
					});
				}
				else {
					// Verify checksum
					var f = JsTools.readFileString( project.makeAbsoluteFilePath(relPath) );
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
		if( !project.isBackup() )
			for(td in project.defs.tilesets)
				if( reloadTileset(td, true) )
					tilesetChanged = true;

		ge.emit(ProjectSelected);

		// Tileset image hot-reloading
		for( td in project.defs.tilesets )
			watcher.watchImage(td.relPath);

		// Level bg image hot-reloading
		for( l in project.levels )
			if( l.bgRelPath!=null )
			watcher.watchImage(l.bgRelPath);

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


	public function onProjectImageChanged(relPath:String) {
		if( project.reloadImage(relPath) ) {
			N.success("Image updated: "+dn.FilePath.extractFileWithExt(relPath));

			// Update tilesets
			for(td in project.defs.tilesets)
				if( td.relPath==relPath )
					reloadTileset(td);

			// Update level bgs
			for(l in project.levels)
				if( l.bgRelPath==relPath ) {
					worldRender.invalidateLevel(l);
					if( curLevel==l )
						levelRender.invalidateBg();
				}
		}
		else
			N.error("Unknown watched image changed: "+relPath);
	}

	function reloadTileset(td:data.def.TilesetDef, isInitialLoading=false) {
		App.LOG.fileOp("Reloading tileset: "+td.identifier+" path="+td.relPath);

		if( !td.hasAtlasPath() )
			return false;

		var oldRelPath = td.relPath;
		var result = td.importAtlasImage( td.relPath );
		App.LOG.fileOp(" -> Reload result: "+result);
		App.LOG.fileOp(" -> pixelData: "+(td.hasValidPixelData() ? "Ok" : "need rebuild"));

		var changed = false;
		var msg = Lang.atlasLoadingMessage(td.relPath, result);

		switch result {
			case FileNotFound:
				changed = true;
				new ui.modal.dialog.LostFile( oldRelPath, function(newAbsPath) {
					var newRelPath = project.makeRelativeFilePath(newAbsPath);
					td.importAtlasImage( newRelPath );
					td.buildPixelData( ge.emit.bind(TilesetDefPixelDataCacheRebuilt(td)) );
					ge.emit( TilesetDefChanged(td) );
					levelRender.invalidateAll();
				});

			case LoadingFailed(err):
				throw "check";
				new ui.modal.dialog.Warning(msg);

			case RemapLoss:
				changed = true;
				new ui.modal.dialog.Warning(msg);

			case TrimmedPadding:
				changed = true;
				new ui.modal.dialog.Message(msg, "tile");

			case Ok:
				if( !isInitialLoading )
					changed = true;

			case RemapSuccessful:
				changed = true;
				new ui.modal.dialog.Message(msg, "tile");
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
		return App.ME.hasInputFocus();
	}

	override function onKeyPress(keyCode:Int) {
		super.onKeyPress(keyCode);

		if( isLocked() ) {
			#if debug
			if( keyCode==K.L && App.ME.isCtrlDown() && App.ME.isShiftDown() ) {
				cd.unset("debugLock");
				N.msg("Unlocked", 0x77ff00);
			}
			#end
			return;
		}

		switch keyCode {
			case K.ESCAPE:
				if( hasInputFocus() ) {
					// BUG jquery crashes on blur if element is removed in  the process
					// see: https://github.com/jquery/jquery/issues/4417
					try App.ME.jBody.find("input:focus, textarea:focus").blur()
					catch(e:Dynamic) {}
				}
				else if( curTool!=null && curTool.palettePoppedOut() )
					curTool.popInPalette();
				else if( specialTool!=null )
					clearSpecialTool();
				else if( worldMode && worldTool.isInAddMode() )
					worldTool.stopAddMode();
				else if( ui.Modal.hasAnyOpen() )
					ui.Modal.closeLatest();
				else if( selectionTool.any() )
					selectionTool.clear();

			case K.TAB:
				if( !ui.Modal.hasAnyOpen() )
					setCompactMode( !settings.v.compactMode );

			case K.Z if( !worldMode && !hasInputFocus() && !ui.Modal.hasAnyOpen() && App.ME.isCtrlDown() ):
				curLevelHistory.undo();

			case K.Y if( !worldMode && !hasInputFocus() && !ui.Modal.hasAnyOpen() && App.ME.isCtrlDown() ):
				curLevelHistory.redo();

			#if debug
			case K.L if( !worldMode && !hasInputFocus() && App.ME.isCtrlDown() && App.ME.isShiftDown() ):
				cd.setS("debugLock",Const.INFINITE);
				N.msg("Locked.", 0xff7700);
			#end

			case K.S:
				if( !hasInputFocus() && App.ME.isCtrlDown() )
					if( App.ME.isShiftDown() )
						onSave(true);
					else
						onSave();

			case K.F if( !hasInputFocus() && !App.ME.hasAnyToggleKeyDown() ):
				camera.fit();

			case K.F12 if( !hasInputFocus() && !App.ME.hasAnyToggleKeyDown() ):
				ui.Modal.closeAll();
				new ui.modal.dialog.EditAppSettings();

			case K.R if( !hasInputFocus() && !App.ME.hasAnyToggleKeyDown() ):
				var state = levelRender.toggleAutoLayerRendering();
				N.quick( "Auto-layers rendering: "+L.onOff(state));

			case K.W if( App.ME.isCtrlDown() ):
				onClose();

			case K.W if( !App.ME.hasAnyToggleKeyDown() && !hasInputFocus() ):
				setWorldMode( !worldMode );

			case K.Q if( App.ME.isCtrlDown() ):
				App.ME.exit();

			case K.E if( !hasInputFocus() && !App.ME.hasAnyToggleKeyDown() ):
				setEmptySpaceSelection( !settings.v.emptySpaceSelection );

			case K.T if( !hasInputFocus() && !App.ME.hasAnyToggleKeyDown() ):
				setTileStacking( !settings.v.tileStacking );

			case K.A if( !hasInputFocus() && !App.ME.hasAnyToggleKeyDown() ):
				setSingleLayerMode( !settings.v.singleLayerMode );

			case K.A if( !hasInputFocus() && App.ME.isCtrlDown() && !App.ME.isShiftDown() && !worldMode ):
				if( settings.v.singleLayerMode )
					selectionTool.selectAllInLayers(curLevel, [curLayerInstance]);
				else
					selectionTool.selectAllInLayers(curLevel, curLevel.layerInstances);

				if( !selectionTool.isEmpty() ) {
					if( settings.v.singleLayerMode )
						N.quick( L.t._("Selected all in layer") );
					else
						N.quick( L.t._("Selected all") );
				}
				else
					N.error("Nothing to select");

			case K.G if( !hasInputFocus() && !App.ME.hasAnyToggleKeyDown() ):
				setGrid( !settings.v.grid );

			case K.H if( !hasInputFocus() ):
				onHelp();

			case k if( k>=48 && k<=57 && !hasInputFocus() ):
				var idx = k==48 ? 9 : k-49;
				if( idx < curLevel.layerInstances.length )
					selectLayerInstance( curLevel.layerInstances[idx] );

			case k if( k>=K.F1 && k<=K.F6 && !hasInputFocus() ):
				jMainPanel.find("#mainBar .buttons button:nth-of-type("+(k-K.F1+1)+")").click();
		}

		// Propagate to tools
		if( !hasInputFocus() && !ui.Modal.hasAnyOpen() ) {
			worldTool.onKeyPress(keyCode);
			panTool.onKeyPress(keyCode);
			if( resizeTool!=null )
				resizeTool.onKeyPress(keyCode);

			if( !worldMode ) {
				if( isSpecialToolActive() )
					specialTool.onKeyPress(keyCode);
				else {
					selectionTool.onKeyPress(keyCode);
					curTool.onKeyPress(keyCode);
				}
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

	function deleteLayerTool(layerUid:Int) {
		if( allLayerTools.exists(layerUid) ) {
			allLayerTools.get(layerUid).destroy();
			allLayerTools.remove(layerUid);
			return true;
		}
		else
			return false;
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
			&& ( tClass==null || Std.isOfType(specialTool, tClass) );
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
					if( li.getIntGrid(cx,cy)>0 )
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
				if( ld==curLayerDef && ge!=null && settings.v.singleLayerMode ) // prioritize active layer
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

	public function clearResizeTool() {
		if( resizeTool!=null ) {
			if( resizeTool.isRunning() )
				resizeTool.stopUsing( getMouse() );
			resizeTool.destroy();
		}
		resizeTool = null;
	}

	public function invalidateResizeTool() {
		if( resizeTool!=null )
			resizeTool.invalidate();
	}

	public function createResizeToolFor(ge:GenericLevelElement) {
		clearResizeTool();
		resizeTool = new tool.ResizeTool(ge);
	}

	function onMouseDown(ev:hxd.Event) {
		if( isLocked() )
			return;

		var m = getMouse();

		panTool.startUsing(ev,m);

		if( !ev.cancel && resizeTool!=null )
			resizeTool.onMouseDown( ev, m );

		if( !ev.cancel && !project.isBackup() )
			rulers.onMouseDown( ev, m );

		if( !ev.cancel )
			worldTool.onMouseDown(ev, m);

		if( !ev.cancel && !worldMode && !project.isBackup() ) {
			if( App.ME.isAltDown() || selectionTool.isOveringSelection(m) && ev.button==0 )
				selectionTool.startUsing( ev, m );
			else if( isSpecialToolActive() )
				specialTool.startUsing( ev, m )
			else
				curTool.startUsing( ev, m );
		}

		if( !ev.cancel && project.isBackup() )
			N.error("Backup files should not be edited directly");
	}

	function onMouseUp() {
		var m = getMouse();

		panTool.stopUsing(m);
		worldTool.onMouseUp(m);
		if( resizeTool!=null && resizeTool.isRunning() )
			resizeTool.stopUsing(m);

		// Tool updates
		if( selectionTool.isRunning() )
			selectionTool.stopUsing( m );
		else if( isSpecialToolActive() && specialTool.isRunning() )
			specialTool.stopUsing( m );
		else if( curTool.isRunning() )
			curTool.stopUsing( m );

		rulers.onMouseUp( m );
	}

	function onMouseMove(ev:hxd.Event) {
		var m = getMouse();

		if( !isLocked() ) {
			// Propagate event to tools & UI components
			panTool.onMouseMove(ev,m);
			rulers.onMouseMove(ev,m); // Note: event cancelation is checked inside
			worldTool.onMouseMove(ev,m);

			if( !ev.cancel && resizeTool!=null )
				resizeTool.onMouseMove(ev,m);

			if( !ev.cancel && !worldMode ) {
				if( App.ME.isAltDown() || selectionTool.isRunning() || selectionTool.isOveringSelection(m) && !curTool.isRunning() )
					selectionTool.onMouseMove(ev,m);
				else if( isSpecialToolActive() )
					specialTool.onMouseMove(ev,m);
				else
					curTool.onMouseMove(ev,m);
			}

			if( ui.Modal.isOpen( ui.modal.panel.EditAllAutoLayerRules ) )
				ui.Modal.getFirst( ui.modal.panel.EditAllAutoLayerRules ).onEditorMouseMove(m);
		}

		// Mouse coords infos
		if( ui.Modal.hasAnyOpen() || isLocked() )
			jMouseCoords.hide();
		else {
			jMouseCoords.show();

			// Coordinates
			if( worldMode ) {
				jMouseCoords.find(".world").text('World = ${m.worldX},${m.worldY}');
				jMouseCoords.find(".grid").hide();
				jMouseCoords.find(".level").hide();
			}
			else {
				if( curLayerInstance!=null )
					jMouseCoords.find(".grid").text('Grid = ${m.cx},${m.cy}');
				else
					jMouseCoords.find(".grid").hide();
				jMouseCoords.find(".level").text('Level = ${m.levelX},${m.levelY}');
				jMouseCoords.find(".world").text('World = ${m.worldX},${m.worldY}');
			}
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
			var overed = getGenericLevelElementAt(m.levelX, m.levelY, settings.v.singleLayerMode);
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
		var speed = camera.pixelRatio * 2100 / camera.width;
		camera.deltaZoomTo( m.levelX, m.levelY, -e.wheelDelta * 0.06 * speed );
		camera.cancelAllAutoMovements();

		// Auto world mode on zoom out
		if( settings.v.autoWorldModeSwitch!=Never && !worldMode && e.wheelDelta>0 ) {
			var wr = camera.getLevelWidthRatio(curLevel);
			var hr = camera.getLevelHeightRatio(curLevel);
			// App.ME.debug( M.pretty(wr)+" x "+M.pretty(hr), true );
			if( wr<=0.3 && hr<=0.3 || wr<=0.22 || hr<=0.22 )
				setWorldMode(true, true);
		}

		// Auto level mode on zoom in
		if( settings.v.autoWorldModeSwitch==ZoomInAndOut && worldMode && e.wheelDelta<0 ) {
			// Find closest level to cursor
			var dh = new dn.DecisionHelper(project.levels);
			dh.keepOnly( l->l.isWorldOver(m.worldX, m.worldY, 500) );
			dh.score( l->l.isWorldOver(m.worldX, m.worldY) ? 100 : 0 );
			dh.score( l->-l.getDist(m.worldX,m.worldY) );

			var l = dh.getBest();
			if( l!=null ) {
				var wr = camera.getLevelWidthRatio(l);
				var hr = camera.getLevelHeightRatio(l);
				// App.ME.debug( M.pretty(wr)+" x "+M.pretty(hr), true );
				if( wr>0.3 && hr>0.3 || wr>0.78 || hr>0.78 ) {
					selectLevel(l);
					setWorldMode(false, true);
				}
			}
		}
	}


	public function selectLevel(l:data.Level) {
		if( curLevel!=null )
			worldRender.invalidateLevel(curLevel);

		curLevelId = l.uid;
		ge.emit( LevelSelected(l) );
		ge.emit( ViewportChanged );
	}

	public function selectLayerInstance(li:data.inst.LayerInstance, notify=true) {
		if( curLayerDefUid==li.def.uid )
			return;

		if( notify )
			N.quick(li.def.identifier, JsTools.createLayerTypeIcon2(li.def.type));

		curLayerDefUid = li.def.uid;
		ge.emit(LayerInstanceSelected);
		clearSpecialTool();

		updateEditOptions();
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
		return settings.v.grid || !layerSupportsFreeMode();
	}

	function updateEditOptions() {
		// Init
		jEditOptions
			.off()
			.find("*")
				.removeClass("active unsupported")
				.off();

		// Update all
		applyEditOption( jEditOptions.find("li.singleLayerMode"), ()->settings.v.singleLayerMode, (v)->setSingleLayerMode(v) );
		applyEditOption( jEditOptions.find("li.grid"), ()->settings.v.grid, (v)->setGrid(v) );
		applyEditOption( jEditOptions.find("li.emptySpaceSelection"), ()->settings.v.emptySpaceSelection, (v)->setEmptySpaceSelection(v) );
		applyEditOption(
			jEditOptions.find("li.tileStacking"),
			()->settings.v.tileStacking,
			(v)->setTileStacking(v),
			()->curLayerDef!=null && curLayerDef.type==Tiles
		);
	}

	inline function applyEditOption( jOpt:js.jquery.JQuery, getter:()->Bool, setter:Bool->Void, ?isSupported:Void->Bool ) {
		if( jOpt.hasClass("active") && !getter() )
			jOpt.removeClass("active");
		else if( !jOpt.hasClass("active") && getter() )
			jOpt.addClass("active");

		if( isSupported!=null ) {
			if( jOpt.hasClass("unsupported") && isSupported() )
				jOpt.removeClass("unsupported");

			if( !jOpt.hasClass("unsupported") && !isSupported() )
				jOpt.addClass("unsupported");
		}

		jOpt.off(".option").on("click.option", (ev)->{
			setter( !getter() );
		});
	}

	public function setWorldMode(v:Bool, usedMouseWheel=false) {
		if( worldMode==v )
			return;

		selectionTool.clear();
		project.reorganizeWorld();
		worldMode = v;
		ge.emit( WorldMode(worldMode) );
		if( worldMode ) {
			N.quick(L.t._("World view"), new J('<span class="icon world"/>'));
			ui.Modal.closeAll();
			new ui.modal.panel.LevelPanel();
		}

		camera.onWorldModeChange(worldMode, usedMouseWheel);
		worldTool.onWorldModeChange(worldMode);
	}

	public function setGrid(v:Bool, notify=true) {
		settings.v.grid = v;
		App.ME.settings.save();
		selectionTool.clear();
		ge.emit( GridChanged(settings.v.grid) );
		if( notify )
			N.quick( "Grid: "+L.onOff( settings.v.grid ));
		updateEditOptions();
	}

	public function setSingleLayerMode(v:Bool) {
		settings.v.singleLayerMode = v;
		App.ME.settings.save();
		levelRender.applyAllLayersVisibility();
		levelRender.invalidateBg();
		selectionTool.clear();
		N.quick( "Single layer mode: "+L.onOff( settings.v.singleLayerMode ));
		updateEditOptions();
	}

	public function setEmptySpaceSelection(v:Bool) {
		settings.v.emptySpaceSelection = v;
		App.ME.settings.save();
		selectionTool.clear();
		N.quick( "Select empty spaces: "+L.onOff( settings.v.emptySpaceSelection ));
		updateEditOptions();
	}

	public function setTileStacking(v:Bool) {
		settings.v.tileStacking = v;
		App.ME.settings.save();
		selectionTool.clear();
		N.quick( "Tile stacking: "+L.onOff( settings.v.tileStacking ));
		updateEditOptions();
	}

	public function setCompactMode(v:Bool, init=false) {
		settings.v.compactMode = v;
		if( !init )
			App.ME.settings.save();

		if( settings.v.compactMode )
			App.ME.jPage.addClass("compactPanel");
		else
			App.ME.jPage.removeClass("compactPanel");

		updateCanvasSize();
		updateAppBg();
		if( !init )
			N.quick("Compact UI: "+L.onOff(settings.v.compactMode));
	}



	function onHelp() {
		new ui.modal.panel.Help();
	}

	public function isLocked() {
		return App.ME.isLocked()
			#if debug || cd.has("debugLock") #end;
	}

	public function onClose(?bt:js.jquery.JQuery) {
		ui.Modal.closeAll();
		if( needSaving )
			new ui.modal.dialog.UnsavedChanges( bt, App.ME.loadPage.bind( ()->new Home() ) );
		else
			App.ME.loadPage( ()->new Home() );
	}

	public function onSave(saveAs=false, ?bypasses:Map<String,Bool>, ?onComplete:Void->Void) {
		if( isLocked() )
			return;

		if( bypasses==null )
			bypasses = new Map();

		// Save as...
		if( saveAs ) {
			var oldDir = project.getProjectDir();

			dn.electron.Dialogs.saveAs(["."+Const.FILE_EXTENSION, ".json"], project.getProjectDir(), function(filePath:String) {
				project.filePath.parseFilePath( filePath );
				var newDir = project.getProjectDir();
				App.LOG.fileOp("Remap project paths: "+oldDir+" => "+newDir);
				project.remapAllRelativePaths(oldDir, newDir);
				bypasses.set("missing",true);
				onSave(false, bypasses, onComplete);
			});
			return;
		}

		// Check sample file
		if( !bypasses.exists("sample") && App.ME.isInAppDir(project.filePath.full, true) ) {
			bypasses.set("sample",true);
			new ui.modal.dialog.Choice(
				Lang.t._("The file you're trying to save is a ::app:: sample map.\nAny change to it will be lost during automatic updates, so it's NOT recommended to modify it.", { app:Const.APP_NAME }),
				[
					{ label:"Save to another file", cb:onSave.bind(true, bypasses, onComplete) },
					{ label:"Save anyway", className:"gray", cb:onSave.bind(false, bypasses, onComplete) },
				]
			);
			return;
		}

		// Check missing file
		if( !bypasses.exists("missing") && !JsTools.fileExists(project.filePath.full) ) {
			needSaving = true;
			new ui.modal.dialog.Confirm(
				null,
				Lang.t._("The project file is no longer in ::path::. Save to this path anyway?", { path:project.filePath.full }),
				onSave.bind(true, bypasses, onComplete)
			);
			return;
		}

		// Check crash backups
		if( project.isBackup() ) {
			needSaving = true;
			onBackupRestore();
			return;
		}

		// Save project
		new ui.ProjectSaving(this, project, (success)->{
			if( !success )
				N.error("Saving failed!");
			else {
				App.LOG.fileOp('Saved "${project.filePath.fileWithExt}".');
				N.success('Saved "${project.filePath.fileName}".');

				App.ME.registerRecentProject(project.filePath.full);
				this.needSaving = false;
				ge.emit(ProjectSaved);
				updateTitle();
			}

			if( onComplete!=null )
				onComplete();
		});
	}

	function onBackupRestore() {
		new ui.modal.dialog.Confirm(
			Lang.t._("Do you want to want to RESTORE this backup?"),
			()->{
				var original = ui.ProjectSaving.makeOriginalPathFromBackup(project.filePath.full);
				if( !JsTools.fileExists(original.full) ) {
					// Project not found
					new ui.modal.dialog.Message(L.t._("Sorry, but I can't restore this backup: I can't locate the corresponding project file."));
				}
				else {
					new ui.modal.dialog.Confirm( // extra confirmation
						Lang.t._("WARNING: I will REPLACE the original project file with this backup. Are you sure?"),
						true,
						()->{
							App.LOG.fileOp('Restoring backup: ${project.filePath.full}...');
							var crashFile = ui.ProjectSaving.isCrashFile(project.filePath.full) ? project.filePath.full : null;

							// Save upon original
							App.LOG.fileOp('Backup original: ${original.full}...');
							project.filePath = original.clone();
							setPermanentNotification("backup");
							onSave();
							selectProject(project);

							// Delete crash backup
							if( crashFile!=null )
								JsTools.removeFile(crashFile);
						}
					);
				}
			}
		);
	}

	inline function shouldLogEvent(e:GlobalEvent) {
		return switch(e) {
			case ViewportChanged: false;
			case WorldLevelMoved: false;
			case LayerInstanceChanged: false;
			case WorldMode(_): false;
			case GridChanged(_): false;
			case _: true;
		}
	}

	function onGlobalEvent(e:GlobalEvent) {
		// Logging
		if( e==null )
			App.LOG.error("Received null global event!");
		else if( shouldLogEvent(e) ) {
			var extra : Dynamic = null;
			switch e {
				case AppSettingsChanged:
				case WorldMode(active):
				case ViewportChanged:
				case ProjectSelected:
				case ProjectSettingsChanged:
				case BeforeProjectSaving:
				case ProjectSaved:
				case LevelSelected(l): extra = l.uid;
				case LevelSettingsChanged(l): extra = l.uid;
				case LevelAdded(l): extra = l.uid;
				case LevelRemoved(l): extra = l.uid;
				case LevelResized(l): extra = l.uid;
				case LevelRestoredFromHistory(l):
				case LevelSorted:
				case WorldLevelMoved:
				case WorldSettingsChanged:
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
				case AutoLayerRenderingChanged:
				case TilesetDefChanged(td): extra = td.uid;
				case TilesetDefAdded(td): extra = td.uid;
				case TilesetDefRemoved(td): extra = td.uid;
				case TilesetSelectionSaved(td): extra = td.uid;
				case TilesetDefPixelDataCacheRebuilt(td): extra = td.uid;
				case EntityInstanceAdded(ei): extra = ei.defUid;
				case EntityInstanceRemoved(ei): extra = ei.defUid;
				case EntityInstanceChanged(ei): extra = ei.defUid;
				case FieldInstanceChanged(fi): extra = fi.defUid;
				case EntityDefAdded:
				case EntityDefRemoved:
				case EntityDefChanged:
				case EntityDefSorted:
				case FieldDefAdded(fd): extra = fd.identifier;
				case FieldDefRemoved(fd): extra = fd.identifier;
				case FieldDefChanged(fd): extra = fd.identifier;
				case FieldDefSorted:
				case EnumDefAdded:
				case EnumDefRemoved:
				case EnumDefChanged:
				case EnumDefSorted:
				case EnumDefValueRemoved:
				case ToolOptionChanged:
				case GridChanged(active):
			}
			App.LOG.add( "event", e.getName() + (extra==null ? "" : " "+Std.string(extra)) );
		}


		// Check if events changes the NeedSaving flag
		switch e {
			case WorldMode(_):
			case AppSettingsChanged:
			case ViewportChanged:
			case LayerInstanceSelected:
			case LevelSelected(_):
			case AutoLayerRenderingChanged:
			case ToolOptionChanged:
			case BeforeProjectSaving:
			case ProjectSaved:

			case _:
				needSaving = true;
		}


		// Use event
		switch e {
			case AppSettingsChanged:
			case WorldMode(active):

			case ViewportChanged:

			case EnumDefAdded, EnumDefRemoved, EnumDefChanged, EnumDefSorted, EnumDefValueRemoved:

			case LayerInstanceChanged:

			case FieldDefChanged(fd):
			case FieldDefSorted:
			case EntityDefSorted:
			case FieldInstanceChanged(fi):

			case EntityInstanceAdded(ei):
			case EntityInstanceRemoved(ei):
			case EntityInstanceChanged(ei):

			case ToolOptionChanged:

			case GridChanged(active):

			case LayerInstanceSelected:
				updateTool();
				updateLayerList();
				updateGuide();

			case AutoLayerRenderingChanged:

			case LayerInstanceVisiblityChanged(li):
				selectionTool.clear();
				updateLayerVisibilities();

			case FieldDefAdded(_), FieldDefRemoved(_):
				project.tidy();
				updateTool();

			case LayerDefConverted:
				updateLayerList();
				resetTools();
				updateTool();

			case LayerDefAdded:
				updateLayerList();
				updateTool();

			case LayerDefRemoved(uid):
				deleteLayerTool(uid);
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
			case WorldLevelMoved:
			case WorldSettingsChanged:

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
		bg.tile = h2d.Tile.fromColor(project.bgColor);
		onAppResize();
	}

	override function onAppResize() {
		super.onAppResize();

		updateCanvasSize();

		if( bg!=null ) {
			bg.scaleX = camera.width;
			bg.scaleY = camera.height;
		}
		ge.emit(ViewportChanged);
		dn.Process.resizeAll();
	}

	function updateTitle() {
		App.ME.setWindowTitle(
			project.filePath.fileName
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

	override function onAppBlur() {
		super.onAppBlur();
		heldVisibilitySet = null;
	}

	override function onAppMouseUp() {
		super.onAppMouseUp();
		heldVisibilitySet = null;
	}


	var heldVisibilitySet = null;
	public function updateLayerList() {
		jLayerList.empty();

		var idx = 1;
		for(ld in project.defs.layers) {
			var li = curLevel.getLayerInstance(ld);
			var e = App.ME.jBody.find("xml.layer").clone().children().wrapAll("<li/>").parent();
			jLayerList.append(e);
			e.attr("uid",ld.uid);

			if( li==curLayerInstance )
				e.addClass("active");

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
			vis.mouseover( (_)->{
				if( App.ME.isMouseButtonDown(0) && heldVisibilitySet!=null )
					levelRender.setLayerVisibility(li, heldVisibilitySet);
			});
			vis.mousedown( (ev:js.jquery.Event)->{
				if( App.ME.isShiftDown() ) {
					// Keep only this one
					var anyChange = !levelRender.isLayerVisible(li);
					for(oli in curLevel.layerInstances)
						if( oli!=li && levelRender.isLayerVisible(oli) ) {
							anyChange = true;
							levelRender.setLayerVisibility(oli, false);
						}
					if( anyChange )
						levelRender.setLayerVisibility(li, true);
					else {
						// Re-enable all if it's already the case
						for(oli in curLevel.layerInstances)
							levelRender.setLayerVisibility(oli, true);
					}
				}
				else {
					// Toggle this one
					heldVisibilitySet = !levelRender.isLayerVisible(li);
					levelRender.setLayerVisibility(li, heldVisibilitySet);
				}
			});
		}

		updateLayerVisibilities();
	}

	function updateLayerVisibilities() {
		jLayerList.children().each( (idx,e)->{
			var jLayer = new J(e);
			var li = curLevel.getLayerInstance( Std.parseInt(jLayer.attr("uid")) );
			if( li==null )
				return;

			if( levelRender.isLayerVisible(li) )
				jLayer.removeClass("hidden");
			else
				jLayer.addClass("hidden");
		});
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

	var wasLocked : Bool = null;
	override function update() {
		super.update();

		// DOM locking
		if( isLocked()!=wasLocked ) {
			wasLocked = isLocked();
			if( isLocked() && !ui.Modal.hasAnyUnclosable() )
				App.ME.jPage.addClass("locked");
			else if( !isLocked() )
				App.ME.jPage.removeClass("locked");
		}


		#if debug
		if( App.ME.cd.has("debugTools") ) {
			App.ME.clearDebug();
			App.ME.debug("mouse="+getMouse());

			App.ME.debug("appButtons="
				+ ( App.ME.isMouseButtonDown(0) ? "[left] " : "" )
				+ ( App.ME.isMouseButtonDown(2) ? "[right] " : "" )
				+ ( App.ME.isMouseButtonDown(1) ? "[middle] " : "" )
			);
			App.ME.debug("zoom="+M.pretty(camera.adjustedZoom,1)+" cam="+camera.width+"x"+camera.height+" pixelratio="+camera.pixelRatio);
			App.ME.debug("-- Tools & UI ----------------------------------------");
			App.ME.debug("  "+worldTool);
			App.ME.debug("  "+panTool);
			App.ME.debug("  "+resizeTool);
			App.ME.debug("  "+selectionTool);
			App.ME.debug("  selection="+selectionTool.debugContent());
			for(t in allLayerTools)
				App.ME.debug("  "+t);
			App.ME.debug("  "+rulers);

			App.ME.debug("-- Processes ----------------------------------------");
			for( line in dn.Process.rprintAll().split('\n') )
				App.ME.debug('<pre>$line</pre>');
		}
		#end
	}
}
