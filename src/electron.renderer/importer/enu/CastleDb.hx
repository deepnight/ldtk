package importer.enu;


// Rough CastleDB JSON typedef
private typedef CastleDbJson = {
	var sheets : Array<{
		var name : String;
		var columns : Array<{
			var typeStr : String;
			var name : String;
		}>;
		var props : {
			var hasGroup : Bool;
			var displayIcon : Null<String>;
		}
		var lines : Array<Dynamic>;
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
			var tileColumn : Null<String> = null;
			for(col in sheet.columns) {
				switch col.typeStr {
					case "0": // unique identifier
						idColumn = col.name;

					case "11": // color
						if( colorColumn==null )
							colorColumn = col.name;

					case _:
				}
				if( sheet.props.displayIcon==col.name )
					tileColumn = col.name;
			}

			if( idColumn==null )
				continue;

			// Has a Unique Identifier column
			var enu : ParsedExternalEnum = {
				enumId: sheet.name,
				values: [],
			}
			parseds.push(enu);

			// Lookup or create icons tileset
			if( tileColumn!=null ) {
				var project = Editor.ME.project;
				for(line in sheet.lines) {
					var t = Reflect.field(line, tileColumn);
					if( t==null || t.file==null )
						continue;
					var rawIconPath = Std.string(t.file);
					var cdbIconPath = dn.FilePath.fromFile(sourceFp.directory + sourceFp.slash() + rawIconPath);
					js.html.Console.log(cdbIconPath.full);
					var cdbTd : data.def.TilesetDef = null;
					for(td in project.defs.tilesets) {
						if( td.isUsingEmbedAtlas() )
							continue;
						var tdFp = dn.FilePath.fromFile(td.relPath);
						if( tdFp.full==cdbIconPath.full ) {
							// Found existing tileset def
							cdbTd = td;
							break;
						}
					}
					// Create a new tileset def
					if( cdbTd==null ) {
						cdbTd = project.defs.createTilesetDef();
						cdbTd.importAtlasImage(cdbIconPath.full);
						var rawId = sourceFp.fileWithExt+"_"+cdbIconPath.fileWithExt;
						cdbTd.identifier = project.fixUniqueIdStr(rawId, (id)->project.defs.isTilesetIdentifierUnique(id,cdbTd));
						cdbTd.tags.set("CastleDB");
					}

					break;
				}
			}

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