import hxd.Key;

class Client extends dn.Process {
	public static var ME : Client;

	public var appWin(get,never) : nw.Window; inline function get_appWin() return nw.Window.get();
	public var jBody(get,never) : J; inline function get_jBody() return new J("body");
	public var jMainPanel(get,never) : J; inline function get_jMainPanel() return new J("#mainPanel");
	public var jInstancePanel(get,never) : J; inline function get_jInstancePanel() return new J("#instancePanel");
	public var jLayers(get,never) : J; inline function get_jLayers() return new J("#layers");
	public var jPalette(get,never) : J; inline function get_jPalette() return new J("#palette");

	public var curLevel(get,never) : LevelData;
	inline function get_curLevel() return project.getLevel(curLevelId);

	public var curLayerDef(get,never) : Null<LayerDef>;
	inline function get_curLayerDef() return project.defs.getLayerDef(curLayerId);

	public var curLayerInstance(get,never) : Null<LayerInstance>;
	function get_curLayerInstance() return curLayerDef==null ? null : curLevel.getLayerInstance(curLayerDef);

	public var ge : GlobalEventDispatcher;
	public var project : ProjectData;
	var curLevelId : Int;
	var curLayerId : Int;

	public var levelRender : display.LevelRender;
	var bg : h2d.Bitmap;
	public var curTool : Tool<Dynamic>;

	public var cursor : ui.Cursor;
	public var selection : Null<GenericLevelElement>;
	var selectionCursor : ui.Cursor;

	var keyDowns : Map<Int,Bool> = new Map();



	public function new() {
		super();

		ME = this;
		createRoot(Boot.ME.s2d);
		appWin.maximize();

		// Events
		new J("body")
			.on("keydown.client", onJsKeyDown )
			.on("keyup.client", onJsKeyUp )
			.mouseup( function(_) onMouseUp() )
			.mouseleave(function(_) onMouseUp() );

		Boot.ME.s2d.addEventListener( onEvent );

		ge = new GlobalEventDispatcher();
		ge.listenAll( onGlobalEvent );


		cursor = new ui.Cursor();
		selectionCursor = new ui.Cursor();
		selectionCursor.highlight();

		initUI();

		project = try {
			var raw = dn.LocalStorage.read("test");
			var json = haxe.Json.parse(raw);
			ProjectData.fromJson(json);
		}
		catch( e:Dynamic ) {
			ProjectData.createEmpty();
		}

		levelRender = new display.LevelRender();
		useProject(project);
		dn.Process.resizeAll();
	}



	public function initUI() {
		jMainPanel.find("*").off();

		// Main file actions
		jMainPanel.find("button.new").click( function(ev) {
			ui.Modal.closeAll();
			new ui.dialog.Confirm(ev.getThis(), function() {
				useProject( ProjectData.createEmpty() );
				N.msg("New project created.");
			});
		});

		jMainPanel.find("button.load").click( function(_) {
			ui.Modal.closeAll();
			var raw = dn.LocalStorage.read("test");
			if( raw==null ) {
				N.error("No data found.");
				return;
			}
			var json = try haxe.Json.parse(raw) catch(e:Dynamic) null;
			if( json==null ) {
				N.error("Invalid JSON!");
				return;
			}
			useProject( ProjectData.fromJson(json) );
			N.msg("Loaded from local storage.");
		});

		jMainPanel.find("button.save").click( function(_) {
			ui.Modal.closeAll();
			dn.LocalStorage.write("test", dn.HaxeJson.prettify( haxe.Json.stringify( project.toJson() ) ) );
			N.msg("Saved to local storage.");
		});


		// Edit buttons
		jMainPanel.find("button.editProject").click( function(_) {
			if( ui.Modal.isOpen(ui.modal.ProjectSettings) )
				ui.Modal.closeAll();
			else
				new ui.modal.ProjectSettings();
		});
		jMainPanel.find("button.editLayers").click( function(_) {
			if( ui.Modal.isOpen(ui.modal.EditLayerDefs) )
				ui.Modal.closeAll();
			else
				new ui.modal.EditLayerDefs();
		});
		jMainPanel.find("button.editEntities").click( function(_) {
			if( ui.Modal.isOpen(ui.modal.EditEntityDefs) )
				ui.Modal.closeAll();
			else
				new ui.modal.EditEntityDefs();
		});



		#if debug
		jMainPanel.find("button.debug").click( function(ev) {
			var w = new ui.Dialog( ev.getThis() );
			function test(json:Dynamic) {
				trace( dn.HaxeJson.stringify(json,true) );
				N.debug("Done");
			}

			w.jContent.append('<p>Serialization tests</p>');
			w.addButton("Project", function() test( project.toJson() ));
			w.addButton("Definitions", function() test( project.defs.toJson() ));
			w.addButton("Current level", function() test( curLevel.toJson() ));
			w.addButton("Current layer", function() test( curLayerInstance.toJson() ));

			w.addButton("Clone: FieldDef", function() {
				var fd = project.defs.entities[0].fieldDefs[0];
				trace( dn.HaxeJson.prettify( haxe.Json.stringify(fd.toJson()) ) );
				trace( dn.HaxeJson.prettify( haxe.Json.stringify(fd.clone().toJson()) ) );
			});

			w.addButton("Clone: LayerDef", function() {
				var ld = project.defs.layers[0];
				trace( dn.HaxeJson.prettify( haxe.Json.stringify(ld.toJson()) ) );
				trace( dn.HaxeJson.prettify( haxe.Json.stringify(ld.clone().toJson()) ) );
			});

			w.addButton("Clone: EntityDef", function() {
				var ed = project.defs.entities[0];
				trace( dn.HaxeJson.prettify( haxe.Json.stringify(ed.toJson()) ) );
				trace( dn.HaxeJson.prettify( haxe.Json.stringify(ed.clone().toJson()) ) );
			});

			w.addButton("Clone: Defs", function() {
				var defs = project.defs;
				trace( dn.HaxeJson.prettify( haxe.Json.stringify(defs.toJson()) ) );
				trace( dn.HaxeJson.prettify( haxe.Json.stringify(defs.clone().toJson()) ) );
			});

			w.addButton("Clone: curLevel", function() {
				trace( dn.HaxeJson.prettify( haxe.Json.stringify(curLevel.toJson()) ) );
				trace( dn.HaxeJson.prettify( haxe.Json.stringify(curLevel.clone().toJson()) ) );
			});

			w.addButton("Clone: curLayerInstance", function() {
				trace( dn.HaxeJson.prettify( haxe.Json.stringify(curLayerInstance.toJson()) ) );
				trace( dn.HaxeJson.prettify( haxe.Json.stringify(curLayerInstance.clone().toJson()) ) );
			});

			w.addButton("Clone: project", function() {
				trace( dn.HaxeJson.prettify( haxe.Json.stringify(project.clone().toJson()) ) );
				project = project.clone();
				levelRender.invalidate();
				N.debug("Replaced with a copy");
			});
		});
		#end
	}

	public function useProject(p:ProjectData) {
		project = p;
		project.tidy();
		curLevelId = project.levels[0].uid;
		curLayerId = curLevel.layerInstances[0]==null ? -1 : curLevel.layerInstances[0].layerDefId;

		Tool.clearSelectionMemory();
		display.LevelRender.invalidateCaches();

		levelRender.fit();
		levelRender.invalidate();
		updateBg();
		updateLayerList();
		updateProjectTitle();
		initTool();
	}

	function onJsKeyDown(ev:js.jquery.Event) {
		keyDowns.set(ev.keyCode, true);
		onKeyDown(ev.keyCode);
	}

	function onJsKeyUp(ev:js.jquery.Event) {
		keyDowns.remove(ev.keyCode);
	}

	function onHeapsKeyDown(ev:hxd.Event) {
		keyDowns.set(ev.keyCode, true);
		onKeyDown(ev.keyCode);
	}

	function onHeapsKeyUp(ev:hxd.Event) {
		keyDowns.remove(ev.keyCode);
	}

	function onKeyDown(keyId:Int) {
		if( keyId==K.ESCAPE )
			if( ui.Modal.hasAnyOpen() )
				ui.Modal.closeAll();
			else
				clearSelection();
	}


	public function setSelection(ge:GenericLevelElement) {
		switch ge {
			case IntGrid(_):
				clearSelection();
				return;

			case Entity(_):
		}

		selection = ge;
		selectionCursor.set(switch selection {
			case IntGrid(li, cx, cy): GridCell(li, cx,cy);
			case Entity(instance): Entity(instance.def, instance.x, instance.y);
		});

		ui.InstanceEditor.closeAll();
		switch selection {
			case null:
			case IntGrid(li, cx, cy):

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
				case Tiles: new tool.EmptyTool(); // TODO
			}
	}

	public function pickGenericLevelElement(ge:Null<GenericLevelElement>) {
		switch ge {
			case null:

			case IntGrid(li, cx, cy):
				selectLayerInstance(li);
				var v = li.getIntGrid(cx,cy);
				curTool.as(tool.IntGridTool).selectValue(v);
				return true;

			case Entity(instance):
				for(ld in project.defs.layers) {
					var li = curLevel.getLayerInstance(ld);
					if( li.def.type!=Entities )
						continue;

					for(e in li.entityInstances)
						if( e==instance ) {
							selectLayerInstance(li);
							curTool.as(tool.EntityTool).selectValue(instance.defId);
							return true;
						}
				}
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
	}
	function onMouseUp() {
		if( curTool.isRunning() )
			curTool.stopUsing( getMouse() );
	}
	function onMouseMove(e:hxd.Event) {
		curTool.onMouseMove( getMouse() );
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

	public function debug(msg:Dynamic, append=false) {
		var e = new J("#debug");
		if( !append )
			e.empty();
		e.show();

		var line = new J("<p/>");
		line.append( Std.string(msg) );
		line.prependTo(e);
	}

	public function selectLayerInstance(l:LayerInstance) {
		if( curLayerId==l.def.uid )
			return;

		clearSelection();
		curLayerId = l.def.uid;
		levelRender.onCurrentLayerChange(curLayerInstance);
		curTool.updatePalette();
		updateLayerList();
		initTool();
	}

	function onGlobalEvent(e:GlobalEvent) {
		switch e {
			case LayerInstanceChanged:
			case EntityFieldChanged:
			case EntityFieldSorted:
			case EntityDefSorted:

			case EntityDefChanged :
				initTool();
				display.LevelRender.invalidateCaches();

			case ProjectChanged:
				updateBg();
				updateProjectTitle();

			case LayerDefChanged, LayerDefSorted:
				if( curLayerDef==null && project.defs.layers.length>0 )
					selectLayerInstance( curLevel.getLayerInstance(project.defs.layers[0]) );
				initTool();
				updateLayerList();

		}
	}

	function updateBg() {
		if( bg!=null )
			bg.remove();

		bg = new h2d.Bitmap( h2d.Tile.fromColor(project.bgColor) );
		root.add(bg, Const.DP_BG);
		onResize();
	}

	override function onResize() {
		super.onResize();
		if( bg!=null ) {
			bg.scaleX = w();
			bg.scaleY = h();
		}
	}

	function updateProjectTitle() {
		appWin.title = project.name+" -- L-Ed v"+Const.APP_VERSION;
		jBody.find("h2#projectTitle").text( project.name );
	}

	public function updateLayerList() {
		var list = jLayers;
		list.empty();

		for(ld in project.defs.layers) {
			var li = curLevel.getLayerInstance(ld);
			var e = jBody.find("xml.layer").clone().children().wrapAll("<li/>").parent();
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
			name.text(li.def.name);
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
				clearSelection();
				updateLayerList();
			});

		}
	}


	public inline function isKeyDown(keyId:Int) return keyDowns.get(keyId)==true;
	public inline function isShiftDown() return keyDowns.get(Key.SHIFT)==true;
	public inline function isCtrlDown() return keyDowns.get(Key.CTRL)==true;
	public inline function isAltDown() return keyDowns.get(Key.ALT)==true;


	public inline function getMouse() : MouseCoords {
		return new MouseCoords(Boot.ME.s2d.mouseX, Boot.ME.s2d.mouseY);
	}

	override function onDispose() {
		super.onDispose();

		if( ME==this )
			ME = null;

		ge.dispose();
		Boot.ME.s2d.removeEventListener(onEvent);

		new J("body").off(".client");
	}

	override function update() {
		super.update();
	}
}
