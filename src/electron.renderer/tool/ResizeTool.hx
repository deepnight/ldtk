package tool;

typedef ResizeRect = {
	var x: Int;
	var y: Int;
	var w: Int;
	var h: Int;
}

class ResizeTool extends Tool<Int> {
	static var DEFAULT_ALPHA = 0.75;
	static var HANDLE_RADIUS = 5;

	var draggedHandle: Null<RectHandlePos>;
	var dragOrigin : Coords;
	var g : h2d.Graphics;
	var ge: GenericLevelElement;
	var _handlePosIterator : Array<RectHandlePos>;

	var invalidated = true;
	var _rect : Null<ResizeRect>;
	var rect(get,never) : ResizeRect;


	public function new(ge:GenericLevelElement) {
		super();
		this.ge = ge;
		createRootInLayers(editor.levelRender.root, Const.DP_UI);
		g = new h2d.Graphics(root);
		g.alpha = DEFAULT_ALPHA;

		_handlePosIterator = RectHandlePos.getConstructors().map( k->RectHandlePos.createByName(k) );
		render();
	}

	function render() {
		g.clear();

		// Draw handles
		var c = 0xffcc00;
		g.beginFill(c,1);
		for(p in _handlePosIterator) {
			if( isHandleActive(p) )
				g.drawCircle(getHandleX(p), getHandleY(p), HANDLE_RADIUS*0.6, 16);
		}
	}

	inline function get_rect() {
		if( _rect==null )
			_rect = switch ge {
				case GridCell(li, cx, cy):
					{ x:cx*li.def.gridSize, y:cy*li.def.gridSize, w:li.def.gridSize, h:li.def.gridSize }

				case Entity(li, ei):
					{ x:ei.left, y:ei.top, w:ei.width, h:ei.height }

				case PointField(li, ei, fi, arrayIdx):
					var pt = fi.getPointGrid(arrayIdx);
					{ x:pt.cx*li.def.gridSize, y:pt.cy*li.def.gridSize, w:li.def.gridSize, h:li.def.gridSize }
			}
		return _rect;
	}

	function isHandleActive(p:RectHandlePos) {
		return switch p {
			case Top, Bottom: rect.w > HANDLE_RADIUS*2;
			case Left, Right: rect.h > HANDLE_RADIUS*2;
			case TopLeft, TopRight, BottomLeft, BottomRight: true;
		}
	}

	function getOveredHandle(m:Coords) : Null<RectHandlePos> {
		for(p in _handlePosIterator)
			if( isHandleActive(p) && M.dist(m.levelX, m.levelY, getHandleX(p), getHandleY(p) ) <= HANDLE_RADIUS )
				return p;
		return null;
	}

	function getHandleX(pos:RectHandlePos) : Float {
		return switch pos {
			case Top, Bottom: rect.x + rect.w*0.5;
			case Left, TopLeft, BottomLeft: rect.x - HANDLE_RADIUS;
			case Right, TopRight, BottomRight: rect.x + rect.w-1 + HANDLE_RADIUS;
		}
	}

	function getHandleY(pos:RectHandlePos) : Float {
		return switch pos {
			case Left,Right: rect.y + rect.h*0.5;
			case Top, TopLeft, TopRight: rect.y - HANDLE_RADIUS;
			case Bottom, BottomLeft, BottomRight: rect.y + rect.h + HANDLE_RADIUS;
		}
	}

	override function isRunning():Bool {
		return draggedHandle!=null;
	}

	override function startUsing(ev:hxd.Event, m:Coords) {
		super.startUsing(ev,m);
		curMode = null;

		draggedHandle = getOveredHandle(m);
		dragOrigin = m;

		ev.cancel = true;
	}

	override function stopUsing(m:Coords) {
		super.stopUsing(m);
		draggedHandle = null;
	}

	public function onMouseDown(ev:hxd.Event, m:Coords) {
		var p = getOveredHandle(m);
		if( p!=null )
			startUsing(ev, m);
	}

	override function onMouseMove(ev:hxd.Event, m:Coords) {
		super.onMouseMove(ev, m);

		if( !isRunning() ) {
			// Overing
			var p = getOveredHandle(m);
			if( p!=null ) {
				g.alpha = 1;
				ev.cancel = true;
				editor.cursor.set( Resize(p) );
			}
			else
				g.alpha = DEFAULT_ALPHA;
		}
		else {
			// Actual resizing
			ev.cancel = true;
			var deltaX = switch draggedHandle { // Width
				case Top, Bottom: 0;
				case Left, TopLeft, BottomLeft: dragOrigin.levelX - m.levelX;
				case Right, TopRight, BottomRight: m.levelX - dragOrigin.levelX;

			}
			var deltaY = switch draggedHandle { // Height
				case Left, Right: 0;
				case Top, TopLeft, TopRight: dragOrigin.levelY - m.levelY;
				case Bottom, BottomLeft, BottomRight: m.levelY - dragOrigin.levelY;

			}
			applyResize(deltaX, deltaY);
			dragOrigin = m;
		}
	}

	function applyResize(deltaX:Int, deltaY:Int) {
		switch ge {
			case GridCell(li, cx, cy):

			case Entity(li, ei):
				if( deltaX!=0 ) {
					// Width
					var old = ei.width;
					ei.customWidth = ei.width + deltaX;
					if( ei.customWidth<=ei.def.width )
						ei.customWidth = null;

					switch draggedHandle {
						case Left, TopLeft, BottomLeft: ei.x -= ei.width-old;
						case _:
					}
				}
				if( deltaY!=0 ) {
					// Height
					var old = ei.height;
					ei.customHeight= ei.height + deltaY;
					if( ei.customHeight<=ei.def.height )
						ei.customHeight = null;

					switch draggedHandle {
						case Top, TopLeft, TopRight: ei.y -= ei.height-old;
						case _:
					}
				}
				editor.ge.emit( EntityInstanceChanged(ei) );
				editor.selectionTool.invalidateRender();

			case PointField(li, ei, fi, arrayIdx):
		}

		invalidate();
	}

	public inline function invalidate() {
		invalidated = true;
	}

	override function postUpdate() {
		super.postUpdate();
		if( invalidated ) {
			_rect = null;
			render();
			invalidated = false;
		}
	}
}