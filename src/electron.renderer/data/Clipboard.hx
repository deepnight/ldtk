package data;

class Clipboard {
	public var data : Null<Dynamic>;
	var type : Null<ClipboardType>;

	public function new() {
		clear();
	}

	@:keep
	public function toString() return "Clipboard("+getName()+")";

	public function set(type:ClipboardType, data:Dynamic) {
		this.type = type;
		this.data = data;
		N.msg("Copied: "+getName());
	}

	public function clear() {
		data = null;
		type = null;
	}


	public function getName() : String {
		if( isEmpty() )
			return L.t._("Empty");

		return switch type {
			case CLayerDef:
				var json : ldtk.Json.LayerDefJson = cast data;
				return 'Layer definition "${json.identifier}"';
		}
	}

	public function require(t:ClipboardType) : Bool{
		if( isEmpty() || !is(t) ) {
			N.error("Cannot paste "+getName()+" here");
			return false;
		}
		else
			return true;
	}

	public inline function isEmpty() return type==null;
	public inline function is(t:ClipboardType) return type!=null && t!=null && type.getIndex()==t.getIndex();
}