package display;

class Rulers extends dn.Process {
	static var PADDING = 16;

	var client(get,never) : Client; inline function get_client() return Client.ME;
	var levelRender(get,never) : LevelRender;
		inline function get_levelRender() return Client.ME.levelRender;

	var curLevel(get,never) : led.Level;
		inline function get_curLevel() return Client.ME.curLevel;

	var curLayerInstance(get,never) : Null<led.inst.LayerInstance>;
		inline function get_curLayerInstance() return Client.ME.curLayerInstance;

	var invalidated = true;
	var g : h2d.Graphics;
	var labels : h2d.Object;

	public function new() {
		super(client);
		createRootInLayers(client.root, Const.DP_UI);
		client.ge.addGlobalListener(onGlobalEvent);

		g = new h2d.Graphics(root);
		labels = new h2d.Object(root);
	}

	override function onDispose() {
		super.onDispose();
		client.ge.removeListener(onGlobalEvent);
	}

	function onGlobalEvent(e:GlobalEvent) {
		switch e {
			case ProjectSelected, LevelSelected, LayerInstanceSelected, ProjectSettingsChanged:
				invalidate();

			case LayerDefChanged, LayerDefRemoved:
				invalidate();

			case ViewportChanged:
				root.x = levelRender.root.x;
				root.y = levelRender.root.y;
				root.setScale( levelRender.root.scaleX );

			case _:
		}
	}

	public function invalidate() {
		invalidated = true;
	}

	function render() {
		invalidated = false;
		g.clear();
		labels.removeChildren();

		var c = C.getPerceivedLuminosityInt(client.project.bgColor)>=0.7 ? 0x0 : 0xffffff;
		g.lineStyle(2, c, 0.4);

		// Top
		g.moveTo(0, -PADDING);
		g.lineTo(curLevel.pxWid, -PADDING);

		// Bottom
		g.moveTo(0, curLevel.pxHei+PADDING);
		g.lineTo(curLevel.pxWid, curLevel.pxHei+PADDING);

		// Left
		g.moveTo(-PADDING, 0);
		g.lineTo(-PADDING, curLevel.pxHei);

		// Right
		g.moveTo(curLevel.pxWid+PADDING, 0);
		g.lineTo(curLevel.pxWid+PADDING, curLevel.pxHei);

		var xLabel = curLayerInstance==null ? curLevel.pxWid+"px" : curLayerInstance.cWid+" cells / "+curLevel.pxWid+"px";
		addLabel(xLabel, Top);
		addLabel(xLabel, Bottom);

		var yLabel = curLayerInstance==null ? curLevel.pxHei+"px" : curLayerInstance.cHei+" cells / "+curLevel.pxHei+"px";
		addLabel(yLabel, Left);
		addLabel(yLabel, Right);
	}

	function addLabel(str:String, pos:RulerPos) {
		var wrapper = new h2d.Object(labels);
		wrapper.x = getX(pos);
		wrapper.y = getY(pos);
		switch pos {
			case Left, Right: wrapper.rotate(-M.PIHALF);
			case Top, Bottom:
		}

		var tf = new h2d.Text(Assets.fontPixel, wrapper);
		tf.alpha = 0.5;
		tf.text = str;
		tf.scale(2);
		tf.x = Std.int( -tf.textWidth*0.5*tf.scaleX );
		tf.y = Std.int( -tf.textHeight*0.5*tf.scaleY );
	}

	function getX(pos:RulerPos) : Int {
		return Std.int( switch pos {
			case Top, Bottom: curLevel.pxWid*0.5;
			case Left: -PADDING*2;
			case Right: curLevel.pxWid + PADDING*2;
		} );
	}

	function getY(pos:RulerPos) : Int {
		return Std.int( switch pos {
			case Top: -PADDING*2;
			case Bottom: curLevel.pxHei + PADDING*2;
			case Left, Right: curLevel.pxHei*0.5;
		} );
	}


	public function onMouseDown(m:MouseCoords) {}
	public function onMouseMove(m:MouseCoords) {}
	public function onMouseUp(m:MouseCoords) {}

	override function postUpdate() {
		super.postUpdate();

		if( invalidated )
			render();
	}
}