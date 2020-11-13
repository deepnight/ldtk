package misc;

class Rect {
	public var cx : Int;
	public var cy : Int;
	public var wid : Int;
	public var hei : Int;

	public var left(get,never) : Int; inline function get_left() return cx;
	public var right(get,never) : Int; inline function get_right() return cx+wid-1;
	public var top(get,never) : Int; inline function get_top() return cy;
	public var bottom(get,never) : Int; inline function get_bottom() return cy+hei-1;

	public function new(x,y,w,h) {
		cx = x;
		cy = y;
		wid = w;
		hei = h;
	}

	public static inline function fromCoords(a:Coords, b:Coords) : Rect {
		return new Rect(
			M.imin(a.cx, b.cx),
			M.imin(a.cy, b.cy),
			M.iabs(a.cx-b.cx)+1,
			M.iabs(a.cy-b.cy)+1
		);
	}

}