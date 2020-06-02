class Client extends dn.Process {
	public static var ME : Client;

	public var appWin(get,never) : nw.Window; inline function get_appWin() return nw.Window.get();
	public var jBody(get,never) : J; inline function get_jBody() return new J("body");
	public var jLayers(get,never) : J; inline function get_jLayers() return new J(".panel .layersList");
	public var jMainBar(get,never) : J; inline function get_jMainBar() return new J("#mainBar");
	public var jPalette(get,never) : J; inline function get_jPalette() return new J("#palette ul");

	public var project : ProjectData;
	var curLevelId : Int;
	var curLayerId : Int;

	public var curLevel(get,never) : LevelData; inline function get_curLevel() return project.getLevel(curLevelId);
	public var curLayerDef(get,never) : LayerDef; inline function get_curLayerDef() return project.getLayerDef(curLayerId);
	public var curLayerContent(get,never) : LayerContent; inline function get_curLayerContent() return curLevel.getLayerContent(curLayerId);

	public var levelRender : render.LevelRender;
	public var curTool : Tool<Dynamic>;

	public function new() {
		super();

		ME = this;
		createRoot(Boot.ME.s2d);
		appWin.title = "LEd v"+Const.APP_VERSION;
		// appWin.maximize();

		jBody.mouseup(function(_) {
			onMouseUp();
		});
		jBody.mouseleave(function(_) {
			onMouseUp();
		});

		// new J(".projectSettings").click( function(_) {} );
		new J("button.editLayers").click( function(_) new ui.win.EditLayers() );

		Boot.ME.s2d.addEventListener( onEvent );

		project = new data.ProjectData();
		// project.createLayerDef(IntGrid,"First layer");
		// project.createLayerDef(IntGrid,"Other");
		// var l = project.createLayerDef(IntGrid,"Last one");
		// l.gridSize = 8;

		project.createLevel();

		curLevelId = project.levels[0].uid;
		curLayerId = project.layerDefs[0].uid;

		initTool();
		levelRender = new render.LevelRender();

		updateLayerList();
	}

	function initTool() {
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
		curTool.startUsing( getMouse(), e.button );
	}
	function onMouseUp() {
		if( curTool.isRunning() )
			curTool.stopUsing( getMouse() );
	}
	function onMouseMove(e:hxd.Event) {
		curTool.onMouseMove( getMouse() );
	}

	public function selectLayer(l:LayerContent) {
		curLayerId = l.def.uid;
		levelRender.onCurrentLayerChange(curLayerContent);
		curTool.updatePalette();
		updateLayerList();
	}

	public function onLayerDefChange() {
		project.checkDataIntegrity();
		if( curLayerContent==null )
			selectLayer(curLevel.layerContents[0]);
		levelRender.invalidate();
		initTool();
		updateLayerList();
	}

	public function updateLayerList() {
		var list = jLayers.find("ul");
		list.empty();

		for(layer in curLevel.layerContents) {
			var e = new J("<li/>");
			list.append(e);

			if( layer==curLayerContent )
				e.addClass("active");

			if( !levelRender.isLayerVisible(layer) )
				e.addClass("hidden");

			var vis = new J('<span class="vis"/>');
			e.append(vis);
			vis.click( function(_) {
				levelRender.toggleLayer(layer);
				updateLayerList();
			});

			var name = new J('<span class="name">'+layer.def.name+'</span>');
			e.append(name);
			name.click( function(_) {
				selectLayer(layer);
			});

		}
	}


	public inline function getMouse() : MouseCoords {
		return new MouseCoords(Boot.ME.s2d.mouseX, Boot.ME.s2d.mouseY);
	}

	override function onDispose() {
		super.onDispose();

		if( ME==this )
			ME = null;

		Boot.ME.s2d.removeEventListener(onEvent);
	}
}
