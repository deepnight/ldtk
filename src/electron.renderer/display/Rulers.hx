package display;

class Rulers extends dn.Process {
	public static var PADDING = 4;
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

	// Drag & drop
	var draggables : Array<RectHandlePos>;
	var draggedPos : Null<RectHandlePos>;
	var dragOrigin : Null<Coords>;
	var dragStarted = false;
	var resizePreview : h2d.Graphics;
	var oldNeighbours : Null< Array<String> >;

	public function new() {
		super(editor);

		createRootInLayers(editor.root, Const.DP_MAIN);
		editor.ge.addGlobalListener(onGlobalEvent);

		draggables = RectHandlePos.createAll();

		g = new h2d.Graphics(root);
		labels = new h2d.Object(root);
		resizePreview = new h2d.Graphics(root);
	}

	@:keep
	override function toString():String {
		return super.toString()
			+ "[" + ( draggedPos==null ? "--" : draggedPos.getName() ) + "]"
			+ ( dragStarted ? " (RESIZING)" : "" );
	}

	override function onDispose() {
		super.onDispose();
		editor.ge.removeListener(onGlobalEvent);
	}

	function onGlobalEvent(e:GlobalEvent) {
		switch e {
			case ProjectSelected, LayerInstanceSelected(_), ProjectSettingsChanged:
				invalidate();

			case FieldDefChanged(_), FieldDefRemoved(_):
				invalidate();

			case LayerDefChanged(_), LayerDefRemoved(_), LevelResized(_), LevelRestoredFromHistory(_):
				invalidate();

			case LevelSettingsChanged(_):
				invalidate();

			case LevelSelected(l):
				invalidate();

			case ViewportChanged(_), WorldLevelMoved(_):
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

		var c = C.getPerceivedLuminosityInt(editor.project.bgColor)>=0.7 ? 0x0 : 0xffffff;
		g.lineStyle(2, c);

		// Horizontal labels
		var xLabel = curLayerInstance==null ? curLevel.pxWid+"px" : curLayerInstance.cWid+" cells / "+curLevel.pxWid+"px";
		if( !editor.curLevel.hasAnyFieldDisplayedAt(Beneath) )
			addLabel(xLabel, Bottom, 16);

		// Vertical labels
		var yLabel = curLayerInstance==null ? curLevel.pxHei+"px" : curLayerInstance.cHei+" cells / "+curLevel.pxHei+"px";
		addLabel(yLabel, Left, 16);
		addLabel(yLabel, Right, 16);

		// Resizing drags
		g.lineStyle(0);
		g.beginFill(c);
		for(p in draggables)
			g.drawCircle( getX(p), getY(p), HANDLE_SIZE*0.5, 24);
	}


	function addLabel(str:String, pos:RectHandlePos, smallFont=true, distancePx=0, ?color:UInt) {
		var scale : Float = switch pos {
			case Top, Bottom: editor.curLevel.pxWid<200 ? 0.5 : 1;
			case Left, Right: editor.curLevel.pxHei<200 ? 0.5 : 1;
			case _: 1;
		}

		var wrapper = new h2d.Object(labels);
		wrapper.x = getX(pos, distancePx);
		wrapper.y = getY(pos, distancePx);
		switch pos {
			case Left, Right: wrapper.rotate(-M.PIHALF);
			case _:
		}

		if( color==null )
			color = C.toWhite(editor.project.bgColor,0.5);

		var tf = new h2d.Text(Assets.getRegularFont(), wrapper);
		tf.text = str;
		tf.textColor = color;
		tf.scale(scale);
		tf.x = Std.int( -tf.textWidth*0.5*tf.scaleX );
		tf.y = Std.int( -tf.textHeight*0.5*tf.scaleY );
	}


	inline function isOver(levelX:Int, levelY:Int, pos:RectHandlePos) {
		if( !editor.worldMode && editor.curLevel.inBounds(levelX,levelY) )
			return false;
		else
			return M.dist( levelX, levelY, getX(pos), getY(pos) ) <= HANDLE_SIZE*1.5;
	}


	function getX(pos:RectHandlePos, extraDistancePx=0) : Int {
		extraDistancePx += PADDING;
		return Std.int( switch pos {
			case Top, Bottom : curLevel.pxWid*0.5;
			case Left, TopLeft, BottomLeft : -extraDistancePx;
			case Right, TopRight, BottomRight : curLevel.pxWid + extraDistancePx;
		} );
	}

	function getY(pos:RectHandlePos, extraDistancePx=0) : Int {
		extraDistancePx += PADDING;
		return Std.int( switch pos {
			case Top, TopLeft, TopRight : -extraDistancePx;
			case Bottom, BottomLeft, BottomRight : curLevel.pxHei + extraDistancePx;
			case Left, Right : curLevel.pxHei*0.5;
		} );
	}

	inline function isClicking() return dragOrigin!=null;

	public function onMouseDown(ev:hxd.Event, m:Coords) {
		resizePreview.clear();
		dragOrigin = null;
		dragStarted = false;
		draggedPos = null;
		oldNeighbours = null;

		if( ev.button!=0 || !canUseResizers() )
			return;

		dragOrigin = m;

		for( p in draggables )
			if( isOver(m.levelX, m.levelY, p) )
				draggedPos = p;

		if( draggedPos!=null ) {
			ev.cancel = true;
			oldNeighbours = curLevel.getNeighboursIids();
		}
	}

	function canUseResizers() {
		return !App.ME.isKeyDown(K.SPACE) && !App.ME.hasAnyToggleKeyDown() && editor.curWorldDepth==editor.curLevel.worldDepth;
	}

	public function onMouseMoveCursor(ev:hxd.Event, m:Coords) {
		if( ev.cancel ) {
			g.alpha = 0.3;
			return;
		}

		// Handles cursors
		if( canUseResizers() )
			for( p in draggables )
				if( !isClicking() && isOver(m.levelX, m.levelY, p) || draggedPos==p ) {
					ev.cancel = true;
					if( !dragStarted )
						editor.cursor.set( Resize(p), L.t._("Resize level") );
					g.alpha = 1;
				}

		// No handle is overed
		if( !ev.cancel )
			g.alpha = 0.3;
	}

	public function onMouseMove(ev:hxd.Event, m:Coords) {
		if( ev.cancel )
			return;

		// Drag only starts after a short threshold
		if( isClicking() && draggedPos!=null && !dragStarted && m.getPageDist(dragOrigin)>=4 )
			dragStarted = true;

		// Preview resizing
		if( dragStarted ) {
			resizePreview.clear();
			var b = getResizedBounds(m);
			resizePreview.lineStyle(4, !resizeBoundsValid(b) ? 0xff0000 : 0xffcc00);
			resizePreview.drawRect(b.newLeft, b.newTop, b.newRight-b.newLeft, b.newBottom-b.newTop);
			editor.cursor.set( Moving, (b.newRight-b.newLeft)+"x"+(b.newBottom-b.newTop)+"px" );
			App.ME.requestCpu();
			ev.cancel = true;
		}
	}

	inline function getResizeGrid() {
		return curLayerInstance==null ? Editor.ME.project.defaultGridSize : curLayerInstance.def.gridSize;
	}

	function resizeBoundsValid(b) {
		var min = getResizeGrid();
		return b.newRight>=b.newLeft+min && b.newBottom>=b.newTop+min;
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

		if( editor.curWorld.worldLayout==GridVania) {
			// Snap to world grid
			var w = editor.curWorld;
			b.newLeft = dn.M.round( b.newLeft/w.worldGridWidth ) * w.worldGridWidth;
			b.newRight = dn.M.round( b.newRight/w.worldGridWidth ) * w.worldGridWidth;
			b.newTop = dn.M.round( b.newTop/w.worldGridHeight ) * w.worldGridHeight;
			b.newBottom = dn.M.round( b.newBottom/w.worldGridHeight ) * w.worldGridHeight;
		}
		return b;
	}

	public function onMouseUp(m:Coords) {
		if( dragStarted ) {
			var b = getResizedBounds(m);
			if( b.newLeft!=0 || b.newTop!=0 || b.newRight!=curLevel.pxWid || b.newBottom!=curLevel.pxHei ) {
				if( resizeBoundsValid(b) ) {
					var before = curLevel.toJson();
					var initialX = curLevel.worldX;
					var initialY = curLevel.worldY;
					curLevel.worldX += b.newLeft;
					curLevel.worldY += b.newTop;
					curLevel.applyNewBounds(b.newLeft, b.newTop, b.newRight-b.newLeft, b.newBottom-b.newTop);
					editor.selectionTool.clear();
					editor.ge.emit( LevelResized(curLevel) );
					editor.curLevelTimeline.saveFullLevelState();
					editor.ge.emit( WorldLevelMoved(curLevel, true, oldNeighbours) );
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

		labels.visible = !editor.worldMode && App.ME.settings.v.showDetails && !editor.gifMode;
		g.visible = canUseResizers();
	}
}