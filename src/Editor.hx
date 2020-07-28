import hxd.Key;

class Editor extends dn.Process {
	public static var ME : Editor;

	public var jMainPanel(get,never) : J; inline function get_jMainPanel() return new J("#mainPanel");
	public var jInstancePanel(get,never) : J; inline function get_jInstancePanel() return new J("#instancePanel");
	public var jLayers(get,never) : J; inline function get_jLayers() return new J("#layers");
	public var jPalette(get,never) : J; inline function get_jPalette() return jMainPanel.find("#mainPaletteWrapper");

	public var curLevel(get,never) : led.Level;
		inline function get_curLevel() return project.getLevel(curLevelId);

	public var curLayerDef(get,never) : Null<led.def.LayerDef>;
		inline function get_curLayerDef() return project.defs.getLayerDef(curLayerId);

	public var curLayerInstance(get,never) : Null<led.inst.LayerInstance>;
		function get_curLayerInstance() return curLayerDef==null ? null : curLevel.getLayerInstance(curLayerDef);


	public var ge : GlobalEventDispatcher;
	public var watcher : misc.FileWatcher;
	public var project : led.Project;
	public var projectFilePath : String;
	public var curLevelId : Int;
	var curLayerId : Int;
	public var curTool : Tool<Dynamic>;
	var keyDowns : Map<Int,Bool> = new Map();
	public var gridSnapping = true;
	public var needSaving = false;

	public var levelRender : display.LevelRender;
	public var rulers : display.Rulers;
	var bg : h2d.Bitmap;
	public var cursor : ui.Cursor;
	public var selection : Null<GenericLevelElement>;
	var selectionCursor : ui.Cursor;

	var levelHistory : Map<Int,LevelHistory> = new Map();
	public var curLevelHistory(get,never) : LevelHistory;
		inline function get_curLevelHistory() return levelHistory.get(curLevelId);


	public function new(parent:dn.Process, p:led.Project, path:String) {
		super(parent);

		App.ME.loadPage("editor");

		ME = this;
		createRoot(parent.root);
		projectFilePath = path;
		App.ME.registerRecentProject(path);

		// Events
		App.ME.jBody
			.on("keydown.client", onJsKeyDown )
			.on("keyup.client", onJsKeyUp )
			.mouseup( function(_) onMouseUp() )
			.mouseleave(function(_) onMouseUp() );

		Boot.ME.s2d.addEventListener( onEvent );

		ge = new GlobalEventDispatcher();
		ge.addGlobalListener( onGlobalEvent );

		watcher = new misc.FileWatcher();

		cursor = new ui.Cursor();
		selectionCursor = new ui.Cursor();
		selectionCursor.highlight();

		levelRender = new display.LevelRender();
		rulers = new display.Rulers();

		initUI();

		selectProject(p);
		needSaving = false;
	}

	public function initUI() {
		// Edit buttons
		jMainPanel.find("button.editProject").click( function(_) {
			if( ui.Modal.isOpen(ui.modal.panel.ProjectSettings) )
				ui.Modal.closeAll();
			else
				new ui.modal.panel.ProjectSettings();
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

		jMainPanel.find("input#enhanceActiveLayer")
			.prop("checked", levelRender.enhanceActiveLayer)
			.change( function(ev) {
				levelRender.setEnhanceActiveLayer( ev.getThis().prop("checked") );
			});


		jMainPanel.find("input#gridSnapping")
			.prop("checked", gridSnapping)
			.change( function(ev) {
				gridSnapping = ev.getThis().prop("checked");
			});


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

	public function makeFullFilePath(relPath:String) {
		var fp = dn.FilePath.fromFile( getProjectDir() +"/"+ relPath );
		return fp.full;
	}

	public function selectProject(p:led.Project) {
		watcher.clearAllWatches();

		project = p;
		project.tidy();

		// Load tilesets
		for(td in project.defs.tilesets)
			reloadTileset(td, true);

		// Check external enums
		for( relPath in project.defs.getExternalEnumPaths() ) {
			if( !JsTools.fileExists( makeFullFilePath(relPath) ) )
				new ui.modal.dialog.LostFile(relPath, function(newAbsPath) {
					var newRel = makeRelativeFilePath(newAbsPath);
					importer.HxEnum.load(newRel, true);
				});
		}


		curLevelId = project.levels[0].uid;
		curLayerId = -1;

		// Pick 1st layer in current level
		if( project.defs.layers.length>0 ) {
			for(li in curLevel.layerInstances) {
				curLayerId = li.def.uid;
				break;
			}
		}

		levelHistory = new Map();
		levelHistory.set( curLevelId, new LevelHistory(curLevelId) );

		ge.emit(ProjectSelected);

		// Tileset image hot-reloading
		for( td in project.defs.tilesets )
			watcher.watchTileset(td);
	}


	public function reloadTileset(td:led.def.TilesetDef, silentOk=false) {
		if( !td.hasAtlasPath() )
			return;

		var oldRelPath = td.relPath;
		var result = td.reloadImage( getProjectDir() );

		switch result {
			case FileNotFound:
				new ui.modal.dialog.LostFile( oldRelPath, function(newAbsPath) {
					var newRelPath = makeRelativeFilePath(newAbsPath);
					td.importAtlasImage( getProjectDir(), newRelPath );
					ge.emit( TilesetDefChanged );
				});

			case RemapLoss:
				var name = dn.FilePath.fromFile(td.relPath).fileWithExt;
				new ui.modal.dialog.Warning( Lang.t._("The image ::file:: was updated, but the new version is smaller than the previous one.\nSome tiles might have been lost in the process. It is recommended to check this carefully before saving this project!", { file:name } ) );

			case RemapSuccessful, Ok:
				if( !silentOk || result!=Ok ) {
					var name = dn.FilePath.fromFile(td.relPath).fileWithExt;
					N.success(Lang.t._("Tileset image ::file:: updated.", { file:name } ) );
				}
		}

		ge.emit(TilesetDefChanged);
	}

	function onJsKeyDown(ev:js.jquery.Event) {
		if( ev.keyCode==K.TAB && !ui.Modal.hasAnyOpen() )
			ev.preventDefault();

		keyDowns.set(ev.keyCode, true);
		onKeyPress(ev.keyCode);
	}

	function onJsKeyUp(ev:js.jquery.Event) {
		keyDowns.remove(ev.keyCode);
	}

	function onHeapsKeyDown(ev:hxd.Event) {
		keyDowns.set(ev.keyCode, true);
		onKeyPress(ev.keyCode);
	}

	function onHeapsKeyUp(ev:hxd.Event) {
		keyDowns.remove(ev.keyCode);
	}

	inline function hasInputFocus() {
		return App.ME.jBody.find("input:focus, textarea:focus").length>0;
	}
	function onKeyPress(keyId:Int) {
		switch keyId {
			case K.ESCAPE:
				if( ui.Modal.hasAnyOpen() )
					ui.Modal.closeAll();
				else
					clearSelection();

			case K.TAB:
				if( !ui.Modal.hasAnyOpen() ) {
					App.ME.jPage.toggleClass("compactPanel");
					updateAppBg();
				}

			case K.Z:
				if( !hasInputFocus() && !ui.Modal.hasAnyOpen() && isCtrlDown() )
					curLevelHistory.undo();

			case K.Y:
				if( !hasInputFocus() && !ui.Modal.hasAnyOpen() && isCtrlDown() )
					curLevelHistory.redo();

			case K.S:
				if( !hasInputFocus() && isCtrlDown() )
					onSave();

			case K.W:
				if( !hasInputFocus() && isCtrlDown() )
					onClose();

			case K.A:
				if( !hasInputFocus() )
					levelRender.setEnhanceActiveLayer( !levelRender.enhanceActiveLayer );

			case K.G:
				if( !hasInputFocus() ) {
					gridSnapping = !gridSnapping;
					jMainPanel.find("input#gridSnapping").prop("checked", gridSnapping);
				}

			case K.H:
				if( !hasInputFocus() )
					onHelp();


			#if debug
			case K.T:
				if( !hasInputFocus() ) {
					var t = haxe.Timer.stamp();
					var json = project.levels[0].toJson();
					App.ME.debug(dn.M.pretty(haxe.Timer.stamp()-t, 3)+"s");
				}
			#end
		}

		// Propagate to current tool
		if( !hasInputFocus() && !ui.Modal.hasAnyOpen() )
			curTool.onKeyPress(keyId);
	}

	function allowKeyPresses() {
		return !hasInputFocus();
	}


	public function setSelection(ge:GenericLevelElement) {
		switch ge {
			case IntGrid(_), Tile(_):
				clearSelection();
				return;

			case Entity(_):
		}

		selection = ge;
		selectionCursor.set(switch selection {
			case IntGrid(li, cx, cy): GridCell(li, cx,cy);
			case Entity(instance): Entity(instance.def, instance.x, instance.y);
			case Tile(li,cx,cy): Tiles(li, [li.getGridTile(cx,cy)], cx,cy);
		});

		ui.InstanceEditor.closeAll();
		switch selection {
			case null:
			case IntGrid(_):
			case Tile(_):

			case Entity(instance):
				new ui.InstanceEditor(instance);
		}
	}

	public function clearSelection() {
		selection = null;
		selectionCursor.set(None);
		ui.InstanceEditor.closeAll();
	}

	function initTool() {
		if( curTool!=null )
			curTool.destroy();

		clearSelection();
		cursor.set(None);
		if( curLayerDef==null )
			curTool = new tool.EmptyTool();
		else
			curTool = switch curLayerDef.type {
				case IntGrid: new tool.IntGridTool();
				case Entities: new tool.EntityTool();
				case Tiles: new tool.TileTool();
			}
	}

	public function pickGenericLevelElement(ge:Null<GenericLevelElement>) {
		switch ge {
			case null:

			case IntGrid(li, cx, cy):
				selectLayerInstance(li);
				var v = li.getIntGrid(cx,cy);
				curTool.as(tool.IntGridTool).selectValue(v);
				levelRender.showRect( cx*li.def.gridSize, cy*li.def.gridSize, li.def.gridSize, li.def.gridSize, li.getIntGridColorAt(cx,cy) );
				return true;

			case Entity(instance):
				for(ld in project.defs.layers) {
					var li = curLevel.getLayerInstance(ld);
					if( li.def.type!=Entities )
						continue;

					for(e in li.entityInstances)
						if( e==instance ) {
							selectLayerInstance(li);
							curTool.as(tool.EntityTool).selectValue(instance.defUid);
							levelRender.showRect( instance.left, instance.top, instance.def.width, instance.def.height, instance.def.color );
							return true;
						}
				}

			case Tile(li, cx, cy):
				selectLayerInstance(li);
				var tid = li.getGridTile(cx,cy);
				var td = project.defs.getTilesetDef(li.def.tilesetDefUid);
				if( td==null )
					return false;

				var savedSel = td.getSavedSelectionFor(tid);

				var t = curTool.as(tool.TileTool);
				if( savedSel==null || !isShiftDown() && !isCtrlDown() )
					t.selectValue( { ids:[tid], mode:t.getMode() } );
				else
					t.selectValue( savedSel );
				levelRender.showRect( cx*li.def.gridSize, cy*li.def.gridSize, li.def.gridSize, li.def.gridSize, 0xffcc00 );
				return true;
		}

		return false;
	}

	function onEvent(e:hxd.Event) {
		switch e.kind {
			case EPush: onMouseDown(e);
			case ERelease: onMouseUp();
			case EMove: onMouseMove(e);
			case EOver:
			case EOut: onMouseUp();
			case EWheel: onMouseWheel(e);
			case EFocus:
			case EFocusLost: onMouseUp();
			case EKeyDown: onHeapsKeyDown(e);
			case EKeyUp: onHeapsKeyUp(e);
			case EReleaseOutside: onMouseUp();
			case ETextInput:
			case ECheck:
		}
	}

	function onMouseDown(e:hxd.Event) {
		curTool.startUsing( getMouse(), e.button );
		rulers.onMouseDown( getMouse(), e.button );
	}
	function onMouseUp() {
		if( curTool.isRunning() )
			curTool.stopUsing( getMouse() );
		rulers.onMouseUp( getMouse() );
	}
	function onMouseMove(e:hxd.Event) {
		curTool.onMouseMove( getMouse() );
		rulers.onMouseMove( getMouse() );
	}

	function onMouseWheel(e:hxd.Event) {
		var m = getMouse();
		var mouseX = m.levelX;
		var mouseY = m.levelY;
		levelRender.zoom += -e.wheelDelta*0.1 * levelRender.zoom;
		var panRatio = e.wheelDelta < 0 ? 0.15 : 0.05;
		levelRender.focusLevelX = levelRender.focusLevelX*(1-panRatio) + mouseX*panRatio;
		levelRender.focusLevelY = levelRender.focusLevelY*(1-panRatio) + mouseY*panRatio;
	}

	public function selectLevel(l:led.Level) {
		if( curLevelId==l.uid )
			return;

		curLevelId = l.uid;
		ge.emit(LevelSelected);
	}

	public function selectLayerInstance(l:led.inst.LayerInstance) {
		if( curLayerId==l.def.uid )
			return;

		curLayerId = l.def.uid;
		ge.emit(LayerInstanceSelected);
	}

	function onHelp() {
		ui.Modal.closeAll();
		var m = new ui.Modal();
		m.loadTemplate("help","helpWindow");
	}

	function onClose(?bt:js.jquery.JQuery) {
		ui.Modal.closeAll();
		if( needSaving )
			new ui.modal.dialog.UnsavedChanges(bt, App.ME.openHome);
		else
			App.ME.openHome();
	}

	public function onSave(?bypassMissing=false) {
		if( !bypassMissing && !JsTools.fileExists(projectFilePath) ) {
			new ui.modal.dialog.Confirm(
				Lang.t._("The project file is no longer in ::path::. Save to this path anyway?", { path:projectFilePath }),
				onSave.bind(true)
			);
			return;
		}

		var data = JsTools.prepareProjectFile(project);
		JsTools.writeFileBytes(projectFilePath, data.bytes);
		needSaving = false;
		N.msg("Saved to "+projectFilePath);
	}

	function onGlobalEvent(e:GlobalEvent) {
		switch e {
			case ViewportChanged:
			case LayerInstanceSelected:
			case LevelSelected:
			case LayerInstanceVisiblityChanged:
			case ToolOptionChanged:

			case _:
				needSaving = true;
		}

		switch e {
			case ViewportChanged:

			case EnumDefAdded, EnumDefRemoved, EnumDefChanged, EnumDefSorted, EnumDefValueRemoved:

			case LayerInstanceChanged:
			case EntityFieldDefChanged:
			case EntityFieldSorted:
			case EntityDefSorted:
			case EntityFieldInstanceChanged:
			case ToolOptionChanged:

			case LayerInstanceSelected:
				clearSelection();
				initTool();
				updateLayerList();
				updateGuide();

			case LayerInstanceVisiblityChanged:
				clearSelection();
				updateLayerList();

			case EntityFieldAdded, EntityFieldRemoved:
				initTool();
				levelRender.invalidate();

			case LayerDefAdded, LayerDefRemoved:
				updateLayerList();
				initTool();
				levelRender.invalidate();

			case ProjectSelected:
				updateAppBg();
				updateTitles();
				updateLayerList();
				updateGuide();
				Tool.clearSelectionMemory();
				initTool();

			case LevelSettingsChanged:
				updateTitles();
				updateGuide();

			case LevelAdded:
			case LevelResized:
			case LevelSorted:

			case LevelSelected:
				updateLayerList();
				updateTitles();
				updateGuide();
				initTool();
				if( !levelHistory.exists(curLevelId) )
					levelHistory.set(curLevelId, new LevelHistory(curLevelId) );

			case LayerInstanceRestoredFromHistory, LevelRestoredFromHistory:
				updateAppBg();
				updateLayerList();
				updateTitles();
				updateGuide();
				initTool();

			case TilesetDefChanged, TilesetDefRemoved, EntityDefChanged, EntityDefAdded, EntityDefRemoved:
				initTool();
				updateGuide();

			case TilesetDefAdded:

			case ProjectSettingsChanged:
				updateAppBg();
				updateTitles();

			case LayerDefChanged, LayerDefSorted:
				if( curLayerDef==null && project.defs.layers.length>0 )
					selectLayerInstance( curLevel.getLayerInstance(project.defs.layers[0]) );
				initTool();
				updateGuide();
				updateLayerList();
		}

		if( curLevelHistory!=null )
			curLevelHistory.manualOnGlobalEvent(e);
	}

	function updateAppBg() {
		if( bg!=null )
			bg.remove();

		bg = new h2d.Bitmap( h2d.Tile.fromColor(project.bgColor) );
		root.add(bg, Const.DP_BG);
		onResize();
	}

	override function onResize() {
		super.onResize();
		if( bg!=null ) {
			bg.scaleX = canvasWid();
			bg.scaleY = h();
		}
	}

	inline function canvasWid() {
		return App.ME.jCanvas.outerWidth() * js.Browser.window.devicePixelRatio;
	}

	inline function canvasHei() {
		return App.ME.jCanvas.outerHeight() * js.Browser.window.devicePixelRatio;
	}

	function updateTitles() {
		App.ME.setWindowTitle( project.name+" ("+curLevel.identifier+")" );
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

				case Entities:
					_createGuideBlock([K.ALT], "mouseLeft", L.t._("Pick"));
					_createGuideBlock([K.CTRL,K.ALT], "mouseLeft", L.t._("Copy"));
					_createGuideBlock([K.CTRL], null, L.t._("(while moving) Free mode"));

				case Tiles:
					_createGuideBlock([K.SHIFT], "mouseLeft", L.t._("Rectangle"));
					_createGuideBlock([K.ALT], "mouseLeft", L.t._("Pick"));
					_createGuideBlock([K.SHIFT,K.ALT], "mouseLeft", L.t._("Pick saved selection"));
			}
		}
	}

	public function updateLayerList() {
		var list = jLayers;
		list.empty();

		for(ld in project.defs.layers) {
			var li = curLevel.getLayerInstance(ld);
			var e = App.ME.jBody.find("xml.layer").clone().children().wrapAll("<li/>").parent();
			list.append(e);

			if( li==curLayerInstance )
				e.addClass("active");

			if( !levelRender.isLayerVisible(li) )
				e.addClass("hidden");

			// Icon
			var icon = e.find(".icon");
			switch li.def.type {
				case IntGrid: icon.addClass("intGrid");
				case Entities: icon.addClass("entity");
				case Tiles: icon.addClass("tile");
			}

			// Name
			var name = e.find(".name");
			name.text(li.def.identifier);
			e.click( function(_) {
				selectLayerInstance(li);
			});


			// Visibility button
			var vis = e.find(".vis");
			if( levelRender.isLayerVisible(li) )
				vis.find(".off").hide();
			else
				vis.find(".on").hide();
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

	public inline function isKeyDown(keyId:Int) return keyDowns.get(keyId)==true;
	public inline function isShiftDown() return keyDowns.get(Key.SHIFT)==true;
	public inline function isCtrlDown() return keyDowns.get(Key.CTRL)==true;
	public inline function isAltDown() return keyDowns.get(Key.ALT)==true;
	public inline function hasAnyToggleKeyDown() return isShiftDown() || isCtrlDown() || isAltDown();


	public inline function getMouse() : MouseCoords {
		return new MouseCoords(Boot.ME.s2d.mouseX, Boot.ME.s2d.mouseY);
	}

	override function onDispose() {
		super.onDispose();

		if( ME==this )
			ME = null;

		watcher = null;

		ge.dispose();
		ge = null;

		Boot.ME.s2d.removeEventListener(onEvent);

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
