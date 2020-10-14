package importer;

class HxEnum {

	public static function load(relPath:String, isSync:Bool) {
		var curProject = Editor.ME.project;
		var absPath = Editor.ME.makeAbsoluteFilePath(relPath);
		var fileContent = JsTools.readFileString(absPath);

		// File not found
		if( fileContent==null ) {
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
		var parseds = parse(fileContent);
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
			var checksum = haxe.crypto.Md5.encode(fileContent);
			var log = importToProject(copy, relPath, checksum, parseds);
			if( log.length>0 )
				new ui.modal.dialog.Sync(log, relPath, copy);
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



	static function importToProject(project:data.Project, relSourcePath:String, checksum:String, parseds:Array<EditorTypes.ParsedExternalEnum>) : SyncLog {
		var log : SyncLog = [];

		var shownEnums = new Map();

		var isNew = true;
		for(ed in project.defs.externalEnums)
			if( ed.externalRelPath==relSourcePath ) {
				isNew = false;
				break;
			}

		if( isNew ) {
			// Source file is completely new
			for(pe in parseds) {
				log.push({ op:Add, str:'New enum: "${pe.enumId}"' });
				project.defs.createExternalEnumDef(relSourcePath, checksum, pe);
			}
		}
		else {
			// Source file was previously already imported
			for(pe in parseds) {
				var existing = project.defs.getEnumDef(pe.enumId);
				if( existing==null ) {
					// New enum found
					project.defs.createExternalEnumDef(relSourcePath, checksum, pe);
					log.push({ op:Add, str:'New enum: "${pe.enumId}"' });
				}
				else {
					// Add new values on existing
					for(v in pe.values)
						if( !existing.hasValue(v) ) {
							existing.addValue(v);
							log.push({ op:Add, str:'New value: "${pe.enumId}.$v"' });
							shownEnums.set(pe.enumId,true);
						}

					// Remove lost values
					for(v in existing.values.copy()) {
						var found = false;
						for(v2 in pe.values)
							if( v2==v.id ) {
								found = true;
								break;
							}

						if( !found ) {
							var ed = project.defs.getEnumDef(pe.enumId);
							log.push({
								op:Remove( project.isEnumValueUsed(ed,v.id) ),
								str:'Removed value: "${pe.enumId}.${v.id}"'
							});
							shownEnums.set(pe.enumId,true);
							project.defs.removeEnumDefValue(existing, v.id);
						}
					}

					existing.alphaSortValues();
				}
			}

			// Remove lost enums
			for( ed in project.defs.externalEnums.copy() )
				if( ed.externalRelPath==relSourcePath ) {
					var found = false;
					for(pe in parseds)
						if( pe.enumId==ed.identifier ) {
							found = true;
							break;
						}

					if( !found ) {
						log.push({ op:Remove(project.isEnumDefUsed(ed)), str:'Removed enum: ${ed.identifier}' });
						project.defs.removeEnumDef(ed);
					}
				}
		}

		// Fix checksum
		for( ed in project.defs.externalEnums )
			if( ed.externalRelPath==relSourcePath && ed.externalFileChecksum!=checksum ) {
				ed.externalFileChecksum = checksum;
				if( !shownEnums.exists(ed.identifier) )
					log.push({ op:ChecksumUpdated, str:ed.identifier });
			}



		project.tidy();
		return log;
	}

}