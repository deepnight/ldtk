package misc;

class WorldRect {
	public var x : Int;
	public var y : Int;
	public var wid : Int;
	public var hei : Int;

	public var left(get,never) : Int; inline function get_left() return x;
	public var right(get,never) : Int; inline function get_right() return x+wid-1;
	public var top(get,never) : Int; inline function get_top() return y;
	public var bottom(get,never) : Int; inline function get_bottom() return y+hei-1;

	public function new(x,y,w,h) {
		this.x = x;
		this.y = y;
		wid = w;
		hei = h;
	}

	@:keep
	public inline function toString() {
		return 'WorldRect($x,$y ${wid}x$hei)';
	}

	public inline function useLevel(l:data.Level) {
		x = l.worldX;
		y = l.worldY;
		wid = l.pxWid;
		hei = l.pxHei;
	}

	public static inline function fromLevel(l:data.Level) {
		return new WorldRect(l.worldX, l.worldY, l.pxWid, l.pxHei);
	}
}