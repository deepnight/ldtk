class Client extends dn.Process {
	public static var ME : Client;

	public var win(get,never) : nw.Window; inline function get_win() return nw.Window.get();
	public var jBody(get,never) : J; inline function get_jBody() return new J("body");
	public var jLayers(get,never) : J; inline function get_jLayers() return new J(".layers");
	// public var win(get,never) : js.html.Window; inline function get_win() return js.Browser.window;
	public var doc(get,never) : js.html.Document; inline function get_doc() return js.Browser.document;

	public var project : ProjectData;
	public var curLevel : Null<LevelData>;
	public var curLayer : Null<LayerContent>;

	public function new() {
		super();

		ME = this;
		createRoot(Boot.ME.s2d);

		win.title = "LEd v"+Const.APP_VERSION;
		win.maximize();
		var e = new J('<div class="panel right"/>');
		jBody.prepend(e);
		e.append( new J('<input type="text"/>') );
		e.append( new J('<input type="text"/>') );
		e.append( new J('<input type="text"/>') );

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

		var lr = new render.LevelRender(curLevel);
		lr.render();

		updateLayerList();
	}

	function updateLayerList() {
		jLayers.empty();
		var list = new J("<ul/>");
		for(layer in curLevel.layers) {
			var e = new J("<li/>");
			if( layer==curLayer )
				e.addClass("active");
			e.append(layer.def.name+" ("+layer.def.type+")");
			e.click( function(_) {
				curLayer = layer;
				updateLayerList();
			});
			list.append(e);
		}
		jLayers.append(list);
	}

	override function onDispose() {
		super.onDispose();
		if( ME==this )
			ME = null;
	}
}
