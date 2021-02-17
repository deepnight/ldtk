package tool;

typedef ResizeRect = {
	var x: Int;
	var y: Int;
	var w: Int;
	var h: Int;
}

class ResizeTool extends Tool<Int> {
	static var DEFAULT_ALPHA = 0.75;

	var handleDist = 4;
	var draggedHandle: Null<RectHandlePos>;
	var g : h2d.Graphics;
	var ge: GenericLevelElement;
	var _handlePosIterator : Array<RectHandlePos>;

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
		var c = 0xff00ff;
		g.beginFill(c,1);
		for(e in _handlePosIterator)
			g.drawCircle(getHandleX(e), getHandleY(e), handleDist);

	}

	inline function get_rect() {
		if( _rect==null )
			_rect = switch ge {
				case GridCell(li, cx, cy):
					{ x:cx*li.def.gridSize, y:cy*li.def.gridSize, w:li.def.gridSize, h:li.def.gridSize }

				case Entity(li, ei):
					{ x:ei.left, y:ei.top, w:ei.def.width, h:ei.def.height }

				case PointField(li, ei, fi, arrayIdx):
					var pt = fi.getPointGrid(arrayIdx);
					{ x:pt.cx*li.def.gridSize, y:pt.cy*li.def.gridSize, w:li.def.gridSize, h:li.def.gridSize }
			}
		return _rect;
	}

	function getOveredHandle(m:Coords) : Null<RectHandlePos> {
		for(p in _handlePosIterator)
			if( M.dist(m.levelX, m.levelY, getHandleX(p), getHandleY(p) )<=5 )
				return p;
		return null;
	}

	function getHandleX(pos:RectHandlePos) : Float {
		return switch pos {
			case Top, Bottom: rect.x + rect.w*0.5;
			case Left, TopLeft, BottomLeft: rect.x - handleDist;
			case Right, TopRight, BottomRight: rect.x + rect.w-1 + handleDist;
		}
	}

	function getHandleY(pos:RectHandlePos) : Float {
		return switch pos {
			case Left,Right: rect.y + rect.h*0.5;
			case Top, TopLeft, TopRight: rect.y - handleDist;
			case Bottom, BottomLeft, BottomRight: rect.y + rect.h + handleDist;
		}
	}

	override function isRunning():Bool {
		return false;
	}

	override function startUsing(ev:hxd.Event, m:Coords) {
		super.startUsing(ev,m);
		curMode = null;
	}

	override function onMouseMove(ev:hxd.Event, m:Coords) {
		super.onMouseMove(ev, m);

		var p = getOveredHandle(m);
		if( p!=null ) {
			g.alpha = 1;
			ev.cancel = true;
			editor.cursor.set( Resize(p) );
		}
		else
			g.alpha = DEFAULT_ALPHA;
	}

	override function postUpdate() {
		super.postUpdate();
		render();
		// root.x = editor.levelRender.root.x;
		// root.y = editor.levelRender.root.y;
		// root.setScale( editor.levelRender.root.scaleX );
	}

}