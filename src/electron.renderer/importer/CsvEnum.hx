package importer;

import data.Project;

class CsvEnum {

	public static function load(relPath:String, isSync:Bool) {
		var curProject = Editor.ME.project;
		var absPath = curProject.makeAbsoluteFilePath(relPath);
		var fileContent = JsTools.readFileString(absPath);

		// File not found
		if( fileContent==null ) {
			if( isSync )
				new ui.modal.dialog.LostFile(relPath, function(newAbs) {
					var newRel = curProject.makeRelativeFilePath(newAbs);
					if( curProject.remapExternEnums(relPath, newRel) )
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
			if( needConfirm )
				new ui.modal.dialog.Sync(log, relPath, copy);
			else if( log.length>0 ) {
				var fp = dn.FilePath.fromFile(relPath);
				N.success( L.t._("::file:: updated successfully.", { file:fp.fileWithExt }));
				Editor.ME.selectProject(copy);
			}
			else
				N.msg(L.t._("File is already up-to-date."));
		}
	}



	static function parse(fileContent:String) : Array<ParsedExternalEnum> {

		if( fileContent==null || fileContent.length==0 )
		{
			N.error("File Empty");
			return [];
		}

		// Search file for enums
		var externalEnums : Array<ParsedExternalEnum> = [];
		var headers :Array<String> = [];
		var columns :Array<Array<String>> = [];

		// Split file into lines array
		var lines =	fileContent.split("\r\n");

		for (i in 0...lines[0].split(",").length)
		{
			columns.push(new Array<String>());
		}

		// Parse the csv
		for(lineIndex in 0...lines.length){
			var values = lines[lineIndex].split(",");

			for (columnIndex in 0...values.length)
			{
				// Header info is on the first line
				if(lineIndex==0)
				{
					headers.push(values[columnIndex]);
				}
				else
				{
					columns[columnIndex].push(values[columnIndex]);
				}
			}
		}
		
		// Populate the externalEnums array with parsed data
		for (i in 0...headers.length)
		{
			externalEnums.push({
				enumId: headers[i],
				values: columns[i],
			});
		}

		return externalEnums;
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
							var ed = project.defs.getEnumDef(pe.enumId);
							log.push({
								op:Remove( project.isEnumValueUsed(ed,v.id) ),
								str:'Removed enum value: "${pe.enumId}.${v.id}"'
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
					log.push({ op:ChecksumUpdated, str:"Enum "+ed.identifier });
			}



		project.tidy();
		return log;
	}

}