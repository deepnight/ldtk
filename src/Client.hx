import hxd.Key;

class Client extends dn.Process {
	public static var ME : Client;

	public var appWin(get,never) : nw.Window; inline function get_appWin() return nw.Window.get();
	public var jBody(get,never) : J; inline function get_jBody() return new J("body");
	public var jLayers(get,never) : J; inline function get_jLayers() return new J("#layers");
	public var jMainBar(get,never) : J; inline function get_jMainBar() return new J("#mainBar");
	public var jInstancePanel(get,never) : J; inline function get_jInstancePanel() return new J("#instancePanel");
	public var jPalette(get,never) : J; inline function get_jPalette() return new J("#palette ul");

	public var ge : GlobalEventDispatcher;
	public var project : ProjectData;
	var curLevelId : Int;
	var curLayerId : Int;

	public var curLevel(get,never) : LevelData; inline function get_curLevel() return project.getLevel(curLevelId);
	public var curLayerDef(get,never) : LayerDef; inline function get_curLayerDef() return project.getLayerDef(curLayerId);
	public var curLayerContent(get,never) : LayerContent; inline function get_curLayerContent() return curLevel.getLayerContent(curLayerId);

	public var levelRender : display.LevelRender;
	public var curTool : Tool<Dynamic>;

	public var cursor : ui.Cursor;
	public var selection : Null<GenericLevelElement>;
	var selectionCursor : ui.Cursor;

	var keyDowns : Map<Int,Bool> = new Map();

	public function new() {
		super();

		ME = this;
		createRoot(Boot.ME.s2d);
		appWin.title = "L-Ed v"+Const.APP_VERSION;
		appWin.maximize();

		new J("body")
			.on("keypress.client", onJsKeyPress )
			.on("keydown.client", onJsKeyDown )
			.on("keyup.client", onJsKeyUp );

		cursor = new ui.Cursor();

		selectionCursor = new ui.Cursor();
		selectionCursor.highlight();

		ge = new GlobalEventDispatcher();
		ge.listenAll( onGlobalEvent );

		jBody.mouseup(function(_) {
			onMouseUp();
		});
		jBody.mouseleave(function(_) {
			onMouseUp();
		});

		new J("button.save").click( function(_) N.notImplemented() );
		new J("button.editProject").click( function(_) {
			if( ui.Modal.isOpen(ui.modal.ProjectSettings) )
				ui.Modal.closeAll();
			else
				new ui.modal.ProjectSettings();
		});
		new J("button.editLayers").click( function(_) {
			if( ui.Modal.isOpen(ui.modal.EditLayerDefs) )
				ui.Modal.closeAll();
			else
				new ui.modal.EditLayerDefs();
		});
		new J("button.editEntities").click( function(_) {
			if( ui.Modal.isOpen(ui.modal.EditEntityDefs) )
				ui.Modal.closeAll();
			else
				new ui.modal.EditEntityDefs();
		});

		// new J("#layers, #palette").click( function(ev) {
		// 	if( ui.Window.hasAnyOpen() ) {
		// 		ui.Window.closeAll();
		// 		ev.stopPropagation();
		// 	}
		// });

		Boot.ME.s2d.addEventListener( onEvent );

		project = new data.ProjectData();

		// Placeholder data
		var ed = project.createEntityDef("Hero");
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
		var ld = project.layerDefs[0];
		ld.name = "Collisions";
		ld.addIntGridValue(0x00ff00);
		ld.addIntGridValue(0x0000ff);
		var ld = project.createLayerDef(Entities,"Entities");
		var ld = project.createLayerDef(IntGrid,"Decorations");
		ld.gridSize = 8;
		ld.getIntGridValueDef(0).color = 0x00ff00;


		project.createLevel();

		curLevelId = project.levels[0].uid;
		curLayerId = project.layerDefs[0].uid;

		initTool();
		levelRender = new display.LevelRender();

		updateLayerList();
	}

	function onJsKeyDown(ev:js.jquery.Event) {
		keyDowns.set(ev.keyCode, true);
	}

	function onJsKeyUp(ev:js.jquery.Event) {
		keyDowns.remove(ev.keyCode);
	}

	function onJsKeyPress(ev:js.jquery.Event) {
	}

	function onHeapsKeyDown(ev:hxd.Event) {
		keyDowns.set(ev.keyCode, true);
	}

	function onHeapsKeyUp(ev:hxd.Event) {
		keyDowns.remove(ev.keyCode);
	}


	public function setSelection(ge:GenericLevelElement) {
		selection = ge;
		selectionCursor.set(switch selection {
			case IntGrid(lc, cx, cy): GridCell(lc, cx,cy);
			case Entity(instance): Entity(instance.def, instance.x, instance.y);
		});

		ui.InstanceEditor.closeAll();
		switch selection {
			case null:
			case IntGrid(lc, cx, cy):

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

			case IntGrid(lc, cx, cy):
				selectLayer(lc);
				var v = lc.getIntGrid(cx,cy);
				curTool.as(tool.IntGridTool).selectValue(v);
				return true;

			case Entity(instance):
				for(lc in curLevel.layerContents) {
					if( lc.def.type!=Entities )
						continue;

					for(e in lc.entityInstances)
						if( e==instance ) {
							selectLayer(lc);
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
		if( levelRender.isLayerVisible(curLayerContent) && curTool.canBeUsed() )
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

	public function selectLayer(l:LayerContent) {
		if( curLayerId==l.def.uid )
			return;

		clearSelection();
		curLayerId = l.def.uid;
		levelRender.onCurrentLayerChange(curLayerContent);
		curTool.updatePalette();
		updateLayerList();
		initTool();
	}

	function onGlobalEvent(e:GlobalEvent) {
		switch e {
			case LayerContentChanged:

			case _:
				project.checkDataIntegrity();
				if( curLayerContent==null )
					selectLayer(curLevel.layerContents[0]);
				initTool();
				updateLayerList();
		}

		if( e==EntityDefChanged )
			display.LevelRender.invalidateCaches();
	}

	public function updateLayerList() {
		var list = jLayers.find("ul");
		list.empty();

		for(lc in curLevel.layerContents) {
			var e = jLayers.find("xml.layer").clone().children().wrapAll("<li/>").parent();
			list.append(e);

			if( lc==curLayerContent )
				e.addClass("active");

			if( !levelRender.isLayerVisible(lc) )
				e.addClass("hidden");

			// Icon
			var icon = e.find(".icon");
			switch lc.def.type {
				case IntGrid: icon.addClass("intGrid");
				case Entities: icon.addClass("entity");
			}

			// Name
			var name = e.find(".name");
			name.text(lc.def.name);
			e.click( function(_) {
				selectLayer(lc);
			});


			// Visibility button
			var vis = e.find(".vis");
			if( levelRender.isLayerVisible(lc) )
				vis.find(".off").hide();
			else
				vis.find(".on").hide();
			vis.click( function(ev) {
				if( ui.Modal.closeAll() )
					return;
				ev.stopPropagation();
				levelRender.toggleLayer(lc);
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
