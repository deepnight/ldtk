package js.jquery;

class JqIterator {
	var j:JQuery;
	var i:Int;
	inline public function new(j:JQuery):Void {
		this.i = 0;
		this.j = j;
	}
	inline public function hasNext():Bool {
		return i < j.length;
	}
	inline public function next():js.html.Element {
		return this.j[i++];
	}

	static function __init__() {
		var JQueryDefined = #if (haxe_ver >= 4)
			js.Syntax.typeof(JQuery) != "undefined";
		#else 
			untyped __typeof__(JQuery) != "undefined";
		#end
		if (JQueryDefined && JQuery.fn != null)
			JQuery.fn.iterator = function() return new JqIterator(js.Lib.nativeThis);
	}
}
