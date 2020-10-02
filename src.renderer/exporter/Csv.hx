package exporter;

class Csv {
	var wid: Int;
	var hei: Int;
	var bytes: haxe.io.Bytes;

	public function new(w,h) {
		wid = w;
		hei = h;
		bytes = haxe.io.Bytes.alloc(wid*hei);
		bytes.fill(0, bytes.length, 0);
		trace('$wid x $hei => ${bytes.length}');
	}

	public inline function set(cx,cy, v:Int) {
		if( cx>=0 && cy>=0 )
			setCoordId(cx+cy*wid, v);
	}

	public inline function setCoordId(coordId, v:Int) {
		if( coordId<wid*hei )
			bytes.set(coordId, v);
	}

	public function getString() {
		var out = [];
		for(cy in 0...hei)
		for(cx in 0...wid)
			out.push( bytes.get(cx+cy*wid) );
		return out.join(",");
	}
}
