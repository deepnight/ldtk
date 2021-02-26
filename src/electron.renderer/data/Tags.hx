package data;

class Tags {
	var map : Map<String,Bool>;

	public function new() {
		map = new Map();
	}

	@:keep
	public function toString() {
		return 'Tags(${count()}):[${toArray().join(",")}]';
	}

	public inline function count() {
		var n = 0;
		for(v in map)
			n++;
		return n;
	}
	public inline function isEmpty() return count()==0;

	@:allow(ui.TagEditor)
	inline function cleanUpTag(k:String) : Null<String> {
		k = Project.cleanupIdentifier(k,false);
		return k==null || k=="_" || k=="" ? null : k;
	}

	public inline function set(k:String, v=true) : String {
		k = cleanUpTag(k);
		if( k!=null )
			if( v )
				map.set(k,v);
			else
				map.remove(k);
		return k;
	}

	public inline function iterator() return map.keys();

	public inline function unset(k:String) : String {
		return set(k,false);
	}

	public inline function toggle(k) {
		if( has(k) )
			unset(k);
		else
			set(k);
	}

	public inline function has(k) {
		k = cleanUpTag(k);
		return k!=null && map.exists(k);
	}

	public function hasTagFoundIn(others:Tags) {
		for( k in map.keys() )
			if( others.has(k) )
				return true;
		return false;
	}

	public inline function clear() {
		map = new Map();
	}

	public function toArray() : Array<String> {
		var all = [];
		for(k in map.keys())
			all.push(k);
		return all;
	}

	public function fromArray(arr:Array<String>) {
		map = new Map();
		if( arr!=null )
			for( k in arr )
				set(k,true);
	}

	public function toJson() : Array<String> {
		return toArray();
	}

	public static function fromJson(json:Dynamic) : Tags {
		var o = new Tags();
		o.fromArray( JsonTools.readArray(json,[]) );
		return o;
	}


	public function tidy() {}
}