import hxd.Key;

class Client extends dn.Process {
	public static var ME : Client;

	public var appWin(get,never) : nw.Window; inline function get_appWin() return nw.Window.get();
	public var jBody(get,never) : J; inline function get_jBody() return new J("body");
	public var jLayers(get,never) : J; inline function get_jLayers() return new J("#layers");
	public var jMainBar(get,never) : J; inline function get_jMainBar() return new J("#mainBar");
	public var jPalette(get,never) : J; inline function get_jPalette() return new J("#palette ul");

	public var ge : GlobalEventDispatcher;
	public var project : ProjectData;
	var curLevelId : Int;
	var curLayerId : Int;

	public var curLevel(get,never) : LevelData; inline function get_curLevel() return project.getLevel(curLevelId);
	public var curLayerDef(get,never) : LayerDef; inline function get_curLayerDef() return project.getLayerDef(curLayerId);
	public var curLayerContent(get,never) : LayerContent; inline function get_curLayerContent() return curLevel.getLayerContent(curLayerId);

	public var levelRender : render.LevelRender;
	public var curTool : Tool<Dynamic>;

	public var cursor : ui.Cursor;

	var toggleKeys : Map<Int,Bool> = new Map();

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

		ge = new GlobalEventDispatcher();
		ge.watchAny( onGlobalEvent );

		jBody.mouseup(function(_) {
			onMouseUp();
		});
		jBody.mouseleave(function(_) {
			onMouseUp();
		});

		new J("button.debug1").click( function(ev) {
			var w = new ui.Dialog(ev.getThis());
			w.addButton("btA", function() N.debug("A"));
			w.addButton("btB", function() N.debug("B"));
			w.addButton("btC", function() N.debug("C"));
		} );
		new J("button.debug2").click( function(ev) { new ui.dialog.Confirm(ev.getThis(), function() N.debug("ok")); } );

		new J("button.save").click( function(_) { N.notImplemented(); } );
		new J("button.editLayers").click( function(_) new ui.win.EditLayers() );
		new J("button.editEntities").click( function(_) new ui.win.EditEntities() );

		Boot.ME.s2d.addEventListener( onEvent );

		project = new data.ProjectData();
		var ed = project.createEntityDef("Hero");
		ed.color = 0x00ff00;
		var ld = project.createLayerDef(Entities,"Entities");
		var ld = project.createLayerDef(IntGrid,"Decorations");
		ld.gridSize = 8;
		ld.getIntGridValue(0).color = 0x00ff00;
		project.layerDefs[0].name = "Collisions";


		project.createLevel();

		curLevelId = project.levels[0].uid;
		curLayerId = project.layerDefs[0].uid;

		initTool();
		levelRender = new render.LevelRender();

		updateLayerList();
	}

	function onJsKeyDown(ev:js.jquery.Event) {
		if( ev.shiftKey ) toggleKeys.set(Key.SHIFT, true);
		if( ev.ctrlKey ) toggleKeys.set(Key.CTRL, true);
		if( ev.altKey ) toggleKeys.set(Key.ALT, true);
	}

	function onJsKeyUp(ev:js.jquery.Event) {
		if( ev.shiftKey ) toggleKeys.set(Key.SHIFT, false);
		if( ev.ctrlKey ) toggleKeys.set(Key.CTRL, false);
		if( ev.altKey ) toggleKeys.set(Key.ALT, false);
	}

	function onJsKeyPress(ev:js.jquery.Event) {
	}

	function initTool() {
		if( curTool!=null )
			curTool.destroy();
		curTool = new tool.IntGridBrush();
	}

	function onEvent(e:hxd.Event) {
		switch e.kind {
			case EPush: onMouseDown(e);
			case ERelease: onMouseUp();
			case EMove: onMouseMove(e);
			case EOver:
			case EOut: onMouseUp();
			case EWheel:
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
		if( levelRender.isLayerVisible(curLayerContent) )
			curTool.startUsing( getMouse(), e.button );
	}
	function onMouseUp() {
		if( curTool.isRunning() )
			curTool.stopUsing( getMouse() );
	}
	function onMouseMove(e:hxd.Event) {
		var m = getMouse();
		curTool.onMouseMove(m);
	}

	public function selectLayer(l:LayerContent) {
		curLayerId = l.def.uid;
		levelRender.onCurrentLayerChange(curLayerContent);
		curTool.updatePalette();
		updateLayerList();
	}

	function onGlobalEvent(e:GlobalEvent) {
		switch e {
			case LayerDefChanged, LayerDefSorted, EntityDefChanged, EntityDefSorted, EntityFieldChanged :
				project.checkDataIntegrity();
				if( curLayerContent==null )
					selectLayer(curLevel.layerContents[0]);
				initTool();
				updateLayerList();

			case LayerContentChanged:
		}
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
				ev.stopPropagation();
				levelRender.toggleLayer(lc);
				updateLayerList();
			});

		}
	}


	public inline function isShiftDown() return toggleKeys.get(Key.SHIFT)==true;
	public inline function isCtrlDown() return toggleKeys.get(Key.CTRL)==true;


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
}
