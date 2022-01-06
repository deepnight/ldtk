package data;

class Clipboard {
	public var json : Null<Dynamic>;
	var type : Null<ClipboardType>;

	public function new() {
		clear();
		readSystemClipboard();
	}

	@:keep
	public function toString() return "Clipboard("+getName()+")";

	public static function create(type:ClipboardType, json:Dynamic) : Clipboard {
		var c = new Clipboard();
		c.copy(type, json);
		return c;
	}

	public function readSystemClipboard() {
		trace("read sys clipboard: ");
		trace(electron.Clipboard.readText());
	}

	public function copy(type:ClipboardType, json:Dynamic) {
		this.type = type;
		this.json = json;

		var str = Std.string(type) + "||||" + haxe.Json.stringify(json);
		electron.Clipboard.writeText(str);

		N.msg("Copied: "+getName());
	}

	public function clear() {
		json = null;
		type = null;
	}


	public function getName() : String {
		if( isEmpty() )
			return L.t._("Empty");

		return switch type {
			case CRule:
				var json : data.def.AutoLayerRuleDef = cast json;
				return 'Rule "${json.uid}"';

			case CRuleGroup:
				var json : data.DataTypes.AutoLayerRuleGroup = cast json;
				return 'Rule group "${json.name}"';

			case CLayerDef:
				var json : ldtk.Json.LayerDefJson = cast json;
				return 'Layer definition "${json.identifier}"';

			case CEntityDef:
				var json : ldtk.Json.EntityDefJson = cast json;
				return 'Entity definition "${json.identifier}"';

			case CEnumDef:
				var json : ldtk.Json.EnumDefJson = cast json;
				return 'Enum definition "${json.identifier}"';

			case CTilesetDef:
				var json : ldtk.Json.TilesetDefJson = cast json;
				return 'Tileset definition "${json.identifier}"';

			case CFieldDef:
				var json : ldtk.Json.FieldDefJson = cast json;
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

	// public inline function as<T>(outType:Class<T>) : Null<T> {
	// 	return isEmpty() ? null : Std.downcast(json, outType);
	// }
}