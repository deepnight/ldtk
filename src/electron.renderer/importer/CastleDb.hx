package importer;

import haxe.DynamicAccess;
import cdb.Database;

class CastleDb {

	public function new() {}

	public function load(relPath:String, isSync=false) {

		var project = Editor.ME.project;
		var absPath = project.makeAbsoluteFilePath(relPath);
		var fileContent = NT.readFileString(absPath);
		var sourceFp = dn.FilePath.fromFile(relPath);

		var db = new Database();
		db.load(fileContent);
		
		for (sheet in db.sheets) {
			// for (column in sheet.columns) {
			// 	switch (column.type) {
			// 		case TTilePos:
			// 		case _:
			// 	}
			// }
			var cdbTd : data.def.TilesetDef = null;
			for (line in sheet.lines) {
				var line:DynamicAccess<Dynamic> = line;

				// Lookup or create icons tileset
				if (sheet.props.displayIcon != null) {
					var v = line.get(sheet.props.displayIcon);
					if (v == null || v.file == null) continue;

					var rawIconPath = Std.string(v.file);
					var cdbIconPath = dn.FilePath.fromFile(sourceFp.directory + sourceFp.slash() + rawIconPath);
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
				}
			}
		}
		project.database = db;
	}
}