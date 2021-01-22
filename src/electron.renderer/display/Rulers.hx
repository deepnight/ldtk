package display;

class Rulers extends dn.Process {
	static var PADDING = 20;
	static var HANDLE_SIZE = 10;

	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	var levelRender(get,never) : LevelRender;
		inline function get_levelRender() return Editor.ME.levelRender;

	var curLevel(get,never) : data.Level;
		inline function get_curLevel() return Editor.ME.curLevel;

	var curLayerInstance(get,never) : Null<data.inst.LayerInstance>;
		inline function get_curLayerInstance() return Editor.ME.curLayerInstance;

	// Render
	var invalidated = true;
	var g : h2d.Graphics;
	var labels : h2d.Object;

	var tip : h2d.Flow;
	var tipTf : h2d.Text;

	// Drag & drop
	var draggables : Array<RulerPos>;
	var draggedPos : Null<RulerPos>;
	var dragOrigin : Null<Coords>;
	var dragStarted = false;
	var resizePreview : h2d.Graphics;

	public function new() {
		super(editor);

		createRootInLayers(editor.root, Const.DP_UI);
		editor.ge.addGlobalListener(onGlobalEvent);

		draggables = RulerPos.createAll();

		g = new h2d.Graphics(root);
		labels = new h2d.Object(root);
		resizePreview = new h2d.Graphics(root);

		tip = new h2d.Flow(root);
		tip.backgroundTile = Assets.elements.getTile("fieldBg");
		tip.borderWidth = tip.borderHeight = 3;
		tip.padding = 3;
		tipTf = new h2d.Text(Assets.fontPixel, tip);
		tipTf.textColor = 0x0;
		tip.visible = false;
	}

	override function toString():String {
		return Type.getClassName(Type.getClass(this))
			+ "[" + ( draggedPos==null ? "--" : draggedPos.getName() ) + "]"
			+ ( dragStarted ? " (RESIZING)" : "" );
	}

	function setTip(?p:RulerPos, ?str:String) {
		tip.visible = str!=null;
		if( tipTf.text!=str )
			tipTf.text = str;
		if( tip.visible ) {
			tip.x = Std.int( getX(p) - tip.outerWidth*tip.scaleX*0.5 );
			tip.y = Std.int( getY(p) - tip.outerHeight*tip.scaleY*0.5 );
		}
	}

	override function onDispose() {
		super.onDispose();
		editor.ge.removeListener(onGlobalEvent);
	}

	function onGlobalEvent(e:GlobalEvent) {
		switch e {
			case ProjectSelected, LayerInstanceSelected, ProjectSettingsChanged:
				invalidate();

			case LayerDefChanged, LayerDefRemoved(_), LevelResized(_), LevelRestoredFromHistory(_):
				invalidate();

			case LevelSettingsChanged(_):
				invalidate();

			case LevelSelected(l):
				invalidate();

			case ViewportChanged, WorldLevelMoved:
				root.x = levelRender.root.x;
				root.y = levelRender.root.y;
				root.setScale( levelRender.root.scaleX );
				tip.setScale( editor.camera.pixelRatio*2 * 1/editor.camera.adjustedZoom );

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

		var c = C.getPerceivedLuminosityInt(editor.project.bgColor)>=0.7 ? 0x0 : 0xffffff;
		g.lineStyle(2, c);

		// Top
		g.moveTo(0, -PADDING);
		g.lineTo(curLevel.pxWid*0.5-HANDLE_SIZE*1.5, -PADDING);
		g.moveTo(curLevel.pxWid*0.5+HANDLE_SIZE*1.5, -PADDING);
		g.lineTo(curLevel.pxWid, -PADDING);

		// Bottom
		g.moveTo(0, curLevel.pxHei+PADDING);
		g.lineTo(curLevel.pxWid*0.5-HANDLE_SIZE*1.5, curLevel.pxHei+PADDING);
		g.moveTo(curLevel.pxWid*0.5+HANDLE_SIZE*1.5, curLevel.pxHei+PADDING);
		g.lineTo(curLevel.pxWid, curLevel.pxHei+PADDING);

		// Left
		g.moveTo(-PADDING, 0);
		g.lineTo(-PADDING, curLevel.pxHei*0.5-HANDLE_SIZE*1.5);
		g.moveTo(-PADDING, curLevel.pxHei*0.5+HANDLE_SIZE*1.5);
		g.lineTo(-PADDING, curLevel.pxHei);

		// Right
		g.moveTo(curLevel.pxWid+PADDING, 0);
		g.lineTo(curLevel.pxWid+PADDING, curLevel.pxHei*0.5-HANDLE_SIZE*1.5);
		g.moveTo(curLevel.pxWid+PADDING, curLevel.pxHei*0.5+HANDLE_SIZE*1.5);
		g.lineTo(curLevel.pxWid+PADDING, curLevel.pxHei);

		// Horizontal labels
		var xLabel = curLayerInstance==null ? curLevel.pxWid+"px" : curLayerInstance.cWid+" cells / "+curLevel.pxWid+"px";
		addLabel(xLabel, Top);
		addLabel(xLabel, Bottom);

		// Vertical labels
		var yLabel = curLayerInstance==null ? curLevel.pxHei+"px" : curLayerInstance.cHei+" cells / "+curLevel.pxHei+"px";
		addLabel(yLabel, Left);
		addLabel(yLabel, Right);

		addLabel(editor.curLevel.identifier, Top, false, PADDING+8, 0xffcc00);


		// Resizing drags
		g.lineStyle(0);
		g.beginFill(c);
		for(p in draggables)
			g.drawCircle( getX(p), getY(p), HANDLE_SIZE*0.5);
	}


	function addLabel(str:String, pos:RulerPos, smallFont=true, extraPadding=0, ?color:UInt) {
		var scale : Float = switch pos {
			case Top, Bottom: editor.curLevel.pxWid<400 ? 0.5 : 1;
			case Left, Right: editor.curLevel.pxHei<300 ? 0.5 : 1;
			case _: 1;
		}

		var wrapper = new h2d.Object(labels);
		wrapper.x = getX(pos, PADDING*2 + extraPadding*scale);
		wrapper.y = getY(pos, PADDING*2 + extraPadding*scale);
		switch pos {
			case Left, Right: wrapper.rotate(-M.PIHALF);
			case _:
		}

		if( color==null )
			color = C.toWhite(editor.project.bgColor,0.5);

		var tf = new h2d.Text(smallFont ? Assets.fontLight_tiny : Assets.fontLight_small, wrapper);
		tf.text = str;
		tf.textColor = color;
		tf.scale(scale);
		tf.x = Std.int( -tf.textWidth*0.5*tf.scaleX );
		tf.y = Std.int( -tf.textHeight*0.5*tf.scaleY );
	}


	inline function isOver(x:Int, y:Int, pos:RulerPos) {
		return M.dist( x,y, getX(pos), getY(pos) ) <= HANDLE_SIZE*1.5;
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

	public function onMouseDown(ev:hxd.Event, m:Coords) {
		resizePreview.clear();
		dragOrigin = null;
		dragStarted = false;
		draggedPos = null;

		if( ev.button!=0 || !canUseResizers() )
			return;

		dragOrigin = m;

		for( p in draggables )
			if( isOver(m.levelX, m.levelY, p) )
				draggedPos = p;

		if( draggedPos!=null ) {
			ev.cancel = true;
			// editor.curTool.stopUsing(m);
		}
	}

	function canUseResizers() {
		return !App.ME.isKeyDown(K.SPACE) && !App.ME.hasAnyToggleKeyDown();
	}

	public function onMouseMove(ev:hxd.Event, m:Coords) {
		if( ev.cancel )
			return;

		// Cursor
		if( canUseResizers() )
			for( p in draggables )
				if( !isClicking() && isOver(m.levelX, m.levelY, p) || draggedPos==p ) {
					ev.cancel = true;
					editor.cursor.set( Resize(p) );
					g.alpha = 1;
				}
		if( !ev.cancel )
			g.alpha = 0.3;

		// Drag only starts after a short threshold
		if( isClicking() && draggedPos!=null && !dragStarted && m.getPageDist(dragOrigin)>=4 )
			dragStarted = true;

		// Preview resizing
		if( dragStarted ) {
			resizePreview.clear();
			var b = getResizedBounds(m);
			resizePreview.lineStyle(4, !resizeBoundsValid(b) ? 0xff0000 : 0xffcc00);
			resizePreview.drawRect(b.newLeft, b.newTop, b.newRight-b.newLeft, b.newBottom-b.newTop);
			setTip(draggedPos, (b.newRight-b.newLeft)+"x"+(b.newBottom-b.newTop)+"px");
		}
	}

	inline function getResizeGrid() {
		return curLayerInstance==null ? Editor.ME.project.defaultGridSize : curLayerInstance.def.gridSize;
	}

	function resizeBoundsValid(b) {
		var min = getResizeGrid() * 2;
		return b.newRight>b.newLeft+min && b.newBottom>b.newTop+min;
	}

	function getResizedBounds(m:Coords) {
		if( draggedPos==null )
			return null;

		var grid = getResizeGrid();
		var b = {
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

		if( editor.project.worldLayout==GridVania) {
			// Snap to world grid
			var p = editor.project;
			b.newLeft = dn.M.round( b.newLeft/p.worldGridWidth ) * p.worldGridWidth;
			b.newRight = dn.M.round( b.newRight/p.worldGridWidth ) * p.worldGridWidth;
			b.newTop = dn.M.round( b.newTop/p.worldGridHeight ) * p.worldGridHeight;
			b.newBottom = dn.M.round( b.newBottom/p.worldGridHeight ) * p.worldGridHeight;
		}
		return b;
	}

	public function onMouseUp(m:Coords) {
		setTip();
		if( dragStarted ) {
			var b = getResizedBounds(m);
			if( b.newLeft!=0 || b.newTop!=0 || b.newRight!=curLevel.pxWid || b.newBottom!=curLevel.pxHei ) {
				if( resizeBoundsValid(b) ) {
					var before = curLevel.toJson();
					curLevel.worldX += b.newLeft;
					curLevel.worldY += b.newTop;
					curLevel.applyNewBounds(b.newLeft, b.newTop, b.newRight-b.newLeft, b.newBottom-b.newTop);
					editor.selectionTool.clear();
					editor.ge.emit( LevelResized(curLevel) );
					editor.curLevelHistory.saveResizedState( before, curLevel.toJson() );
					editor.ge.emit( WorldLevelMoved );
				}
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

		labels.visible = !editor.worldMode;
	}
}