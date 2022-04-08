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
		var project = Editor.ME.project;

		var isNew = true;
		for(ed in project.defs.externalEnums)
			if( ed.externalRelPath==relSourcePath ) {
				isNew = false;
				break;
			}


		var diff : Map<String, EnumSyncDiff> = new Map();

		function _getEnumDiff(enumId:String) : EnumSyncDiff {
			if( !diff.exists(enumId) )
				diff.set(enumId, {
					enumId: enumId,
					change: null,
					valueDiffs: new Map(),
				});

			return diff.get(enumId);
		}

		function _getValueDiff(enumId:String, valueId:String) : EnumValueSyncDiff {
			var ec = _getEnumDiff(enumId);
			if( !ec.valueDiffs.exists(valueId) )
				ec.valueDiffs.set(valueId, {
					valueId: valueId,
					change: null, // not meant to be null in the end
				});

			return ec.valueDiffs.get(valueId);
		}

		if( isNew ) {
			// Brand new source file, everything is new
			for(pe in parseds) {
				_getEnumDiff(pe.enumId).change = Added;
				for(v in pe.values) {
					var ec = _getValueDiff(pe.enumId, v);
					ec.change = Added;
				}
			}
		}
		else {
			// Source file was previously already imported
			for(pe in parseds) {
				var existing = project.defs.getEnumDef(pe.enumId);
				if( existing==null ) {
					// New enum found
					_getEnumDiff(pe.enumId).change = Added;
					for(v in pe.values) {
						var ec = _getValueDiff(pe.enumId, v);
						ec.change = Added;
					}
				}
				else {
					// New values
					for(v in pe.values)
						if( !existing.hasValue(v) ) {
							var vc = _getValueDiff(pe.enumId, v);
							vc.change = Added;
						}

					// Lost values
					for(edv in existing.values.copy()) {
						var found = false;
						for(v2 in pe.values)
							if( v2==edv.id ) {
								found = true;
								break;
							}

						if( !found ) {
							var ed = project.defs.getEnumDef(pe.enumId);
							var vc = _getValueDiff(pe.enumId, edv.id);
							vc.change = Removed;
						}
					}
				}
			}

			// Lost enums
			for( ed in project.defs.externalEnums )
				if( ed.externalRelPath==relSourcePath ) {
					var found = false;
					for(pe in parseds)
						if( pe.enumId==ed.identifier ) {
							found = true;
							break;
						}

					if( !found ) {
						_getEnumDiff(ed.identifier).change = Removed;
						for(v in ed.values)
							_getValueDiff(ed.identifier, v.id).change = Removed;
					}
				}
		}

		trace(diff);

		// var syncOps : Array<EnumSyncOp> = [];

		// var shownEnums = new Map();
		// if( isNew ) {
		// 	// Source file is completely new
		// 	for(pe in parseds) {
		// 		syncOps.push({
		// 			type: AddEnum(pe.values),
		// 			enumId: pe.enumId,
		// 			cb: (p)->{
		// 				trace('whole new, create $pe');
		// 				p.defs.createExternalEnumDef(relSourcePath, checksum, pe);
		// 			},
		// 		});
		// 	}
		// }
		// else {
		// 	// Source file was previously already imported
		// 	for(pe in parseds) {
		// 		var existing = project.defs.getEnumDef(pe.enumId);
		// 		if( existing==null ) {
		// 			// New enum found
		// 			syncOps.push({
		// 				type: AddEnum(pe.values),
		// 				enumId: pe.enumId,
		// 				cb: (p)->{
		// 					trace('create $pe');
		// 					p.defs.createExternalEnumDef(relSourcePath, checksum, pe);
		// 				},
		// 			});
		// 		}
		// 		else {
		// 			// Add new values on existing
		// 			for(v in pe.values)
		// 				if( !existing.hasValue(v) ) {
		// 					syncOps.push({
		// 						type: AddValue(v),
		// 						enumId: pe.enumId,
		// 						cb: (p)->{
		// 							trace('add value $v to ${pe.enumId}');
		// 							var ed = p.defs.getEnumDef(pe.enumId);
		// 							ed.addValue(v);
		// 						},
		// 					});
		// 					shownEnums.set(pe.enumId,true);
		// 				}

		// 			// Remove lost values
		// 			for(v in existing.values.copy()) {
		// 				var found = false;
		// 				for(v2 in pe.values)
		// 					if( v2==v.id ) {
		// 						found = true;
		// 						break;
		// 					}

		// 				if( !found ) {
		// 					var ed = project.defs.getEnumDef(pe.enumId);
		// 					syncOps.push({
		// 						type: RemoveValue( v.id, project.isEnumValueUsed(ed,v.id) ),
		// 						enumId: pe.enumId,
		// 						cb: (p)->{
		// 							trace('lost value ${v.id} in ${pe.enumId}');
		// 							var ed = p.defs.getEnumDef(pe.enumId);
		// 							p.defs.removeEnumDefValue(ed, v.id);
		// 						},
		// 					});
		// 					shownEnums.set(pe.enumId,true);
		// 				}
		// 			}

		// 			existing.alphaSortValues();
		// 		}
		// 	}

		// 	// Remove lost enums
		// 	for( ed in project.defs.externalEnums )
		// 		if( ed.externalRelPath==relSourcePath ) {
		// 			var found = false;
		// 			for(pe in parseds)
		// 				if( pe.enumId==ed.identifier ) {
		// 					found = true;
		// 					break;
		// 				}

		// 			if( !found ) {
		// 				syncOps.push({
		// 					type: RemoveEnum(project.isEnumDefUsed(ed)),
		// 					enumId: ed.identifier,
		// 					cb: (p)->{
		// 						trace('lost enum ${ed.identifier}');
		// 						var ed = p.defs.getEnumDef(ed.identifier);
		// 						p.defs.removeEnumDef(ed);
		// 					},
		// 				});
		// 			}
		// 		}
		// }

		// Show sync window, if some user confirmation is required
		var needConfirm = false;
		for(eDiff in diff) {
			switch eDiff.change {
				case Added:

				case Removed:
					var ed = project.defs.getEnumDef(eDiff.enumId);
					if( project.isEnumDefUsed(ed) ) {
						needConfirm = true;
						break;
					}

				case Renamed(to): // should not be in here before Sync window

				case null:
					var ed = project.defs.getEnumDef(eDiff.enumId);
					for(vDiff in eDiff.valueDiffs)
						switch vDiff.change {
							case Added:
							case Renamed(to): // should not be in here before Sync window
							case Removed:
								if( project.isEnumValueUsed(ed, vDiff.valueId) ) {
									needConfirm = true;
									break;
								}
						}

			}
		}

		var fileName = dn.FilePath.extractFileWithExt(relSourcePath);
		if( needConfirm ) {
			// Request user confirmation
			new ui.modal.dialog.EnumSync(diff, relSourcePath, (updatedOps)->{
				new ui.LastChance( Lang.t._("External file \"::name::\" synced", { name:fileName }), Editor.ME.project );
				applyDiff(diff, relSourcePath);
				Editor.ME.invalidateAllLevelsCache();
				project.tidy();
				updateChecksums(relSourcePath, checksum);
				Editor.ME.ge.emit( ExternalEnumsLoaded );
				N.success( fileName, L.t._("Enums updated successfully.") );
			});
		}
		else if( Lambda.count(diff)>0 ) {
			// Update is easy
			applyDiff(diff, relSourcePath);
			updateChecksums(relSourcePath, checksum);
			Editor.ME.ge.emit( ExternalEnumsLoaded );
			N.success( fileName, L.t._("Enums updated successfully.") );
		}
		else {
			// No change
			N.msg( fileName, L.t._("Enums are already up-to-date.") );
			updateChecksums(relSourcePath, checksum);
			Editor.ME.ge.emit( ExternalEnumsLoaded );
		}
	}


	function updateChecksums(relSourcePath:String, checksum:String) {
		// Update checksums
		for( ed in Editor.ME.project.defs.externalEnums )
			if( ed.externalRelPath==relSourcePath && ed.externalFileChecksum!=checksum )
				ed.externalFileChecksum = checksum;


	}



	function applyDiff(diff:Map<String,EnumSyncDiff>, relSourcePath:String) {
		var project = Editor.ME.project;

		var unsortedEnums = new Map();
		for(eDiff in diff) {
			switch eDiff.change {

				case null:
					// Value changes
					var ed = project.defs.getEnumDef(eDiff.enumId);
					for(vDiff in eDiff.valueDiffs)
						switch vDiff.change {
							case Added:
								trace('add value ${vDiff.valueId}');
								ed.addValue(vDiff.valueId);

							case Removed:
								trace('remove value ${vDiff.valueId}');
								ed.removeValue(vDiff.valueId);

							case Renamed(to):
								trace('rename value ${vDiff.valueId}=>$to');
								ed.renameValue(vDiff.valueId, to);
						}

				case Added:
					trace('add enum ${eDiff.enumId}');
					var ed = project.defs.createEnumDef(relSourcePath);
					ed.identifier = eDiff.enumId;
					for(v in eDiff.valueDiffs)
						ed.addValue(v.valueId);
					unsortedEnums.set(ed.identifier, true);

				case Removed:
					trace('remove enum ${eDiff.enumId}');
					var ed = project.defs.getEnumDef(eDiff.enumId);
					project.defs.removeEnumDef(ed);

				case Renamed(to):
					trace('rename enum ${eDiff.enumId}=>$to');
					var ed = project.defs.getEnumDef(eDiff.enumId);
					ed.identifier = to;
			}
		}

		// Re-sort modified enums
		for(ed in project.defs.externalEnums)
			if( unsortedEnums.exists(ed.identifier) )
				ed.alphaSortValues();
	}


	/**
		Execute a list of sync operations
	**/
	// function applySyncOps(ops:Array<EnumSyncOp>, relSourcePath:String, checksum:String) {
	// 	var project = Editor.ME.project;

	// 	// Run sync ops
	// 	for( op in ops )
	// 		op.cb(project);

	// 	// Break level cache
	// 	var unsortedEnums = new Map();
	// 	for(op in ops)
	// 		switch op.type {
	// 			case AddEnum(_):
	// 			case AddValue(_):
	// 				unsortedEnums.set(op.enumId, true);

	// 			case DateUpdated:
	// 			case Special:
	// 				unsortedEnums.set(op.enumId, true);
	// 				Editor.ME.invalidateAllLevelsCache();
	// 				break;

	// 			case RemoveValue(_,used):
	// 				if( used ) {
	// 					Editor.ME.invalidateAllLevelsCache();
	// 					break;
	// 				}

	// 			case RemoveEnum(used):
	// 				if( used ) {
	// 					Editor.ME.invalidateAllLevelsCache();
	// 					unsortedEnums.set(op.enumId, true);
	// 					break;
	// 				}
	// 		}

	// 	// Re-sort modified enums
	// 	for(ed in project.defs.externalEnums)
	// 		if( unsortedEnums.exists(ed.identifier) )
	// 			ed.alphaSortValues();

	// 	Editor.ME.ge.emit( ExternalEnumsLoaded );
	// }

}