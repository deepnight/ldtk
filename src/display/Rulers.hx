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

	// Render
	var invalidated = true;
	var g : h2d.Graphics;
	var labels : h2d.Object;

	// Drag & drop
	var draggables : Array<RulerPos>;
	var draggedPos : Null<RulerPos>;
	var dragOrigin : Null<MouseCoords>;
	var dragStarted = false;
	var resizePreview : h2d.Graphics;

	public function new() {
		super(client);
		createRootInLayers(client.root, Const.DP_UI);
		client.ge.addGlobalListener(onGlobalEvent);

		draggables = RulerPos.createAll();

		g = new h2d.Graphics(root);
		labels = new h2d.Object(root);
		resizePreview = new h2d.Graphics(root);
	}

	override function onDispose() {
		super.onDispose();
		client.ge.removeListener(onGlobalEvent);
	}

	function onGlobalEvent(e:GlobalEvent) {
		switch e {
			case ProjectSelected, LevelSelected, LayerInstanceSelected, ProjectSettingsChanged:
				invalidate();

			case LayerDefChanged, LayerDefRemoved, LevelResized, LevelRestoredFromHistory:
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
		var a = 0.3;
		g.lineStyle(2, c, a);

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

		// Horizontal labels
		var xLabel = curLayerInstance==null ? curLevel.pxWid+"px" : curLayerInstance.cWid+" cells / "+curLevel.pxWid+"px";
		addLabel(xLabel, Top);
		addLabel(xLabel, Bottom);

		// Vertical labels
		var yLabel = curLayerInstance==null ? curLevel.pxHei+"px" : curLayerInstance.cHei+" cells / "+curLevel.pxHei+"px";
		addLabel(yLabel, Left);
		addLabel(yLabel, Right);


		// Corners
		if( curLayerInstance!=null ) {
			g.lineStyle(0);
			g.beginFill(c, a);
			var size = 8;
			for(p in draggables)
				g.drawRect( getX(p)-size*0.5, getY(p)-size*0.5, size, size );
		}
	}

	function addLabel(str:String, pos:RulerPos) {
		var wrapper = new h2d.Object(labels);
		wrapper.x = getX(pos, PADDING*2);
		wrapper.y = getY(pos, PADDING*2);
		switch pos {
			case Left, Right: wrapper.rotate(-M.PIHALF);
			case _:
		}

		var tf = new h2d.Text(Assets.fontPixel, wrapper);
		tf.alpha = 0.5;
		tf.text = str;
		tf.scale(2);
		tf.x = Std.int( -tf.textWidth*0.5*tf.scaleX );
		tf.y = Std.int( -tf.textHeight*0.5*tf.scaleY );
	}


	inline function isOver(x:Int, y:Int, pos:RulerPos) {
		return M.dist( x,y, getX(pos), getY(pos) ) <= PADDING;
	}


	function getX(pos:RulerPos, ?padding:Float) : Int {
		if( padding==null )
			padding = PADDING;

		return Std.int( switch pos {
			case Top, Bottom : curLevel.pxWid*0.5;
			case Left, TopLeft, BottomLeft : -padding;
			case Right, TopRight, BottomRight : curLevel.pxWid + padding;
		} );
	}

	function getY(pos:RulerPos, ?padding:Float) : Int {
		if( padding==null )
			padding = PADDING;

		return Std.int( switch pos {
			case Top, TopLeft, TopRight : -padding;
			case Bottom, BottomLeft, BottomRight : curLevel.pxHei + padding;
			case Left, Right : curLevel.pxHei*0.5;
		} );
	}

	inline function isClicking() return dragOrigin!=null;

	public function onMouseDown(m:MouseCoords, buttonId:Int) {
		resizePreview.clear();
		dragOrigin = null;
		dragStarted = false;
		draggedPos = null;

		if( buttonId!=0 || !canUseResizers() )
			return;

		dragOrigin = m;

		for( p in draggables )
			if( isOver(m.levelX, m.levelY, p) )
				draggedPos = p;

		if( draggedPos!=null )
			client.curTool.stopUsing(m);
	}

	function canUseResizers() {
		return curLayerInstance!=null
			&& !client.isKeyDown(K.SPACE) && !client.isShiftDown() && !client.isCtrlDown() && !client.isAltDown();
	}

	public function onMouseMove(m:MouseCoords) {
		if( curLayerInstance==null)
			return;

		// Cursor
		if( canUseResizers() )
			for( p in draggables )
				if( !isClicking() && isOver(m.levelX, m.levelY, p) || draggedPos==p )
					client.cursor.set( Resize(p) );

		// Drag only starts after a short threshold
		if( isClicking() && draggedPos!=null && !dragStarted && M.dist(m.gx, m.gy, dragOrigin.gx, dragOrigin.gy)>=4 )
			dragStarted = true;

		// Preview resizing
		if( dragStarted ) {
			resizePreview.clear();
			resizePreview.lineStyle(4, 0xffcc00);
			var b = getResizedBounds(m);
			resizePreview.drawRect(b.newLeft, b.newTop, b.newRight-b.newLeft, b.newBottom-b.newTop);
		}
	}

	function getResizedBounds(m:MouseCoords) {
		if( draggedPos==null )
			return null;

		var grid = curLayerInstance.def.gridSize;
		return {
			newLeft :
				switch draggedPos {
					case Left, TopLeft, BottomLeft : M.floor( ( m.levelX - dragOrigin.levelX ) / grid ) * grid;
					case _: 0;
				},

			newTop :
				switch draggedPos {
					case Top, TopLeft, TopRight: M.floor( ( m.levelY - dragOrigin.levelY ) / grid ) * grid;
					case _: 0;
				},

			newRight :
				switch draggedPos {
					case Right, TopRight, BottomRight: curLevel.pxWid + M.floor( ( m.levelX - dragOrigin.levelX ) / grid ) * grid;
					case _: curLevel.pxWid;
				},
			newBottom :
				switch draggedPos {
					case Bottom, BottomLeft, BottomRight: curLevel.pxHei + M.floor( ( m.levelY - dragOrigin.levelY ) / grid ) * grid;
					case _: curLevel.pxHei;
				},

		}
	}

	public function onMouseUp(m:MouseCoords) {
		if( dragStarted ) {
			var b = getResizedBounds(m);
			if( b.newLeft!=0 || b.newTop!=0 || b.newRight!=curLevel.pxWid || b.newBottom!=curLevel.pxHei ) {
				var before = curLevel.toJson();
				curLevel.applyNewBounds(b.newLeft, b.newTop, b.newRight-b.newLeft, b.newBottom-b.newTop);
				client.ge.emit(LevelResized);
				client.curLevelHistory.saveResizedState( before, curLevel.toJson() );
			}
		}

		dragOrigin = null;
		draggedPos = null;
		dragStarted = false;
		resizePreview.clear();
	}

	override function postUpdate() {
		super.postUpdate();

		if( invalidated )
			render();
	}
}