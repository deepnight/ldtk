package page;

class Editor extends Page {
	public static var ME : Editor;

	public var jMainPanel(get,never) : J; inline function get_jMainPanel() return new J("#mainPanel");
	public var jEditOptions(get,never) : J; inline function get_jEditOptions() return new J("#editingOptions");
	public var jInstancePanel(get,never) : J; inline function get_jInstancePanel() return new J("#instancePanel");
	public var jLayerList(get,never) : J; inline function get_jLayerList() return new J("#layers");
	public var jPalette(get,never) : J; inline function get_jPalette() return jMainPanel.find("#mainPaletteWrapper");
	var jMouseCoords : js.jquery.JQuery;
	var jDepths : js.jquery.JQuery;


	public var curWorld(get,never) : data.World;
		inline function get_curWorld() return project==null ? null : project.getWorldIid(curWorldIid);

	public var curLevel(get,never) : data.Level;
		inline function get_curLevel() return project==null ? null : project.getLevel(curLevelId);

	public var curLayerDef(get,never) : Null<data.def.LayerDef>;
		inline function get_curLayerDef() return project!=null ? project.defs.getLayerDef(curLayerDefUid) : null;

	public var curLayerInstance(get,never) : Null<data.inst.LayerInstance>;
		function get_curLayerInstance() return curLayerDef==null ? null : curLevel.getLayerInstance(curLayerDef);


	public var ge : GlobalEventDispatcher;
	public var watcher : misc.FileWatcher;
	public var project : data.Project;
	public var curWorldIid : String;
	public var curLevelId : Int;
	var curLayerDefUid : Int;

	// Tools
	public var worldTool : WorldTool;
	var panTool : tool.PanView;
	public var resizeTool : Null<tool.ResizeTool>;
	public var curTool(get,never) : tool.LayerTool<Dynamic>;
	public var selectionTool: tool.SelectionTool;
	var allLayerTools : Map<Int,tool.LayerTool<Dynamic>> = new Map();
	var specialTool : Null< Tool<Dynamic> >; // if not null, will be used instead of default tool
	var doNothingTool : tool.lt.DoNothing;
	var invalidatedMouseCoords = true;

	public var needSaving = false;
	public var worldMode(default,null) = false;
	public var curWorldDepth = 0;

	public var camera : display.Camera;
	public var worldRender : display.WorldRender;
	public var levelRender : display.LevelRender;
	public var rulers : display.Rulers;
	var bg : h2d.Bitmap;
	public var cursor : ui.Cursor;
	public var gifMode = false;


	var levelHistory : Map<Int,LevelHistory> = new Map();
	public var curLevelHistory(get,never) : LevelHistory;
		inline function get_curLevelHistory() return levelHistory.get(curLevelId);


	public function new(p:data.Project, ?loadLevelIndex:Int) {
		super();

		loadPageTemplate("editor");

		ME = this;
		createRoot(parent.root);
		App.ME.registerRecentProject(p.filePath.full);
		jDepths = jPage.find("#worldDepths");

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

		worldRender = new display.WorldRender();
		levelRender = new display.LevelRender();
		camera = new display.Camera();
		rulers = new display.Rulers();

		selectionTool = new tool.SelectionTool();
		doNothingTool = new tool.lt.DoNothing();
		worldTool = new WorldTool();
		panTool = new tool.PanView();

		cursor = new ui.Cursor();
		root.add(cursor.root, Const.DP_UI);

		showCanvas();
		initUI();
		updateCanvasSize();

		settings.v.showDetails = true;

		selectProject(p);

		// Suggest backups
		if( project.recommendsBackup() && !project.hasFlag(IgnoreBackupSuggest) ) {
			var w = new ui.modal.dialog.Choice(
				L.t._("As your project is growing bigger, it is STRONGLY advised to enable BACKUPS, to secure your work."),
				[
					{
						label:L.t._("Enable backups when saving"),
						className: "strong",
						cb: ()->{
							project.backupOnSave = true;
							ge.emit(ProjectSettingsChanged);
						},
					},
					{
						label:L.t._("No, and I understand the risk."),
						className: "gray",
						cb: ()->{
							project.setFlag(IgnoreBackupSuggest, true);
							ge.emit(ProjectSettingsChanged);
						},
					}
				],
				L.t._("Enable backups"),
				false
			);
		}

		if( loadLevelIndex!=null ) {
			// Auto-load provided level index
			if( loadLevelIndex>=0 && loadLevelIndex<project.levels.length ) {
				selectLevel( project.levels[loadLevelIndex] );
				camera.fit(true);
			}
			else
				N.error('Invalid level index $loadLevelIndex');
		}
		else if( settings.v.lastProject!=null ) {
			// Auto load last level UID
			var l = project.getLevel( settings.v.lastProject.levelUid );
			if( l!=null ) {
				selectLevel(l);
				camera.fit(true);
			}
		}

		saveLastProjectInfos();
		setCompactMode( settings.v.compactMode, true );
		dn.Process.resizeAll();
	}

	public static inline function exists() {
		return ME!=null && !ME.destroyed;
	}

	function initUI() {
		jMouseCoords = App.ME.jBody.find("xml.mouseCoords").clone().children().first();
		App.ME.jBody.append(jMouseCoords);

		// Edit buttons
		jMainPanel.find("button.editProject").click( function(_) {
			if( isPaused() ) return;
			if( ui.Modal.isOpen(ui.modal.panel.EditProject) )
				ui.Modal.closeAll();
			else
				new ui.modal.panel.EditProject();
		});

		jMainPanel.find("button.world").click( function(_) {
			if( isPaused() ) return;
			setWorldMode(!worldMode);
		});

		jMainPanel.find("button.editLevelInstance").click( function(_) {
			if( isPaused() ) return;
			if( ui.Modal.isOpen(ui.modal.panel.LevelInstancePanel) )
				ui.Modal.closeAll();
			else
				new ui.modal.panel.LevelInstancePanel();
		});

		jMainPanel.find("button.editLayers").click( function(_) {
			if( isPaused() ) return;
			if( ui.Modal.isOpen(ui.modal.panel.EditLayerDefs) )
				ui.Modal.closeAll();
			else
				new ui.modal.panel.EditLayerDefs();
		});

		jMainPanel.find("button.editEntities").click( function(_) {
			if( isPaused() ) return;
			if( ui.Modal.isOpen(ui.modal.panel.EditEntityDefs) )
				ui.Modal.closeAll();
			else
				new ui.modal.panel.EditEntityDefs();
		});

		jMainPanel.find("button.editTilesets").click( function(_) {
			if( isPaused() ) return;
			if( ui.Modal.isOpen(ui.modal.panel.EditTilesetDefs) )
				ui.Modal.closeAll();
			else
				new ui.modal.panel.EditTilesetDefs();
		});

		jMainPanel.find("button.editEnums").click( function(_) {
			if( isPaused() ) return;
			if( ui.Modal.isOpen(ui.modal.panel.EditEnumDefs) )
				ui.Modal.closeAll();
			else
				new ui.modal.panel.EditEnumDefs();
		});


		jMainPanel.find("button.close").click( function(ev) onClose(ev.getThis()) );


		jMainPanel.find("button.showHelp").click( function(_) {
			if( isPaused() ) return;
			if( ui.Modal.isOpen(ui.modal.panel.Help) )
				ui.Modal.closeAll();
			else
				onHelp();
		});

		jMainPanel.find("button.settings").click( function(_) {
			if( isPaused() ) return;
			if( !ui.Modal.isOpen(ui.modal.dialog.EditAppSettings) ) {
				ui.Modal.closeAll();
				new ui.modal.dialog.EditAppSettings();
			}
		});


		// Option checkboxes
		updateEditOptions();

		// World depths
		jDepths.hide();

		// Space bar blocking
		new J(js.Browser.window).off().keydown( function(ev) {
			var e = new J(ev.target);
			if( ev.keyCode==K.SPACE && !e.is("input") && !e.is("textarea") )
				ev.preventDefault();
		});
	}

	public function setPermanentNotification(id:String, ?jContent:js.jquery.JQuery) {
		jPage.find('#permanentNotifications #$id').remove();
		if( jContent!=null ) {
			var jLi = new J('<li id="$id"></li>');
			jLi.append(jContent);
			jPage.find("#permanentNotifications").append(jLi);
			// if( onClick!=null )
			// 	jLi.click( (_)->onClick() );
			// else
			// 	jLi.addClass("noClick");
		}
	}

	function updateBanners() {
		// Display "backup" header
		if( project.isBackup() ) {
			var jBackup = new J('<div class="backupHeader"/>');
			var jDesc = new J('<div class="desc"/>');
			jDesc.appendTo(jBackup);
			jDesc.append("<p>This file is a BACKUP: you cannot edit or modify to it in any way. You may only restore it to replace the original project.</p>");
			var inf = ui.ProjectSaver.extractBackupInfosFromFileName(project.filePath.full);
			if( inf!=null )
				jDesc.append("<p>"+inf.date+"</p>");
			var jRestore = new J('<button>Restore this backup</button>');
			jRestore.click( _->onBackupRestore() );
			jRestore.appendTo(jBackup);
			setPermanentNotification("backup", jBackup);
		}
		else
			setPermanentNotification("backup");

		// Display "tutorial description" header
		if( project.tutorialDesc!=null ) {
			var jDesc = new J('<div class="wrapper"/>');
			jDesc.html( "<p>" + project.tutorialDesc.split("\n").join("</p><p>") + "</p>" );
			setPermanentNotification("tutorialDesc", jDesc);
		}
		else
			setPermanentNotification("tutorialDesc");
	}

	public function selectProject(p:data.Project) {
		watcher.clearAllWatches();
		ui.modal.Dialog.closeAll();

		project = p;
		project.tidy();

		var all = ui.ProjectSaver.listBackupFiles(project.filePath.full);

		updateBanners();

		// Check external enums
		if( !project.isBackup() ) {
			for( relPath in project.defs.getExternalEnumPaths() ) {
				if( !NT.fileExists( project.makeAbsoluteFilePath(relPath) ) ) {
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
					var f = NT.readFileString( project.makeAbsoluteFilePath(relPath) );
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
		}


		curWorldIid = project.worlds[0].iid;
		curLevelId = project.levels[0].uid;
		curLayerDefUid = -1;

		// Pick 1st layer in current level
		autoPickFirstValidLayer();

		levelHistory = new Map();
		levelHistory.set( curLevelId, new LevelHistory(curLevelId) );

		// Load tilesets
		var tilesetChanged = false;
		for(td in project.defs.tilesets)
			if( reloadTileset(td, true) )
				tilesetChanged = true;

		project.tidy(); // Needed to fix enum value colors

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

		// Check level caches
		if( !project.isBackup() ) {
			for(l in project.levels)
				if( !l.hasJsonCache() ) {
					needSaving = true;
					break;
				}
		}
	}


	public function autoPickFirstValidLayer() {
		if( project.defs.layers.length<=0 )
			return false;

		for(li in curLevel.layerInstances)
			if( !li.def.hideInList ) {
				selectLayerInstance(li,false);
				return true;
			}

		return false;
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
					worldRender.invalidateLevelRender(l);
					if( curLevel==l )
						levelRender.invalidateUiAndBg();
				}
		}
		else
			N.error("Unknown watched image changed: "+relPath);
	}

	function reloadTileset(td:data.def.TilesetDef, isInitialLoading=false) {
		App.LOG.fileOp("Reloading tileset: "+td.identifier+" path="+td.relPath);

		if( !td.hasAtlasPointer() )
			return false;

		var oldRelPath = td.relPath;
		var result = td.importAtlasImage( td.relPath );
		App.LOG.fileOp(" -> Reload result: "+result);
		App.LOG.fileOp(" -> pixelData: "+(td.hasValidPixelData() ? "Ok" : "need rebuild"));

		var changed = false;
		var msg = Lang.imageLoadingMessage(td.relPath, result);

		switch result {
			case FileNotFound:
				changed = true;
				new ui.modal.dialog.LostFile( oldRelPath, function(newAbsPath) {
					var newRelPath = project.makeRelativeFilePath(newAbsPath);
					td.importAtlasImage( newRelPath );
					td.buildPixelData( ge.emit.bind(TilesetDefPixelDataCacheRebuilt(td)) );
					ge.emit( TilesetImageLoaded(td, false) );
					levelRender.invalidateAll();
				});

			case LoadingFailed(_):
				new ui.modal.dialog.Retry(msg, ()->reloadTileset(td, isInitialLoading));

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

			case UnsupportedFileOrigin(origin):
				var m = new ui.modal.dialog.Message(msg);
				m.addClass("error");
				return false;
		}

		// Rebuild "opaque tiles" cache
		if( !td.hasValidPixelData() || !isInitialLoading || result!=Ok ) {
			changed = true;
			td.buildPixelData( ge.emit.bind(TilesetDefPixelDataCacheRebuilt(td)) );
		}

		ge.emit( TilesetImageLoaded(td, isInitialLoading) );
		return changed;
	}


	public inline function hasInputFocus() {
		return App.ME.hasInputFocus();
	}



	var spaceKeyTime = 0.;
	override function onKeyDown(keyCode:Int) {
		super.onKeyDown(keyCode);

		switch keyCode {
			case K.SPACE if( !hasInputFocus() && !App.ME.hasAnyToggleKeyDown() ):
				spaceKeyTime = haxe.Timer.stamp();

			case _:
		}
	}


	override function onKeyUp(keyCode:Int) {
		super.onKeyDown(keyCode);

		switch keyCode {
			case K.SPACE if( !hasInputFocus() && !App.ME.hasAnyToggleKeyDown() ):
				if( haxe.Timer.stamp()-spaceKeyTime<=0.2 ) {
					spaceKeyTime = 0;
					camera.fit();
				}

			case _:
		}
	}


	public inline function cancelSpaceKey() {
		spaceKeyTime = 0;
	}

	override function onKeyPress(keyCode:Int) {
		super.onKeyPress(keyCode);

		if( cd.has("debugLock") ) {
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
					// BUG jquery crashes on "Blur" if element is removed in the process
					// see: https://github.com/jquery/jquery/issues/4417
					try App.ME.jBody.find("input:focus, textarea:focus").blur()
					catch(e:Dynamic) {}
				}
				else if( Std.is(curTool, tool.lt.EntityTool) && Std.downcast(curTool,tool.lt.EntityTool).isChainingRef() )
					tool.lt.EntityTool.cancelRefChaining();
				else if( ui.ValuePicker.exists() )
					ui.ValuePicker.ME.cancel();
				else if( curTool!=null && curTool.palettePoppedOut() )
					curTool.popInPalette();
				else if( specialTool!=null )
					clearSpecialTool();
				else if( ui.Modal.hasAnyOpen() )
					ui.Modal.closeLatest();
				else if( selectionTool.any() )
					selectionTool.clear();

			case K.TAB:
				if( !ui.Modal.hasAnyOpen() && !hasInputFocus() && !ui.EntityInstanceEditor.isOpen() )
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
				if( project.isBackup() )
					N.error("Cannot save over a backup file.");
				else if( !hasInputFocus() && App.ME.isCtrlDown() )
					if( App.ME.isShiftDown() )
						onSave(true);
					else
						onSave();

			case K.F12 if( !hasInputFocus() && !App.ME.hasAnyToggleKeyDown() ):
				if( !ui.Modal.isOpen(ui.modal.dialog.EditAppSettings) ) {
					ui.Modal.closeAll();
					new ui.modal.dialog.EditAppSettings();
				}

			case K.R if( !hasInputFocus() && App.ME.isShiftDown() ):
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

			case K.H if( !hasInputFocus() && !App.ME.hasAnyToggleKeyDown() ):
				onHelp();

			case K.H if( !hasInputFocus() && App.ME.isCtrlDown() ):
				setShowDetails( !settings.v.showDetails );

			case K.PGDOWN if( !hasInputFocus() ):
				if( !worldMode )
					setWorldMode(true);
				else if( !App.ME.hasAnyToggleKeyDown() ) {
					// Change active depth
					if( curWorldDepth>project.getLowestLevelDepth() )
						selectWorldDepth(curWorldDepth-1);
				}
				else if( App.ME.isCtrlDown() || App.ME.isShiftDown() ) {
					// Move current level closer
					project.moveLevelToDepthCloser(curLevel);
					ge.emit( LevelSettingsChanged(curLevel) );
					selectWorldDepth(curLevel.worldDepth);
				}

			case K.PGUP if( !hasInputFocus() ):
				if( !worldMode )
					setWorldMode(true);
				else if( !App.ME.hasAnyToggleKeyDown() ) {
					// Change active depth
					if( curWorldDepth<project.getHighestLevelDepth() )
						selectWorldDepth(curWorldDepth+1);
				}
				else if( App.ME.isCtrlDown() || App.ME.isShiftDown() ) {
					// Move current level further
					project.moveLevelToDepthFurther(curLevel);
					ge.emit( LevelSettingsChanged(curLevel) );
					selectWorldDepth(curLevel.worldDepth);
				}


			case k if( k>=48 && k<=57 && !hasInputFocus() ):
				var idx = k==48 ? 9 : k-49;
				if( idx < curLevel.layerInstances.length )
					selectLayerInstance( curLevel.layerInstances[idx] );

			case k if( k>=K.F1 && k<=K.F6 && !hasInputFocus() ):
				jMainPanel.find("#mainBar .buttons button:nth-of-type("+(k-K.F1+2)+")").click();

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

	public function getGenericLevelElementAt(m:Coords, ?limitToLayerType:ldtk.Json.LayerType, limitToActiveLayer=false) : Null<GenericLevelElement> {
		var m = m.clone();

		function getElement(li:data.inst.LayerInstance) {
			var ge : GenericLevelElement = null;

			if( !levelRender.isLayerVisible(li) || curLayerInstance!=li && li.def.inactiveOpacity<=0 )
				return null;

			m.setRelativeLayer(li);

			switch li.def.type {
				case IntGrid:
					if( li.getIntGrid(m.cx,m.cy)>0 )
						ge = GenericLevelElement.GridCell( li, m.cx, m.cy );

				case AutoLayer:

				case Entities:
					for(ei in li.entityInstances) {
						if( ei.isOver(m.layerX, m.layerY) ) {
							ge = GenericLevelElement.Entity(li, ei);
						}
						else {
							// Points
							for(fi in ei.fieldInstances) {
								if( fi.def.type!=F_Point )
									continue;
								for(i in 0...fi.getArrayLength()) {
									var pt = fi.getPointGrid(i);
									if( pt!=null && m.cx==pt.cx && m.cy==pt.cy )
										ge = GenericLevelElement.PointField(li, ei, fi, i);
								}
							}
						}
					}

				case Tiles:
					if( li.hasAnyGridTile(m.cx, m.cy) )
						ge = GenericLevelElement.GridCell(li, m.cx, m.cy);
			}
			return ge;
		}


		if( limitToActiveLayer )
			return limitToLayerType==null || curLayerDef.type==limitToLayerType ? getElement(curLayerInstance) : null;
		else {
			// Search in all layers
			var all = project.defs.layers.copy(); // TODO optimize these allocations!
			all.reverse();
			var best = null;
			for(ld in all) {
				if( limitToLayerType!=null && ld.type!=limitToLayerType )
					continue;

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
		if( isPaused() )
			return;

		switch e.kind {
			case EPush: onMouseDown(e);
			case ERelease: onMouseUp();
			case EMove: onMouseMove(e);
			case EOver:
			case EOut: onMouseUp();
			case EWheel: onHeapsMouseWheel(e);
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
		if( isLocked() || !App.ME.hasGlContext )
			return;

		var m = getMouse();

		panTool.startUsing(ev,m);

		if( !ev.cancel && ui.ValuePicker.exists() )
			ui.ValuePicker.ME.onMouseDown(ev, m);

		if( !ev.cancel && resizeTool!=null && !ui.ValuePicker.exists() )
			resizeTool.onMouseDown( ev, m );

		if( !ev.cancel && !project.isBackup() && !ui.ValuePicker.exists() )
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

		if( ui.ValuePicker.exists() )
			ui.ValuePicker.ME.onMouseUp(m);

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
		if( !App.ME.hasGlContext )
			return;

		var m = getMouse();

		if( !isLocked() ) {
			// Create a separate cancelable event for cursor update
			var cursorEvent = new hxd.Event(EMove);

			// Propagate event to tools & UI components
			panTool.onMouseMove(ev,m);
			panTool.onMouseMoveCursor(cursorEvent,m);

			if( ui.ValuePicker.exists() ) {
				ui.ValuePicker.ME.onMouseMove(ev,m);
				ui.ValuePicker.ME.onMouseMoveCursor(cursorEvent,m);
			}

			if( !ev.cancel && resizeTool!=null && !ui.ValuePicker.exists() ) {
				resizeTool.onMouseMove(ev,m);
				resizeTool.onMouseMoveCursor(cursorEvent,m);
			}

			if( !ev.cancel && !worldMode && !ui.ValuePicker.exists() ) {
				if( App.ME.isAltDown() || selectionTool.isRunning() || selectionTool.isOveringSelection(m) && !curTool.isRunning() ) {
					selectionTool.onMouseMove(ev,m);
					selectionTool.onMouseMoveCursor(cursorEvent,m);
				}
				else if( isSpecialToolActive() ) {
					specialTool.onMouseMove(ev,m);
					specialTool.onMouseMoveCursor(cursorEvent,m);
				}
				else {
					curTool.onMouseMove(ev,m);
					curTool.onMouseMoveCursor(cursorEvent,m);
				}
			}

			if( !ui.ValuePicker.exists() ) {
				rulers.onMouseMove(ev,m); // Note: event cancelation is checked inside
				rulers.onMouseMoveCursor(cursorEvent,m);
			}

			worldTool.onMouseMove(ev,m); // Note: event cancelation is checked inside
			worldTool.onMouseMoveCursor(cursorEvent,m);

			if( ui.Modal.isOpen( ui.modal.panel.EditAllAutoLayerRules ) )
				ui.Modal.getFirst( ui.modal.panel.EditAllAutoLayerRules ).onEditorMouseMove(m);

			// Default cursor
			if( !cursorEvent.cancel )
				cursor.set(None);

			cursor.onMouseMove(m);

			if( curLevel.inBounds(m.levelX, m.levelY) )
				App.ME.requestCpu(false);
		}

		// Mouse coords infos
		if( ui.Modal.hasAnyOpen() || isLocked() || !App.ME.overCanvas ) {
			if( jMouseCoords.is(":visible") )
				jMouseCoords.hide();
		}
		else
			invalidatedMouseCoords = true;
	}


	function updateMouseCoordsBlock(m:Coords) {
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
		jElement.removeAttr("style").text("--");
		inline function _colorizeElement(c:UInt) {
			jElement.css("color", C.intToHex( C.toWhite( c, 0.66 ) ));
			jElement.css("background-color", C.intToHex( C.toBlack( c, 0.5 ) ));
		}
		var overed = getGenericLevelElementAt(m, settings.v.singleLayerMode);
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

	public var lastMouseWheelDelta = 0.;
	override function onAppMouseWheel(delta:Float) {
		super.onAppMouseWheel(delta);
		lastMouseWheelDelta = delta;
	}


	function onHeapsMouseWheel(e:hxd.Event) {
		deltaZoom( lastMouseWheelDelta*settings.v.mouseWheelSpeed, getMouse() );
		cursor.onMouseMove( getMouse() );
	}


	public function deltaZoom(delta:Float, c:Coords) {
		var spd = 0.15;
		camera.deltaZoomTo( c.levelX, c.levelY, delta*spd*camera.adjustedZoom );
		camera.cancelAllAutoMovements();

		App.ME.requestCpu();

		// Auto world mode on zoom out
		if( settings.v.autoWorldModeSwitch!=Never && !worldMode && delta<0 ) {
			var wr = camera.getLevelWidthRatio(curLevel);
			var hr = camera.getLevelHeightRatio(curLevel);
			// if( wr<=0.3 && hr<=0.3 || wr<=0.22 || hr<=0.22 || camera.adjustedZoom<=camera.getMinZoom() )
			if( camera.adjustedZoom<=camera.getMinZoom() )
				setWorldMode(true, true);
		}

		// Auto level mode on zoom in
		if( settings.v.autoWorldModeSwitch==ZoomInAndOut && worldMode && delta>0 ) {
			// Find closest level to cursor
			var dh = new dn.DecisionHelper(project.levels);
			dh.keepOnly( l->l.worldDepth==curWorldDepth && l.isWorldOver(c.worldX, c.worldY, 500) );
			dh.score( l->l.isWorldOver(c.worldX, c.worldY) ? 100 : 0 );
			dh.score( l->-l.getDist(c.worldX,c.worldY) );

			var l = dh.getBest();
			if( l!=null ) {
				var wr = camera.getLevelWidthRatio(l);
				var hr = camera.getLevelHeightRatio(l);
				// if( wr>0.3 && hr>0.3 || wr>0.78 || hr>0.78 ) {
				if( camera.adjustedZoom>camera.getMinZoom(l) ) {
					selectLevel(l);
					setWorldMode(false, true);
				}
			}
		}

	}


	public function selectLevel(l:data.Level) {
		if( curLevel!=null )
			worldRender.invalidateLevelRender(curLevel);

		curLevelId = l.uid;
		ge.emit( LevelSelected(l) );
		ge.emit( ViewportChanged );
		ui.Tip.clear();

		saveLastProjectInfos();
	}


	public function saveLastProjectInfos() {
		if( settings.v.openLastProject ) {
			settings.v.lastProject = {
				filePath: dn.FilePath.convertToSlashes( project.filePath.full ),
				levelUid: curLevelId,
			}
			settings.save();
		}
	}

	public function selectLayerInstance(li:data.inst.LayerInstance, notify=true) {
		if( curLayerDefUid==li.def.uid )
			return;

		if( notify )
			N.quick(li.def.identifier, JsTools.createLayerTypeIcon2(li.def.type));

		curLayerDefUid = li.def.uid;
		ge.emit(LayerInstanceSelected);
		clearSpecialTool();
		ui.Tip.clear();

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


	public function selectWorldDepth(depth:Int) {
		if( curWorldDepth==depth )
			return;

		curWorldDepth = depth;
		ge.emit( WorldDepthSelected(curWorldDepth) );
	}


	function updateWorldDepthsUI() {
		var min = project.getLowestLevelDepth();
		var max = project.getHighestLevelDepth();

		if( !worldMode || min==max ) {
			jDepths.hide();
			return;
		}

		var jList = jDepths.children("ul");
		jList.empty();
		jDepths.show();

		for(depth in min...max+1) {
			var jDepth = new J('<li/>');
			jDepth.prependTo(jList);
			jDepth.append('<span class="icon"/>');
			jDepth.append('<span class="label">$depth</label>');
			if( depth==curWorldDepth )
				jDepth.addClass("active");
			jDepth.click( _->{
				selectWorldDepth(depth);
			});
		}
	}


	public inline function isSnappingToGrid() {
		return settings.v.grid || !layerSupportsFreeMode();
	}

	function updateEditOptions() {
		ui.Tip.clear();

		// Init
		jEditOptions
			.off()
			.find("*")
				.removeClass("active unsupported")
				.off();

		// Update all
		applyEditOption( jEditOptions.find("li.grid"), ()->settings.v.grid, (v)->setGrid(v) );
		applyEditOption( jEditOptions.find("li.showDetails"), ()->settings.v.showDetails, (v)->setShowDetails(v) );

		applyEditOption( jEditOptions.find("li.singleLayerMode"), ()->settings.v.singleLayerMode, (v)->setSingleLayerMode(v) );
		applyEditOption( jEditOptions.find("li.emptySpaceSelection"), ()->settings.v.emptySpaceSelection, (v)->setEmptySpaceSelection(v) );
		applyEditOption(
			jEditOptions.find("li.tileStacking"),
			()->settings.v.tileStacking,
			(v)->setTileStacking(v),
			()->curLayerDef!=null && curLayerDef.type==Tiles
		);

		JsTools.parseComponents(jEditOptions);
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
			if( isPaused() )
				return;
			setter( !getter() );
		});
	}

	public function setWorldMode(v:Bool, usedMouseWheel=false) {
		if( worldMode==v )
			return;

		App.ME.requestCpu();
		selectionTool.clear();
		project.reorganizeWorld();
		worldMode = v;
		ge.emit( WorldMode(worldMode) );
		if( worldMode ) {
			cursor.set(None);
			N.quick(L.t._("World view"), new J('<span class="icon world"/>'));
			ui.Modal.closeAll();
			new ui.modal.panel.WorldPanel();
		}
		else
			updateLayerList();

		camera.onWorldModeChange(worldMode, usedMouseWheel);
	}

	public function setGrid(v:Bool, notify=true) {
		settings.v.grid = v;
		App.ME.settings.save();
		ge.emit( GridChanged(settings.v.grid) );
		if( notify )
			N.quick( "Grid: "+L.onOff( settings.v.grid ));
		updateEditOptions();
	}

	public function setSingleLayerMode(v:Bool) {
		settings.v.singleLayerMode = v;
		App.ME.settings.save();
		levelRender.applyAllLayersVisibility();
		levelRender.invalidateUiAndBg();
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

	public function setShowDetails(v:Bool) {
		settings.v.showDetails = v;
		App.ME.settings.save();
		selectionTool.clear();
		N.quick( settings.v.showDetails ? L.t._("Showing everything") : L.t._("Showing tiles only"));
		ge.emit( ShowDetailsChanged(v) );
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
		if( isPaused() )
			return;
		ui.Modal.closeAll();
		if( needSaving )
			new ui.modal.dialog.UnsavedChanges( bt, App.ME.loadPage.bind( ()->new Home() ) );
		else
			App.ME.loadPage( ()->new Home(), true );
	}

	public function onSave(saveAs=false, ?bypasses:Map<String,Bool>, ?onComplete:Void->Void) {
		if( isLocked() )
			return;

		if( bypasses==null )
			bypasses = new Map();

		// Save as...
		if( saveAs ) {
			var oldDir = project.getProjectDir();

			dn.js.ElectronDialogs.saveFileAs(["."+Const.FILE_EXTENSION, ".json"], project.getProjectDir(), function(filePath:String) {
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
		if( !bypasses.exists("missing") && !NT.fileExists(project.filePath.full) ) {
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
		new ui.ProjectSaver(this, project, (success)->{
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
			L.t._("WARNING: restoring this backup will REPLACE the original project file with this version.\nAre you sure?"),
			()->{
				var original = ui.ProjectSaver.makeOriginalPathFromBackup(project.filePath.full);
				if( original.full==null || !NT.fileExists(original.full) ) {
					// Project not found
					new ui.modal.dialog.Message(L.t._("Sorry, but I can't restore this backup: I can't locate the original project file."));
				}
				else {
					App.LOG.fileOp('Restoring backup: ${project.filePath.full}...');
					var crashBackupDir = ui.ProjectSaver.isCrashFile(project.filePath.full) ? project.filePath.directory: null;

					// Save upon original
					App.LOG.fileOp('Backup original: ${original.full}...');
					project.filePath = original.clone();
					setPermanentNotification("backup");
					for(l in project.levels)
						invalidateLevelCache(l);
					onSave();
					selectProject(project);

					if( worldMode )
						setWorldMode(false);
					ui.Modal.closeAll();

					// Delete crash backup
					if( crashBackupDir!=null )
						NT.removeDir(crashBackupDir);
				}
			}
		);
	}

	inline function shouldLogEvent(e:GlobalEvent) {
		return switch(e) {
			case ViewportChanged: false;
			case WorldLevelMoved(_): false;
			// case LayerInstanceChangedGlobally(_): false;
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
				case LevelJsonCacheInvalidated(l):
				case WorldLevelMoved(l,isFinal):
				case WorldSettingsChanged:
				case LayerDefAdded:
				case LayerDefConverted:
				case LayerDefRemoved(defUid): extra = defUid;
				case LayerDefChanged(defUid): extra = defUid;
				case LayerDefSorted:
				case LayerDefIntGridValueRemoved(defUid, valueId, isUsed): extra = defUid+'($valueId, $isUsed)';
				case LayerRuleChanged(rule): extra = rule.uid;
				case LayerRuleAdded(rule): extra = rule.uid;
				case LayerRuleRemoved(rule): extra = rule.uid;
				case LayerRuleSeedChanged:
				case LayerRuleSorted:
				case LayerRuleGroupAdded(rg): extra = rg.uid;
				case LayerRuleGroupRemoved(rg): extra = rg.uid;
				case LayerRuleGroupChanged(rg): extra = rg.uid;
				case LayerRuleGroupChangedActiveState(rg): extra = rg.uid;
				case LayerRuleGroupSorted:
				case LayerRuleGroupCollapseChanged(rg): extra = rg.uid;
				case LayerInstanceSelected:
				case LayerInstanceChangedGlobally(li): extra = li.layerDefUid;
				case LayerInstanceVisiblityChanged(li): extra = li.layerDefUid;
				case LayerInstanceRestoredFromHistory(li): extra = li.layerDefUid;
				case LayerInstanceTilesetChanged(li): extra = li.layerDefUid;
				case AutoLayerRenderingChanged:
				case TilesetDefChanged(td): extra = td.uid;
				case TilesetDefAdded(td): extra = td.uid;
				case TilesetDefRemoved(td): extra = td.uid;
				case TilesetMetaDataChanged(td): extra = td.uid;
				case TilesetSelectionSaved(td): extra = td.uid;
				case TilesetDefPixelDataCacheRebuilt(td): extra = td.uid;
				case TilesetDefSorted:
				case EntityInstanceAdded(ei): extra = ei.defUid;
				case EntityInstanceRemoved(ei): extra = ei.defUid;
				case EntityInstanceChanged(ei): extra = ei.defUid;
				case LevelFieldInstanceChanged(l,fi): extra = fi.defUid;
				case EntityFieldInstanceChanged(ei,fi): extra = fi.defUid;

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
				case ToolValueSelected:
				case GridChanged(active):
				case _:
			}
			App.LOG.add( "event", e.getName() + (extra==null ? "" : " "+Std.string(extra)) );
		}


		// Level cache invalidation
		switch e {
			case ViewportChanged:
			case AppSettingsChanged:
			case ProjectSelected:
			case ProjectSettingsChanged:
			case BeforeProjectSaving:
			case ProjectSaved:
			case LevelSelected(level):
			case LevelSettingsChanged(_), LevelAdded(_): invalidateAllLevelsCache();
			case LevelRemoved(_):
				switch project.worldLayout {
					case Free, GridVania:
					case LinearHorizontal, LinearVertical: invalidateAllLevelsCache();
				}
			case LevelResized(level): invalidateLevelCache(level);
			case LevelRestoredFromHistory(level): invalidateLevelCache(level);
			case LevelJsonCacheInvalidated(level):
			case WorldLevelMoved(level,isFinal):
				if( isFinal )
					switch project.worldLayout {
						case Free, GridVania: invalidateLevelCache(level);
						case LinearHorizontal, LinearVertical: invalidateAllLevelsCache();
					}

			case WorldSettingsChanged: invalidateAllLevelsCache();
			case LayerDefAdded: invalidateAllLevelsCache();
			case LayerDefRemoved(defUid): invalidateAllLevelsCache();
			case LayerDefChanged(defUid): invalidateAllLevelsCache();
			case LayerDefSorted: invalidateAllLevelsCache();
			case LayerDefIntGridValuesSorted(defUid):
			case LayerDefIntGridValueRemoved(defUid,value,used):
				if( used ) {
					invalidateAllLevelsCache();
					checkAutoLayersCache( anyChange->{
						worldRender.invalidateAllLevelRenders();
					});
				}
			case LayerDefConverted: invalidateAllLevelsCache();
			case LayerRuleChanged(rule): invalidateAllLevelsCache();
			case LayerRuleAdded(rule): invalidateAllLevelsCache();
			case LayerRuleRemoved(rule): invalidateAllLevelsCache();
			case LayerRuleSeedChanged: invalidateAllLevelsCache();
			case LayerRuleSorted: invalidateAllLevelsCache();
			case LayerRuleGroupAdded(rg): if( rg.rules.length>0 ) invalidateAllLevelsCache();
			case LayerRuleGroupRemoved(rg): if( rg.rules.length>0 ) invalidateAllLevelsCache();
			case LayerRuleGroupChanged(rg): if( rg.rules.length>0 ) invalidateAllLevelsCache();
			case LayerRuleGroupChangedActiveState(rg):
				if( rg.isOptional )
					invalidateLevelCache(curLevel);
				else
					invalidateAllLevelsCache();
			case LayerRuleGroupSorted: invalidateAllLevelsCache();
			case LayerRuleGroupCollapseChanged(rg):
			case LayerInstanceSelected:
			case LayerInstanceEditedByTool(li): invalidateLevelCache(li.level);
			case LayerInstanceChangedGlobally(li): invalidateLevelCache(li.level);
			case LayerInstanceVisiblityChanged(li):
			case LayerInstanceRestoredFromHistory(li): invalidateLevelCache(li.level);
			case AutoLayerRenderingChanged:
			case LayerInstanceTilesetChanged(li): invalidateLevelCache(li.level);
			case TilesetDefChanged(td): invalidateAllLevelsCache();
			case TilesetImageLoaded(td, init):
				if( !init )
					invalidateAllLevelsCache();
			case TilesetDefAdded(td):
			case TilesetDefRemoved(td): invalidateAllLevelsCache();
			case TilesetMetaDataChanged(td):
			case TilesetSelectionSaved(td):
			case TilesetDefPixelDataCacheRebuilt(td):
			case TilesetDefSorted:
			case EntityInstanceAdded(ei): invalidateLevelCache(ei._li.level);
			case EntityInstanceRemoved(ei): invalidateLevelCache(ei._li.level);
			case EntityInstanceChanged(ei): invalidateLevelCache(ei._li.level);
			case EntityDefAdded:
			case EntityDefRemoved: invalidateAllLevelsCache();
			case EntityDefChanged: invalidateAllLevelsCache();
			case EntityDefSorted:
			case FieldDefAdded(fd): invalidateAllLevelsCache();
			case FieldDefRemoved(fd): invalidateAllLevelsCache();
			case FieldDefChanged(fd): invalidateAllLevelsCache();
			case FieldDefSorted: invalidateAllLevelsCache();
			case LevelFieldInstanceChanged(l, fi): invalidateLevelCache(l);
			case EntityFieldInstanceChanged(ei, fi): invalidateLevelCache(ei._li.level);
			case EnumDefAdded:
			case EnumDefRemoved: invalidateAllLevelsCache();
			case EnumDefChanged: invalidateAllLevelsCache();
			case EnumDefSorted:
			case EnumDefValueRemoved: invalidateAllLevelsCache();
			case ToolValueSelected:
			case ToolOptionChanged:
			case WorldMode(active):
			case WorldDepthSelected(worldDepth):
			case GridChanged(active):
			case ShowDetailsChanged(active):
		}


		// Check if events changes the NeedSaving flag
		switch e {
			case WorldMode(_):
			case WorldDepthSelected(_):
			case AppSettingsChanged:
			case ViewportChanged:
			case LayerInstanceSelected:
			case LevelSelected(_):
			case AutoLayerRenderingChanged:
			case ToolOptionChanged:
			case ToolValueSelected:
			case BeforeProjectSaving:
			case LayerRuleGroupCollapseChanged(rg):
			case ProjectSaved:
			case GridChanged(active):
			case ShowDetailsChanged(active):
			case TilesetImageLoaded(td,init):
				if( !init )
					needSaving = true;

			case _:
				needSaving = true;
		}


		// Use event
		switch e {
			case AppSettingsChanged:

			case WorldMode(active):
				if( !active && curWorldDepth!=curLevel.worldDepth )
					selectWorldDepth(curLevel.worldDepth);
				updateWorldDepthsUI();

			case WorldDepthSelected(worldDepth):
				updateWorldDepthsUI();

			case ViewportChanged:

			case EnumDefAdded, EnumDefRemoved, EnumDefChanged, EnumDefSorted, EnumDefValueRemoved:

			case LayerInstanceChangedGlobally(li):
			case LayerInstanceEditedByTool(li):

			case FieldDefChanged(fd):

			case FieldDefSorted:

			case LevelFieldInstanceChanged(l,fi):

			case EntityFieldInstanceChanged(ei,fi):

			case EntityInstanceAdded(ei):

			case EntityInstanceRemoved(ei):
				if( resizeTool!=null && resizeTool.isOnEntity(ei) )
					clearResizeTool();

			case EntityInstanceChanged(ei):
				if( selectionTool.any() )
					selectionTool.invalidateRender();

			case ToolOptionChanged:
				updateTool();

			case ToolValueSelected:

			case GridChanged(active):

			case ShowDetailsChanged(active):

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
				checkAutoLayersCache( (_)->{} );
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
			case LayerRuleGroupAdded(rg):
			case LayerRuleGroupRemoved(rg):
			case LayerRuleGroupSorted:
			case LayerRuleGroupCollapseChanged(rg):

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
				updateWorldDepthsUI();

			case LevelJsonCacheInvalidated(l):
			case LevelAdded(l):

			case LevelRemoved(l):

			case LevelResized(l):

			case WorldLevelMoved(l,isFinal):

			case WorldSettingsChanged:

			case LevelSelected(l):
				updateWorldDepthsUI();
				updateLayerList();
				updateGuide();
				clearSpecialTool();
				selectionTool.clear();
				updateTool();
				if( !levelHistory.exists(l.uid) )
					levelHistory.set(l.uid, new LevelHistory(l.uid) );
				selectWorldDepth(l.worldDepth);

			case LayerInstanceRestoredFromHistory(_), LevelRestoredFromHistory(_):
				selectionTool.clear();
				clearSpecialTool();
				updateAppBg();
				updateLayerList();
				updateGuide();
				updateTool();

			case LayerInstanceTilesetChanged(li):

			case TilesetDefRemoved(_):
				updateLayerList(); // for rule-based layers
				updateTool();
				updateGuide();

			case TilesetDefChanged(_), EntityDefChanged, EntityDefAdded, EntityDefRemoved, EntityDefSorted, TilesetDefSorted:
				tool.lt.EntityTool.cancelRefChaining();
				updateTool();
				updateGuide();

			case TilesetImageLoaded(td, init):
				updateTool();

			case TilesetMetaDataChanged(td):

			case TilesetSelectionSaved(td):

			case TilesetDefPixelDataCacheRebuilt(td):
				project.tidy();

			case TilesetDefAdded(td):

			case ProjectSettingsChanged:
				updateBanners();
				updateAppBg();

			case LayerDefChanged(defUid):
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

			case LayerDefIntGridValuesSorted(defUid):
				updateTool();

			case LayerDefIntGridValueRemoved(defUid,value,used):
				updateTool();
		}

		// Broadcast to LevelHistory
		if( curLevelHistory!=null )
			curLevelHistory.manualOnGlobalEvent(e);

		updateTitle();
	}

	public function invalidateAllLevelsCache() {
		for(l in project.levels)
			invalidateLevelCache(l);
	}

	public function invalidateLevelCache(l:data.Level) {
		if( l==null ) {
			N.error("Unknown level in invalidateLevelCache()");
			return;
		}

		if( l.hasJsonCache() ) {
			l.invalidateJsonCache();
			ge.emit( LevelJsonCacheInvalidated(l) );
		}
	}


	function updateCanvasSize() {
		var panelWid = jMainPanel.outerWidth();
		App.ME.jCanvas.show();
		App.ME.jCanvas.css("left", panelWid+"px");
		App.ME.jCanvas.css("width", "calc( 100vw - "+panelWid+"px )");
		camera.invalidateCanvasSize();
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

	public function updateTitle() {
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
			var active = li==curLayerInstance;
			if( ld.hideInList && !active )
				continue;

			var jLayer = App.ME.jBody.find("xml.layer").clone().children().wrapAll("<li/>").parent();
			jLayerList.append(jLayer);
			jLayer.attr("uid",ld.uid);

			if( active )
				jLayer.addClass("active");

			if( ld.hideInList )
				jLayer.addClass("hiddenFromList");

			jLayer.find(".index").text( Std.string(idx++) );

			// Icon
			var jIcon = jLayer.find(">.layerIcon");
			jIcon.append( JsTools.createLayerTypeIcon2(li.def.type) );

			// Name
			var name = jLayer.find(".name");
			name.text(li.def.identifier);
			jLayer.click( function(_) {
				selectLayerInstance(li);
			});

			// Rules button
			var rules = jLayer.find(".rules");
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
			var vis = jLayer.find(".vis");
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
					invalidateLevelCache(curLevel);
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

		watcher = null;

		cursor.dispose();

		ge.dispose();
		ge = null;

		jMouseCoords.remove();

		App.ME.jCanvas.hide();
		Boot.ME.s2d.removeEventListener(onHeapsEvent);
		Tool.clearSelectionMemory();
		ui.Tileset.clearScrollMemory();

		App.ME.jBody.off(".client");

		if( ME==this )
			ME = null;
	}


	override function postUpdate() {
		super.postUpdate();
		ge.onEndOfFrame();
		cursor.update();
	}

	var wasLocked : Bool = null;
	override function update() {
		super.update();

		if( camera.isAnimated() )
			cursor.onMouseMove( getMouse() );


		// Zoom keyboard shortcuts
		if( App.ME.focused && !App.ME.hasInputFocus() ) {
			if( App.ME.isKeyDown(K.NUMPAD_ADD) || App.ME.isKeyDown(K.QWERTY_EQUALS) )
				deltaZoom(0.45*tmod, Coords.fromLevelCoords(camera.levelX,camera.levelY) );

			if( App.ME.isKeyDown(K.NUMPAD_SUB) || App.ME.isKeyDown(K.QWERTY_MINUS) )
				deltaZoom(-0.45*tmod, Coords.fromLevelCoords(camera.levelX,camera.levelY) );
		}

		// DOM locking
		if( isLocked()!=wasLocked ) {
			wasLocked = isLocked();
			if( isLocked() && !ui.Modal.hasAnyUnclosable() )
				App.ME.jPage.addClass("locked");
			else if( !isLocked() )
				App.ME.jPage.removeClass("locked");
		}

		// Render mouse coords block
		if( invalidatedMouseCoords && !cd.hasSetS("mouseCoordsLimit",0.06) ) {
			invalidatedMouseCoords = false;
			updateMouseCoordsBlock( getMouse() );
		}
	}
}
