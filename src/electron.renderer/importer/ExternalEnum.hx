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
			var checksum = haxe.crypto.Md5.encode(fileContent);
			importToProject(relPath, checksum, parseds);
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
	function importToProject(relSourcePath:String, checksum:String, parseds:Array<EditorTypes.ParsedExternalEnum>) {
		var tmpProject = Editor.ME.project.clone();

		var isNew = true;
		for(ed in tmpProject.defs.externalEnums)
			if( ed.externalRelPath==relSourcePath ) {
				isNew = false;
				break;
			}

		var syncOps : Array<EnumSyncOp> = [];

		var shownEnums = new Map();
		if( isNew ) {
			// Source file is completely new
			for(pe in parseds) {
				syncOps.push({
					type: AddEnum(pe.values),
					enumId: pe.enumId,
					cb: (p)->{
						trace('whole new, create $pe');
						p.defs.createExternalEnumDef(relSourcePath, checksum, pe);
					},
				});
			}
		}
		else {
			// Source file was previously already imported
			for(pe in parseds) {
				var existing = tmpProject.defs.getEnumDef(pe.enumId);
				if( existing==null ) {
					// New enum found
					syncOps.push({
						type: AddEnum(pe.values),
						enumId: pe.enumId,
						cb: (p)->{
							trace('create $pe');
							p.defs.createExternalEnumDef(relSourcePath, checksum, pe);
						},
					});
				}
				else {
					// Add new values on existing
					for(v in pe.values)
						if( !existing.hasValue(v) ) {
							syncOps.push({
								type: AddValue(v),
								enumId: pe.enumId,
								cb: (p)->{
									trace('add value $v to ${pe.enumId}');
									var ed = p.defs.getEnumDef(pe.enumId);
									ed.addValue(v);
								},
							});
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
							syncOps.push({
								type: RemoveValue( v.id, tmpProject.isEnumValueUsed(ed,v.id) ),
								enumId: pe.enumId,
								cb: (p)->{
									trace('lost value ${v.id} in ${pe.enumId}');
									var ed = p.defs.getEnumDef(pe.enumId);
									p.defs.removeEnumDefValue(ed, v.id);
								},
							});
							shownEnums.set(pe.enumId,true);
						}
					}

					existing.alphaSortValues();
				}
			}

			// Remove lost enums
			for( ed in tmpProject.defs.externalEnums )
				if( ed.externalRelPath==relSourcePath ) {
					var found = false;
					for(pe in parseds)
						if( pe.enumId==ed.identifier ) {
							found = true;
							break;
						}

					if( !found ) {
						syncOps.push({
							type: RemoveEnum(tmpProject.isEnumDefUsed(ed)),
							enumId: ed.identifier,
							cb: (p)->{
								trace('lost enum ${ed.identifier}');
								var ed = p.defs.getEnumDef(ed.identifier);
								p.defs.removeEnumDef(ed);
							},
						});
					}
				}
		}

		// Show sync window, if relevant
		var needConfirm = false;
		for(op in syncOps)
			switch op.type {
				case AddEnum(_):
				case AddValue(_):
				case DateUpdated:
				case Special:
				case RemoveEnum(used), RemoveValue(_,used):
					if( used ) {
						needConfirm = true;
						break;
					}
			}

		var fileName = dn.FilePath.extractFileWithExt(relSourcePath);
		if( needConfirm ) {
			// Request user confirmation
			new ui.modal.dialog.EnumSync(syncOps, relSourcePath, (updatedOps)->{
				new ui.LastChance( Lang.t._("External file \"::name::\" synced", { name:fileName }), Editor.ME.project );
				applySyncOps(updatedOps, relSourcePath, checksum);
				N.success( fileName, L.t._("Enums updated successfully.") );
			});
		}
		else if( syncOps.length>0 ) {
			// Update is easy
			applySyncOps(syncOps, relSourcePath, checksum);
			N.success( fileName, L.t._("Enums updated successfully.") );
		}
		else {
			// No change
			N.msg( fileName, L.t._("Enums are already up-to-date.") );
		}
	}



	/**
		Execute a list of sync operations
	**/
	function applySyncOps(ops:Array<EnumSyncOp>, relSourcePath:String, checksum:String) {
		var copy = Editor.ME.project.clone();

		// Run sync ops
		for( op in ops )
			op.cb(copy);

		// Fix checksum
		for( ed in copy.defs.externalEnums )
			if( ed.externalRelPath==relSourcePath && ed.externalFileChecksum!=checksum )
				ed.externalFileChecksum = checksum;

		copy.tidy();

		Editor.ME.selectProject(copy);

		// Break level cache
		for(op in ops)
			switch op.type {
				case AddEnum(_):
				case AddValue(_):
				case DateUpdated:
				case Special:
					Editor.ME.invalidateAllLevelsCache();
					break;

				case RemoveEnum(used), RemoveValue(_,used):
					if( used ) {
						Editor.ME.invalidateAllLevelsCache();
						break;
					}
			}
	}

}