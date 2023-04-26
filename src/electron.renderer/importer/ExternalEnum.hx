package importer;

class ExternalEnum {
	var sourceFp : dn.FilePath;
	var supportsIcons = false;
	var supportsColors = false;

	public static function sync(relPath:String) {
		var ext = dn.FilePath.extractExtension(relPath,true);
		switch ext {
			case "hx":
				var i = new importer.enu.HxEnum();
				i.load(relPath, true);

			case "cdb":
				var i = new importer.enu.CastleDb();
				i.load(relPath, true);

			case "txt":
				var i = new importer.enu.TextFileEnum();
				i.load(relPath, true);

			case "json":
				var i = new importer.enu.JsonEnum();
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
			App.LOG.add("import", 'Importing external enums (new file): $relPath');

		sourceFp = dn.FilePath.fromFile(relPath);
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
			// Sanitize enum IDs and value IDs
			for(pe in parseds) {
				pe.enumId = data.Project.cleanupIdentifier(pe.enumId, project.identifierStyle);

				var existing = new Map();
				for(value in pe.values) {
					var fixedId = project.fixUniqueIdStr(value.valueId, id->!existing.exists(id));
					existing.set(fixedId,true);
					value.valueId = fixedId;
				}
			}

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
		Parse values from a single string, expecting one of these formats:
		 - valueA, valueB, valueC
		 - valueA valueB valueC
		 - valueA ; valueB ; valueC
	**/
	function parseValuesFromString(rawValues:String) : Array<String> {
		if( rawValues==null )
			return [];

		rawValues = StringTools.trim(rawValues);
		if( rawValues.length==0 )
			return [];

		var values = [];

		// Guess separator
		var valueSep = null;
		for(s in [",", ";", " "])
			if( rawValues.indexOf(s)>=0 ) {
				valueSep = s;
				break;
			}
		if( valueSep==null )
			return [];

		// Split values
		for( raw in rawValues.split(valueSep) ) {
			raw = StringTools.trim(raw);
			if( raw.length==0 )
				continue;
			values.push(raw);
		}

		return values;
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
					newTilesetUid: -1,
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
					data: {
						color: null,
						tileRect: null,
					},
					change: null, // not meant to be null in the end
				});

			return ec.valueDiffs.get(valueId);
		}

		if( isNew ) {
			// Brand new source file, everything is new
			for(pe in parseds) {
				var eDiff = _getEnumDiff(pe.enumId);
				eDiff.change = Added;
				eDiff.newTilesetUid = pe.tilesetUid;
				for(v in pe.values) {
					var ec = _getValueDiff(pe.enumId, v.valueId);
					ec.change = Added;
					ec.data = v.data;
				}
			}
		}
		else {
			// Source file was previously already imported
			for(pe in parseds) {

				var existing = project.defs.getEnumDef(pe.enumId);
				if( existing==null ) {
					// New enum
					var eDiff = _getEnumDiff(pe.enumId);
					eDiff.change = Added;
					eDiff.newTilesetUid = pe.tilesetUid;
					for(v in pe.values) {
						var ec = _getValueDiff(pe.enumId, v.valueId);
						ec.change = Added;
						ec.data = v.data;
					}
				}
				else {
					// Changed tileset UID
					if( supportsIcons && existing.iconTilesetUid!=pe.tilesetUid )
						_getEnumDiff(pe.enumId).newTilesetUid = pe.tilesetUid;

					// New values
					for(v in pe.values)
						if( !existing.hasValue(v.valueId) ) {
							var vc = _getValueDiff(pe.enumId, v.valueId);
							vc.change = Added;
						}

					// Lost values
					for(edv in existing.values.copy()) {
						var found = false;
						for(v2 in pe.values)
							if( v2.valueId == edv.id ) {
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
				applyDiff(diff, relSourcePath);
				preserveEnumValuesOrder(parseds);
				Editor.ME.invalidateAllLevelsCache();
				copyParsedValuesData(parseds);
				project.tidy();
				updateChecksums(relSourcePath, checksum);
				Editor.ME.ge.emit( ExternalEnumsLoaded(true) );
				N.success( fileName, L.t._("Enums updated successfully.") );
			});
		}
		else {
			var valuesDataChanged = copyParsedValuesData(parseds);
			if( Lambda.count(diff)>0 || valuesDataChanged ) {
				// Simple case: sync operations don't affect any existing project instance
				App.LOG.add("import", 'Sync automatically applied.');
				applyDiff(diff, relSourcePath);
				preserveEnumValuesOrder(parseds);
				updateChecksums(relSourcePath, checksum);
				if( valuesDataChanged )
					Editor.ME.invalidateAllLevelsCache();
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
	}



	function preserveEnumValuesOrder(parseds:Array<ParsedExternalEnum>) {
		for(pe in parseds) {
			var ed = Editor.ME.project.defs.getEnumDef(pe.enumId);
			var i = 0;
			for(pev in pe.values) {
				var fromIdx = ed.getValueIndex(pev.valueId);
				var v = ed.values.splice(fromIdx,1)[0];
				ed.values.insert(i, v);
				i++;
			}
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


	function copyParsedValuesData(parseds:Array<ParsedExternalEnum>) {
		var project = Editor.ME.project;

		var anyChange = false;
		for(pe in parseds) {
			var ed = project.defs.getEnumDef(pe.enumId);
			if( ed==null )
				continue;

			for(pv in pe.values) {
				var ev = ed.getValue(pv.valueId);
				if( ev==null )
					continue;

				// Update value color
				if( supportsColors && pv.data.color!=ev.color ) {
					ev.color = pv.data.color;
					anyChange = true;
				}

				if( supportsIcons ) {
					// Lost tile
					if( pv.data.tileRect==null && ev.tileRect!=null ) {
						ev.tileRect = null;
						anyChange = true;
					}

					// New tile
					if( pv.data.tileRect!=null && ev.tileRect==null ) {
						ev.tileRect = {
							tilesetUid: pv.data.tileRect.tilesetUid,
							x: pv.data.tileRect.x,
							y: pv.data.tileRect.y,
							w: pv.data.tileRect.w,
							h: pv.data.tileRect.h,
						}
						anyChange = true;
					}

					if( pv.data.tileRect!=null && ev.tileRect!=null ) {
						var oldT = ev.tileRect;
						var newT = pv.data.tileRect;
						if( oldT.x!=newT.x || oldT.y!=newT.y || oldT.w!=newT.w || oldT.h!=newT.h || oldT.tilesetUid!=newT.tilesetUid ) {
							ev.tileRect = {
								tilesetUid: pv.data.tileRect.tilesetUid,
								x: pv.data.tileRect.x,
								y: pv.data.tileRect.y,
								w: pv.data.tileRect.w,
								h: pv.data.tileRect.h,
							}
							anyChange = true;
						}
					}
				}
			}
		}

		if( anyChange )
			App.LOG.add("import", 'Some enum values data were updated.');
		else
			App.LOG.add("import", 'No change in enum values data.');

		return anyChange;
	}


	/**
		Update project using diff data
	**/
	function applyDiff(diff:Map<String,EnumSyncDiff>, relSourcePath:String) {
		var project = Editor.ME.project;

		for(eDiff in diff) {
			switch eDiff.change {
				case null:
					// Value changes
					var ed = project.defs.getEnumDef(eDiff.enumId);
					for(vDiff in eDiff.valueDiffs)
						switch vDiff.change {
							case Added: // New value
								var ev = ed.addValue(vDiff.valueId);
								if( vDiff.data.color!=null )
									ev.color = vDiff.data.color;
								if( vDiff.data.tileRect!=null )
									ev.tileRect = vDiff.data.tileRect;

							case Removed: // Lost value
								ed.removeValue(vDiff.valueId);

							case Renamed(to): // Renamed value
								ed.renameValue(vDiff.valueId, to);
						}

				case Added: // New enum
					var ed = project.defs.createEnumDef(relSourcePath);
					ed.identifier = eDiff.enumId;
					for(v in eDiff.valueDiffs) {
						var ev = ed.addValue(v.valueId);
						if( v.data.color!=null )
							ev.color = v.data.color;
						if( v.data.tileRect!=null )
							ev.tileRect = v.data.tileRect;
					}

				case Removed: // Lost enum
					var ed = project.defs.getEnumDef(eDiff.enumId);
					project.defs.removeEnumDef(ed);

				case Renamed(to): // Renamed enum
					var ed = project.defs.getEnumDef(eDiff.enumId);
					ed.identifier = to;
			}

			// Update misc enumDef props
			var ed = project.defs.getEnumDef(eDiff.enumId);
			if( ed!=null ) {
				if( eDiff.newTilesetUid!=-1 )
					ed.iconTilesetUid = eDiff.newTilesetUid;
			}
		}
	}

}