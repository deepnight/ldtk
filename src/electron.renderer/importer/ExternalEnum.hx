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
		if( isSync )
			App.LOG.add("import", 'Syncing external enums: $relPath');
		else
			App.LOG.add("import", 'Loading external enums: $relPath');

		var project = Editor.ME.project;
		var absPath = project.makeAbsoluteFilePath(relPath);
		var fileContent = NT.readFileString(absPath);

		// File not found
		if( fileContent==null ) {
			App.LOG.add("import", 'Missing file');
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
			App.LOG.add("import", 'Empty file');
			N.error( Lang.t._("This file is empty: ::path::", { path:relPath }) );
			return;
		}

		// Extract file enums
		var parseds = parse(fileContent);

		if( parseds.length>0 ) {
			// Check for identifiers conflicts
			for(pe in parseds) {
				var ed = project.defs.getEnumDef(pe.enumId);
				if( ed!=null && ed.externalRelPath!=relPath ) {
					App.LOG.add("import", 'Conflict with existing enum: ${pe.enumId}');
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

		// Check if the source file is new to this project
		var isNew = true;
		for(ed in project.defs.externalEnums)
			if( ed.externalRelPath==relSourcePath ) {
				isNew = false;
				break;
			}


		// Init diff
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
					// New enum
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

		// Log diff
		function _printDiff(diff:Map<String,EnumSyncDiff>) {
			var out = [];
			for(e in diff) {
				switch e.change {
					case null:
						for(v in e.valueDiffs)
							switch v.change {
								case Added: out.push("+"+e.enumId+"."+v.valueId);
								case Removed: out.push("-"+e.enumId+"."+v.valueId);
								case Renamed(to): out.push(e.enumId+"."+v.valueId+"=>"+to);
							}
					case Added: out.push("+"+e.enumId);
					case Removed: out.push("-"+e.enumId);
					case Renamed(to): out.push(e.enumId+"=>"+to);
				}
			}
			return out.join(", ");
		}
		App.LOG.add("import", 'Sync diff result: ${_printDiff(diff)}');

		// Check if some user confirmation is required for upcoming
		var needConfirm = false;
		for(eDiff in diff) {
			switch eDiff.change {
				case Added:
				case Renamed(to): // should not be in here before Sync window

				case Removed:
					// Check if removed enum is used
					var ed = project.defs.getEnumDef(eDiff.enumId);
					if( project.isEnumDefUsed(ed) ) {
						needConfirm = true;
						break;
					}

				case null:
					// Check value changes
					var ed = project.defs.getEnumDef(eDiff.enumId);
					for(vDiff in eDiff.valueDiffs)
						switch vDiff.change {
							case Added:
							case Renamed(to): // should not be in here before Sync window

							case Removed:
								// Check if removed value is used
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
			App.LOG.add("import", 'Sync needs user actions');
			new ui.modal.dialog.EnumSync(diff, relSourcePath, (updatedOps)->{
				App.LOG.add("import", 'Updated sync diff: ${_printDiff(diff)}');
				new ui.LastChance( Lang.t._("External file \"::name::\" synced", { name:fileName }), Editor.ME.project );
				App.LOG.add("import", 'Sync needs user actions');
				applyDiff(diff, relSourcePath);
				Editor.ME.invalidateAllLevelsCache();
				project.tidy();
				updateChecksums(relSourcePath, checksum);
				Editor.ME.ge.emit( ExternalEnumsLoaded(true) );
				N.success( fileName, L.t._("Enums updated successfully.") );
			});
		}
		else if( Lambda.count(diff)>0 ) {
			// Update is easy
			App.LOG.add("import", 'Sync automatically applied.');
			applyDiff(diff, relSourcePath);
			updateChecksums(relSourcePath, checksum);
			Editor.ME.ge.emit( ExternalEnumsLoaded(true) );
			N.success( fileName, L.t._("Enums updated successfully.") );
		}
		else {
			// No change
			App.LOG.add("import", 'Nothing to sync.');
			N.msg( fileName, L.t._("Enums are already up-to-date.") );
			updateChecksums(relSourcePath, checksum);
			Editor.ME.ge.emit( ExternalEnumsLoaded(false) );
		}
	}


	/**
		Refresh external source checksums
	**/
	function updateChecksums(relSourcePath:String, checksum:String) {
		// Update checksums
		for( ed in Editor.ME.project.defs.externalEnums )
			if( ed.externalRelPath==relSourcePath && ed.externalFileChecksum!=checksum )
				ed.externalFileChecksum = checksum;


	}


	/**
		Update project using diff data
	**/
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
							case Added: // New value
								trace('add value ${vDiff.valueId}');
								ed.addValue(vDiff.valueId);
								unsortedEnums.set(ed.identifier, true);

							case Removed: // Lost value
								trace('remove value ${vDiff.valueId}');
								ed.removeValue(vDiff.valueId);

							case Renamed(to): // Renamed value
								trace('rename value ${vDiff.valueId}=>$to');
								ed.renameValue(vDiff.valueId, to);
								unsortedEnums.set(ed.identifier, true);
						}

				case Added: // New enum
					trace('add enum ${eDiff.enumId}');
					var ed = project.defs.createEnumDef(relSourcePath);
					ed.identifier = eDiff.enumId;
					for(v in eDiff.valueDiffs)
						ed.addValue(v.valueId);
					unsortedEnums.set(ed.identifier, true);

				case Removed: // Lost enum
					trace('remove enum ${eDiff.enumId}');
					var ed = project.defs.getEnumDef(eDiff.enumId);
					project.defs.removeEnumDef(ed);

				case Renamed(to): // Renamed enum
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

}