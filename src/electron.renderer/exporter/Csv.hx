package exporter;

class Csv {
	var wid: Int;
	var hei: Int;
	var bytes: haxe.io.Bytes;

	public inline function new(w:Int, h=1) {
		wid = w;
		hei = h;
		bytes = haxe.io.Bytes.alloc(wid*hei);
		bytes.fill(0, bytes.length, 0);
	}

	public inline function set(cx,cy, v:Int) {
		setAtCoordId( coordId(cx,cy), v );
	}

	public inline function setAtCoordId(coordId, v:Int) {
		if( coordId>=0 && coordId<wid*hei )
			bytes.set(coordId, v);
	}

	inline function coordId(cx,cy) {
		return cx+cy*wid;
	}

	inline function isValid(cx,cy) {
		return cx>=0 && cx<wid && cy>=0 && cy<hei;
	}

	public inline function get(cx,cy) : Int {
		return isValid(cx,cy) ? bytes.get(coordId(cx,cy)) : 0;
	}

	public inline function isNotZero(cx,cy) : Bool {
		return isValid(cx,cy) && bytes.get( coordId(cx,cy) )!=0;
	}

	public inline function getAtCoordId(coordId:Int) : UInt {
		return coordId>=0 && coordId<wid*hei ? bytes.get(coordId) : 0;
	}

	public function build1D() : Array<Int> {
		var out = [];
		for(cy in 0...hei)
		for(cx in 0...wid)
			out.push( bytes.get(cx+cy*wid) );
		return out;
	}

	public function build2D() : Array<Array<Int>> {
		var out = [];
		for(cy in 0...hei) {
			out.push([]);
			for(cx in 0...wid)
				out[cy].push( bytes.get(cx+cy*wid) );
		}
		return out;
	}

	public function toString2D() : String {
		var arr = build2D();
		var out = "";
		for(cy in 0...hei)
			out += arr[cy].join(",") + (cy<hei-1?",":"") + "\n";
		return out;
	}
}
