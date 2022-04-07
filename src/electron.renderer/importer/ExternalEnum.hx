package importer;

class ExternalEnum {

	public static function sync(relPath:String) {
		var ext = dn.FilePath.extractExtension(relPath,true);
		switch ext {
			case "hx":
				var i = new HxEnum();
				i.load(relPath, true);

			case "cdb":
				var i = new CastleDb();
				i.load(relPath, true);

			case _: N.error('Unsupported extension "$ext" for imported enum file.');
		}
	}

	private function new() {}


	/**
		Load enums from given external file
	**/
	public function load(relPath:String, isSync=false) {
		var project = Editor.ME.project;
		var absPath = project.makeAbsoluteFilePath(relPath);
		var fileContent = NT.readFileString(absPath);

		// File not found
		if( fileContent==null ) {
			if( isSync )
				new ui.modal.dialog.LostFile(relPath, function(newAbs) {
					var newRel = project.makeRelativeFilePath(newAbs);
					if( project.remapExternEnums(relPath, newRel) )
						Editor.ME.ge.emit( EnumDefChanged );
					load(newRel, true);
				});
			else
				N.error( Lang.t._("File not found: ::path::", { path:relPath }) );

			return;
		}

		// Empty file
		if( fileContent.length==0 ) {
			N.error( Lang.t._("This file is empty: ::path::", { path:relPath }) );
			return;
		}

		var parseds = parse(fileContent);
		if( parseds.length>0 ) {
			// Check for identifiers conflicts
			for(pe in parseds) {
				var ed = project.defs.getEnumDef(pe.enumId);
				if( ed!=null && ed.externalRelPath!=relPath ) {
					N.error("Import failed: the file contains the Enum \""+pe.enumId+"\" which is already used in this project.");
					return;
				}
			}

			// Try to import/sync
			var copy = project.clone();
			var checksum = haxe.crypto.Md5.encode(fileContent);
			importToProject(copy, relPath, checksum, parseds);
		}
	}




	/**
		Parse enums in file
	**/
	function parse(fileContent:String) : Array<ParsedExternalEnum> {
		return [];
	}



	/**
		Import parsed enums to existing project
	**/
	function importToProject(tmpProject:data.Project, relSourcePath:String, checksum:String, parseds:Array<EditorTypes.ParsedExternalEnum>) {
		var log : SyncLog = [];

		var isNew = true;
		for(ed in tmpProject.defs.externalEnums)
			if( ed.externalRelPath==relSourcePath ) {
				isNew = false;
				break;
			}


		var shownEnums = new Map();
		if( isNew ) {
			// Source file is completely new
			for(pe in parseds) {
				log.push({ op:Add, str:'New enum: "${pe.enumId}"' });
				tmpProject.defs.createExternalEnumDef(relSourcePath, checksum, pe);
			}
		}
		else {
			// Source file was previously already imported
			for(pe in parseds) {
				var existing = tmpProject.defs.getEnumDef(pe.enumId);
				if( existing==null ) {
					// New enum found
					tmpProject.defs.createExternalEnumDef(relSourcePath, checksum, pe);
					log.push({ op:Add, str:'New enum: "${pe.enumId}"' });
				}
				else {
					// Add new values on existing
					for(v in pe.values)
						if( !existing.hasValue(v) ) {
							existing.addValue(v);
							log.push({ op:Add, str:'New enum value: "${pe.enumId}.$v"' });
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
							var ed = tmpProject.defs.getEnumDef(pe.enumId);
							log.push({
								op:Remove( tmpProject.isEnumValueUsed(ed,v.id) ),
								str:'Removed enum value: "${pe.enumId}.${v.id}"'
							});
							shownEnums.set(pe.enumId,true);
							tmpProject.defs.removeEnumDefValue(existing, v.id);
						}
					}

					existing.alphaSortValues();
				}
			}

			// Remove lost enums
			for( ed in tmpProject.defs.externalEnums.copy() )
				if( ed.externalRelPath==relSourcePath ) {
					var found = false;
					for(pe in parseds)
						if( pe.enumId==ed.identifier ) {
							found = true;
							break;
						}

					if( !found ) {
						log.push({ op:Remove(tmpProject.isEnumDefUsed(ed)), str:'Removed enum: ${ed.identifier}' });
						tmpProject.defs.removeEnumDef(ed);
					}
				}
		}

		// Fix checksum
		for( ed in tmpProject.defs.externalEnums )
			if( ed.externalRelPath==relSourcePath && ed.externalFileChecksum!=checksum ) {
				ed.externalFileChecksum = checksum;
				if( !shownEnums.exists(ed.identifier) )
					log.push({ op:ChecksumUpdated, str:"Enum "+ed.identifier });
			}


		tmpProject.tidy();


		// Show sync window, if relevant
		var needConfirm = false;
		for(l in log)
			switch l.op {
				case Remove(used):
					if( used ) {
						needConfirm = true;
						break;
					}
				case Add:
				case ChecksumUpdated:
				case DateUpdated:
			}

		if( needConfirm ) {
			// Request user confirmation
			new ui.modal.dialog.SyncLogPrint(log, relSourcePath, tmpProject);
		}
		else if( log.length>0 ) {
			// Update went well
			var fp = dn.FilePath.fromFile(relSourcePath);
			N.success( L.t._("::file:: updated successfully.", { file:fp.fileWithExt }));
			Editor.ME.selectProject( tmpProject );
		}
		else {
			// No change
			N.msg(L.t._("File is already up-to-date."));
		}
	}
}