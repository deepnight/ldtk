import hxd.Key;

class Client extends dn.Process {
	public static var ME : Client;

	public var appWin(get,never) : nw.Window; inline function get_appWin() return nw.Window.get();
	public var jBody(get,never) : J; inline function get_jBody() return new J("body");
	public var jLayers(get,never) : J; inline function get_jLayers() return new J("#layers");
	public var jMainPanel(get,never) : J; inline function get_jMainPanel() return new J("#mainPanel");
	public var jInstancePanel(get,never) : J; inline function get_jInstancePanel() return new J("#instancePanel");
	public var jPalette(get,never) : J; inline function get_jPalette() return new J("#palette");

	public var curLevel(get,never) : LevelData; inline function get_curLevel() return project.getLevel(curLevelId);
	public var curLayerDef(get,never) : LayerDef; inline function get_curLayerDef() return project.defs.getLayerDef(curLayerId);
	public var curLayerInstance(get,never) : LayerInstance; inline function get_curLayerInstance() return curLevel.getLayerInstance(curLayerDef);

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
		});
		#end

		jMainPanel.find("button.save").click( function(_) N.notImplemented() );
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


		project = new data.ProjectData();

		// Placeholder data
		var ed = project.defs.createEntityDef("Hero");
		ed.color = 0x00ff00;
		ed.width = 24;
		ed.height = 32;
		// ed.maxPerLevel = 1;
		ed.setPivot(0.5,1);
		var fd = ed.createField(project, F_Int);
		fd.name = "life";
		fd.setDefault(Std.string(3));
		fd.setMin("1");
		fd.setMax("10");
		var ld = project.defs.layers[0];
		ld.name = "Collisions";
		ld.getIntGridValueDef(0).name = "walls";
		ld.addIntGridValue(0x00ff00, "grass");
		ld.addIntGridValue(0x0000ff, "water");
		var ld = project.defs.createLayerDef(Entities,"Entities");
		var ld = project.defs.createLayerDef(IntGrid,"Decorations");
		ld.gridSize = 8;
		ld.displayOpacity = 0.7;
		ld.getIntGridValueDef(0).color = 0x00ff00;

		project.createLevel();
		curLevelId = project.levels[0].uid;
		curLayerId = project.defs.layers[0].uid;

		levelRender = new display.LevelRender();
		initTool();
		updateBg();
		updateProjectTitle();
		updateLayerList();
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

		cursor.set(None);
		curTool = switch curLayerDef.type {
			case IntGrid: new tool.IntGridTool();
			case Entities: new tool.EntityTool();
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
		if( levelRender.isLayerVisible(curLayerInstance) && curTool.canBeUsed() )
			curTool.startUsing( getMouse(), e.button );
	}
	function onMouseUp() {
		if( curTool!=null && curTool.isRunning() )
			curTool.stopUsing( getMouse() );
	}
	function onMouseMove(e:hxd.Event) {
		var m = getMouse();
		curTool.onMouseMove(m);
	}

	function onMouseWheel(e:hxd.Event) {
		levelRender.zoom += -e.wheelDelta*0.2;
	}

	public function debug(msg:Dynamic, clear=true) {
		var e = new J("#debug");
		if( clear )
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
				display.LevelRender.invalidateCaches();

			case ProjectChanged:
				updateBg();
				updateProjectTitle();

			case LayerDefChanged, LayerDefSorted:
				if( curLayerDef==null )
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
