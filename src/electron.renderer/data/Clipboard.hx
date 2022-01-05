package data;

class Clipboard {
	public var data : Null<Dynamic>;
	var type : Null<ClipboardType>;

	public function new() {
		clear();
	}

	@:keep
	public function toString() return "Clipboard("+getName()+")";

	public static function create(type:ClipboardType, data:Dynamic) : Clipboard {
		var c = new Clipboard();
		c.copy(type, data);
		return c;
	}

	public function copy(type:ClipboardType, data:Dynamic) {
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
			case CRule:
				var json : data.def.AutoLayerRuleDef = cast data;
				return 'Rule "${json.uid}"';

			case CRuleGroup:
				var json : data.DataTypes.AutoLayerRuleGroup = cast data;
				return 'Rule group "${json.name}"';

			case CLayerDef:
				var json : ldtk.Json.LayerDefJson = cast data;
				return 'Layer definition "${json.identifier}"';

			case CEntityDef:
				var json : ldtk.Json.EntityDefJson = cast data;
				return 'Entity definition "${json.identifier}"';

			case CEnumDef:
				var json : ldtk.Json.EnumDefJson = cast data;
				return 'Enum definition "${json.identifier}"';

			case CTilesetDef:
				var json : ldtk.Json.TilesetDefJson = cast data;
				return 'Tileset definition "${json.identifier}"';

			case CFieldDef:
				var json : ldtk.Json.FieldDefJson = cast data;
				return 'Field definition "${json.identifier}"';
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