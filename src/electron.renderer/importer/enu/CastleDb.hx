package importer.enu;


// Rough CastleDB JSON typedef
private typedef CastleDbJson = {
	var sheets : Array<{
		var name : String;
		var columns : Array<{
			var typeStr : String;
			var name : String;
		}>;
		var lines : Array<{
			var constId: String;
			var values: Array<{
				var value : Dynamic;
				var valueName : String;
				var isInteger : Bool;
				var doc : String;
			}>;
		}>;
	}>;
}


class CastleDb extends importer.ExternalEnum {
	public function new() {
		super();
	}

	override function parse(fileContent:String) {
		super.parse(fileContent);

		var json : CastleDbJson = try haxe.Json.parse(fileContent) catch(_) null;
		if( json==null )
			return [];

		var parseds : Array<ParsedExternalEnum> = [];
		for(sheet in json.sheets) {
			// Check columns first and look for Unique IDs
			var idColumn : Null<String> = null;
			var colorColumn : Null<String> = null;
			for(col in sheet.columns) {
				switch col.typeStr {
					case "0": // unique identifier
						idColumn = col.name;

					case "11": // color
						if( colorColumn==null )
							colorColumn = col.name;

					case _:
				}
			}

			if( idColumn==null )
				continue;

			// Has a Unique Identifier column
			var enu : ParsedExternalEnum = {
				enumId: sheet.name,
				values: [],
			}
			parseds.push(enu);

			var uniq = new Map();
			for(line in sheet.lines) {
				var e = Reflect.field(line, idColumn);
				if( e==null || StringTools.trim(e).length==0 )
					continue;

				if( !uniq.exists(e) ) {
					uniq.set(e,true);
					enu.values.push({
						valueId: e,
						data: {
							color: colorColumn==null ? null : {
								var color : Int = Reflect.field(line, colorColumn);
								color;
							}
						},
					});
				}
			}

		}
		return parseds;
	}
}