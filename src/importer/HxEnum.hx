package importer;

class HxEnum {

	public static function load(relPath:String, isSync:Bool) {
		var curProject = Editor.ME.project;
		var absPath = Editor.ME.makeFullFilePath(relPath);
		var file = JsTools.readFileString(absPath);

		if( file==null ) {
			// File not found
			if( isSync )
				new ui.modal.dialog.LostFile(relPath, function(newAbs) {
					var newRel = Editor.ME.makeRelativeFilePath(newAbs);
					for(ed in curProject.defs.externalEnums)
						if( ed.externalRelPath==relPath )
							ed.externalRelPath = newRel;
					Editor.ME.ge.emit( EnumDefChanged );
					load(newRel, true);
				});
			else
				N.error( Lang.t._("File not found: ::path::", { path:relPath }) );

			return;
		}

		// Parse file
		var parseds = parse(file);
		if( parseds.length>0 ) {
			// Check for duplicate identifiers
			for(pe in parseds) {
				var ed = curProject.defs.getEnumDef(pe.enumId);
				if( ed!=null && ed.externalRelPath!=relPath ) {
					N.error("Import failed: the file contains the Enum identifier \""+pe.enumId+"\" which is already used in this project.");
					return;
				}
			}

			// Try to import/sync
			var copy = curProject.clone();
			var result = copy.defs.importExternalEnums(relPath, parseds);
			if( result.needConfirm )
				new ui.modal.dialog.EnumImport(result.log, relPath, copy);
			else if( result.log.length>0 ) {
				Editor.ME.selectProject(copy);
				N.success("Successfully imported enums!");
			}
			else
				N.msg("File is up-to-date!");
		}
	}



	static function parse(fileContent:String) : Array<ParsedExternalEnum> {
		if( fileContent==null || fileContent.length==0 )
			return [];

		// Trim comments
		var lineCommentReg = ~/^([^\/\n]*)(\/\/.*)$/gm;
		fileContent = lineCommentReg.replace(fileContent,"$1");
		var multilineCommentReg = ~/(\/\*[\s\S]*?\*\/)/gm;
		fileContent = multilineCommentReg.replace(fileContent,"");

		// Any enum?
		var enumBlocksReg = ~/^[ \t]*enum[ \t]+([a-z0-9_]+)[ \t]*{/gim;
		if( !enumBlocksReg.match(fileContent) ) {
			N.error("Couldn't find any simple Enum in this source fileContent.");
			return [];
		}

		// Search enum blocks
		var parseds : Array<ParsedExternalEnum> = [];
		while( enumBlocksReg.match(fileContent) ) {
			var enumId = enumBlocksReg.matched(1);

			// Extract values block
			var brackets = 1;
			var pos = enumBlocksReg.matchedPos().pos + enumBlocksReg.matchedPos().len;
			var start = pos;
			while( pos < fileContent.length && brackets>=1 ) {
				if( fileContent.charAt(pos)=="{" )
					brackets++;
				else if( fileContent.charAt(pos)=="}" )
					brackets--;
				pos++;
			}
			var rawValues = fileContent.substring(start,pos-1);

			// Checks presence of unsupported Parametered values
			var paramEnumReg = ~/([A-Z][A-Za-z0-9_]*)[ \t]*\(/gm;
			if( !paramEnumReg.match(rawValues) ) {
				// This enum only contains unparametered values
				var enumValuesReg = ~/([A-Z][A-Za-z0-9_]*)[ \t]*;/gm;
				var values = [];
				while( enumValuesReg.match(rawValues) ) {
					values.push( enumValuesReg.matched(1) );
					rawValues = enumValuesReg.matchedRight();
				}
				if( values.length>0 ) {
					// Success!
					parseds.push({
						enumId: enumId,
						values: values,
					});
				}
			}


			fileContent = enumBlocksReg.matchedRight();
		}
		return parseds;
	}
}