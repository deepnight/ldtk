class Client extends dn.Process {
	public static var ME : Client;

	public var win(get,never) : nw.Window; inline function get_win() return nw.Window.get();
	public var jBody(get,never) : J; inline function get_jBody() return new J("body");
	public var jLayers(get,never) : J; inline function get_jLayers() return new J(".panel .layersList");
	// public var win(get,never) : js.html.Window; inline function get_win() return js.Browser.window;
	public var doc(get,never) : js.html.Document; inline function get_doc() return js.Browser.document;

	public var project : ProjectData;
	public var curLevel : LevelData;
	public var curLayer : LayerContent;
	public var levelRender : render.LevelRender;
	var curTool : Tool;

	public function new() {
		super();

		ME = this;
		createRoot(Boot.ME.s2d);
		win.title = "LEd v"+Const.APP_VERSION;
		win.maximize();

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
		project.createLayerDef(IntGrid,"First layer");
		project.createLayerDef(IntGrid,"Other");
		var l = project.createLayerDef(IntGrid,"Last one");
		l.gridSize = 8;
		curLevel = project.createLevel();
		curLayer = curLevel.layers[0];
		curLayer.setIntGrid(0,0, 1);
		curLayer.setIntGrid(2,4, 0);
		curLayer.setIntGrid(5,5, 1);
		curLayer.setIntGrid(6,6, 0);

		curTool = new tool.IntGridBrush();

		levelRender = new render.LevelRender(curLevel);

		updateLayerList();
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
		curTool.startUsing( getMouse() );
	}
	function onMouseUp() {
		if( curTool.isRunning() )
			curTool.stopUsing( getMouse() );
	}
	function onMouseMove(e:hxd.Event) {
		curTool.onMouseMove( getMouse() );
	}

	public function selectLayer(l:LayerContent) {
		curLayer = l;
		levelRender.onCurrentLayerChange(curLayer);
		updateLayerList();

	}

	public function updateLayerList() {
		var list = jLayers.find("ul");
		list.empty();

		for(layer in curLevel.layers) {
			var e = new J("<li/>");
			list.append(e);

			if( layer==curLayer )
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
