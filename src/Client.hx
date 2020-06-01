class Client extends dn.Process {
	public static var ME : Client;

	public var win(get,never) : nw.Window; inline function get_win() return nw.Window.get();
	public var jBody(get,never) : J; inline function get_jBody() return new J("body");
	public var jLayers(get,never) : J; inline function get_jLayers() return new J(".layers");
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

		new J(".projectSettings").click( function(_) {
			loadTemplateInWindow( hxd.Res.tpl.projectSettings );
		});

		new J(".editLayers").click( function(_) new ui.EditLayers() );

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
		curLayer.setIntGrid(5,5, 0);
		curLayer.setIntGrid(6,6, 0);

		curTool = new tool.IntGridBrush();

		levelRender = new render.LevelRender(curLevel);

		updateLayerList();
	}

	function onEvent(e:hxd.Event) {
		switch e.kind {
			case EPush: onMouseDown(e);
			case ERelease: onMouseUp(e);
			case EMove: onMouseMove(e);
			case EOver:
			case EOut: onMouseUp(e);
			case EWheel:
			case EFocus:
			case EFocusLost: onMouseUp(e);
			case EKeyDown:
			case EKeyUp:
			case EReleaseOutside: onMouseUp(e);
			case ETextInput:
			case ECheck:
		}
	}

	function onMouseDown(e:hxd.Event) {
		curTool.startUsing();
	}
	function onMouseUp(e:hxd.Event) {
		curTool.stopUsing();
	}
	function onMouseMove(e:hxd.Event) {
		if( curTool.isRunning() )
			curTool.use();
	}

	public function selectLayer(l:LayerContent) {
		curLayer = l;
		levelRender.renderGrid();
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


	public function loadTemplateInWindow(tpl:hxd.res.Resource) {
		var html = new J( tpl.entry.getText() );
		var win = new J(".window");
		win.show();
		win.find(".content").append(html);
	}

	public function getMouse() {
		var gx = Boot.ME.s2d.mouseX;
		var gy = Boot.ME.s2d.mouseY;

		var x = Std.int( ( gx/Const.SCALE - levelRender.root.x ) / levelRender.zoom );
		var y = Std.int( ( gy/Const.SCALE - levelRender.root.y ) / levelRender.zoom );

		return {
			gx : gx,
			gy : gy,
			x : x,
			y : y,
			cx : Std.int(x/curLayer.def.gridSize),
			cy : Std.int(y/curLayer.def.gridSize),
		}
	}

	override function onDispose() {
		super.onDispose();

		if( ME==this )
			ME = null;

		Boot.ME.s2d.removeEventListener(onEvent);
	}
}
