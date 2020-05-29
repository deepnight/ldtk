package js.jquery;

class JqEltsIterator {
	var j:JQuery;
	var i:Int;
	inline public function new(j:JQuery):Void {
		this.i = 0;
		this.j = j;
	}
	inline public function hasNext():Bool {
		return i < j.length;
	}
	inline public function next():JQuery {
		return new JQuery(this.j[i++]);
	}

	static function __init__() {
		var JQueryDefined = #if (haxe_ver >= 4)
			js.Syntax.typeof(JQuery) != "undefined";
		#else 
			untyped __typeof__(JQuery) != "undefined";
		#end
		if (JQueryDefined && JQuery.fn != null) {
			JQuery.fn.elements = function() return new JqEltsIterator(js.Lib.nativeThis);
		}
	}
}