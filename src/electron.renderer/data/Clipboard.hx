package data;

class Clipboard {
	static var SIGNATURE = Const.APP_NAME+" "+Const.getAppVersionStr(true)+" clipboard";
	static var SYS_SEP = "\n----\n";

	public var name(get,never) : Null<String>;
	var jsonObj : Null<Dynamic>;
	var jsonStr : Null<String>;
	var type : Null<ClipboardType>;
	var linkToSystem = false;


	private function new(linkToSystemClipboard:Bool) {
		this.linkToSystem = linkToSystemClipboard;
		clearInternal();
		readSystemClipboard();
	}

	@:keep
	public function toString() return 'Clipboard.${linkToSystem?"sys":"tmp"}($name})';

	/**
		Clear internal clipboard data
	**/
	function clearInternal() {
		jsonObj = null;
		jsonStr = null;
		type = null;
	}

	/** Create a Clipboard connected with the System clipboard **/
	public static function createSystem() : Clipboard {
		return new Clipboard(true);
	}

	/** Create a temporary Clipboard (ie. not connected with the System clipboard) **/
	public static function createTemp(type:ClipboardType, obj:Dynamic) : Clipboard {
		var c = new Clipboard(false);
		c.copyData(type, obj);
		return c;
	}


	/**
		Read system clipboard and check if it contains any compatible data
	**/
	var _lastKnownSys : Null<String>;
	public function readSystemClipboard() : Bool {
		if( !linkToSystem )
			return false;

		// Read system clipboard
		var raw = try electron.Clipboard.readText() catch(_) null;
		if( _lastKnownSys==raw )
			return false;
		_lastKnownSys = raw;

		// Check format
		if( raw==null || raw.substr(0,SIGNATURE.length)!=SIGNATURE ) {
			clearInternal();
			return false;
		}
		raw = StringTools.replace(raw, "\r", ""); // Windows CRLF
		var parts = raw.split(SYS_SEP);
		if( parts.length!=3 ) {
			clearInternal();
			return false;
		}

		// Extract type enum
		type = try Type.createEnum(ClipboardType, parts[1]) catch(_) null;
		if( type==null ) {
			clearInternal();
			return false;
		}

		// Extract & check JSON
		jsonStr = parts[2];
		jsonObj = try haxe.Json.parse(jsonStr) catch(_) null;
		if( jsonObj==null ) {
			clearInternal();
			return false;
		}

		return true;
	}

	/**
		Return clipboard content as an anonymous object parsed from internal JSON
	**/
	public function getParsedJson<T>() : Null<T> {
		readSystemClipboard();
		return isEmpty() ? null : jsonObj;
	}

	/**
		Write an anonymous object to the clipboard
	**/
	public function copyData(type:ClipboardType, obj:Dynamic) {
		this.type = type;
		this.jsonObj = obj;

		// Stringify JSON
		this.jsonStr = try haxe.Json.stringify(jsonObj) catch(_) null;
		if( jsonStr==null || type==null ) {
			clearInternal();
			N.error("Could not copy value, JSON writer failed!");
			return;
		}

		// Write system clipboard
		if( linkToSystem ) {
			var parts = [
				SIGNATURE,
				Std.string(type),
				jsonStr,
			];
			var str = parts.join(SYS_SEP);
			electron.Clipboard.writeText(str);
		}

		N.copied(name);
	}

	public function copyStr(v:String) {
		if( linkToSystem ) {
			electron.Clipboard.writeText(v);
			clearInternal();
		}

	}

	/**
		Human readable name from JSON
	**/
	function get_name() : String {
		// Extract name
		if( isEmpty() )
			return L.t._("Empty");
		else
			return switch type {
				case CRule:
					var json : data.def.AutoLayerRuleDef = jsonObj;
					'Rule "${json.uid}"';

				case CRuleGroup:
					var json : data.def.AutoLayerRuleGroupDef = jsonObj;
					'Rule group "${json.name}"';

				case CLayerDef:
					var json : ldtk.Json.LayerDefJson = jsonObj;
					'Layer definition "${json.identifier}"';

				case CEntityDef:
					var json : ldtk.Json.EntityDefJson = jsonObj;
					'Entity definition "${json.identifier}"';

				case CEnumDef:
					var json : ldtk.Json.EnumDefJson = jsonObj;
					'Enum definition "${json.identifier}"';

				case CTilesetDef:
					var json : ldtk.Json.TilesetDefJson = jsonObj;
					'Tileset definition "${json.identifier}"';

				case CFieldDef:
					var json : ldtk.Json.FieldDefJson = jsonObj;
					'Field definition "${json.identifier}"';
			}
	}


	public inline function isEmpty() return type==null || jsonStr==null || jsonObj==null;

	public inline function is(t:ClipboardType) {
		readSystemClipboard();
		return type!=null && t!=null && type.getIndex()==t.getIndex();
	}
}