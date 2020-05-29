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
	var levelRender : render.LevelRender;

	public function new() {
		super();

		ME = this;
		createRoot(Boot.ME.s2d);

		win.title = "LEd v"+Const.APP_VERSION;

		project = new data.ProjectData();
		project.createLayerDef(IntGrid,"First layer");
		project.createLayerDef(IntGrid,"Other");
		project.createLayerDef(IntGrid,"Last one");
		curLevel = project.createLevel();
		curLayer = curLevel.layers[0];
		curLayer.setIntGrid(0,0, 1);
		curLayer.setIntGrid(2,4, 0);
		curLayer.setIntGrid(5,5, 0);
		curLayer.setIntGrid(6,6, 0);

		levelRender = new render.LevelRender(curLevel);

		updateLayerList();
	}

	function updateLayerList() {
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
				curLayer = layer;
				updateLayerList();
			});

		}
	}

	override function onDispose() {
		super.onDispose();
		if( ME==this )
			ME = null;
	}
}
