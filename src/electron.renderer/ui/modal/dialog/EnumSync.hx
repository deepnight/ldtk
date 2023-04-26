package ui.modal.dialog;

class EnumSync extends ui.modal.Dialog {
	// TODO close existing EnumSync windows

	var jConfirm : js.jquery.JQuery;

	public function new(diff:Map<String,EnumSyncDiff>, relSourcePath:String, onSync:Map<String,EnumSyncDiff>->Void) {
		super();

		var fileName = dn.FilePath.fromFile(relSourcePath).fileWithExt;
		loadTemplate("sync");
		jContent.find("h2 .file").text( fileName );

		// List possible "enum renaming" targets
		var enumRenameTargets = [];
		for(eDiff in diff)
			switch eDiff.change {
				case Added: enumRenameTargets.push(eDiff.enumId);
				case _:
			}

		// Print changes
		var changedEnums = new Map();
		var enumRenames : Map<String, { from:String, to:String }> = [];
		var valueRenames : Map<String, { enumId:String, from:String, to:String }> = new Map();
		var jEnumsList = jContent.find(".log");
		for(eDiff in diff) {
			changedEnums.set(eDiff.enumId, true);

			// Create enum jquery
			var jEnum = new J('<li class="enum"/>').appendTo(jEnumsList);
			jEnum.append('<div class="title">${eDiff.enumId}</div>');
			var jValuesList = new J('<ul class="values"/>');
			jValuesList.appendTo(jEnum);


			// Display enum changes
			switch eDiff.change {
				case null:
				case Renamed(to): // should not be in here before Sync validation

				case Added:
					jEnum.addClass("added");
					jEnum.find(".title").append('<div class="label added">Added</div>');


				case Removed:
					jEnum.addClass("removed");

					// Select to rename enum
					if( enumRenameTargets.length>0 ) {
						var jSelect = new J('<select/>');
						jSelect.appendTo( jEnum.find(".title") );
						jSelect.append('<option value="" class="def">-- Choose an action --</option>');
						for(v in enumRenameTargets)
							jSelect.append('<option value="rename:$v" to="$v">Rename enum ${eDiff.enumId} ➜ $v</option>');
						jSelect.append('<option value="remove" class="remove">REMOVE ${eDiff.enumId} ENUM FROM PROJECT</option>');
						jSelect.change( _->{
							var raw = Std.string( jSelect.val() );
							if( raw.indexOf("rename")==0 ) {
								// Plan enum renaming
								var to = raw.split(":")[1];
								enumRenames.set(eDiff.enumId, { from:eDiff.enumId, to:to });
							}
							else {
								// Plan enum removal
								enumRenames.remove(eDiff.enumId);
							}
							checkActions();
						});
					}

			}


			// List possible "value renaming" targets
			var valueRenameTargets = [];
			for(vDiff in eDiff.valueDiffs)
				switch vDiff.change {
					case Added: valueRenameTargets.push(vDiff.valueId);
					case Removed:
					case Renamed(to): // should not be in here before Sync validation
				}

			// List existing values
			var ed = project.defs.getEnumDef(eDiff.enumId);
			if( ed!=null ) {
				var limit = 4;
				for(v in ed.values)
					if( limit--<=0 ) {
						jValuesList.append('<li>(...)</li>');
						break;
					}
					else
						jValuesList.append('<li value="${v.id}">${v.id}</li>');
			}

			// List pending operations near enum values
			for(vDiff in eDiff.valueDiffs) {
				var jLi = new J('<li/>');
				jLi.prependTo(jValuesList);

				switch vDiff.change {
					case Renamed(to): // should not be in here before Sync validation

					case Added:
						jLi.append( vDiff.valueId );
						jLi.addClass("added");
						jLi.append('<div class="label added">Added</div>');

					case Removed:
						var cleanId = StringTools.replace(vDiff.valueId, '"', '');
						cleanId = StringTools.replace(cleanId, '\n', '');
						jLi.append( vDiff.valueId );
						jLi.addClass("removed");
						jValuesList.find('[value="$cleanId"]').hide();
						jLi.append('<div class="label removed">Removed</div>');

						// Select to rename value
						if( valueRenameTargets.length>0 ) {
							var jSelect = new J('<select/>');
							jSelect.appendTo(jLi);
							jSelect.append('<option value="" class="def">-- Choose an action --</option>');
							for(v in valueRenameTargets)
								jSelect.append('<option value="rename:$v" to="$v">Rename ${vDiff.valueId} ➜ $v</option>');
							jSelect.append('<option value="remove" class="remove">REMOVE ${eDiff.enumId}.${vDiff.valueId} FROM PROJECT</option>');
							jSelect.change( _->{
								var raw = Std.string( jSelect.val() );
								if( raw.indexOf("rename")==0 ) {
									// Plan renaming
									var to = raw.split(":")[1];
									valueRenames.set(eDiff.enumId+"."+vDiff.valueId, {
										enumId: eDiff.enumId,
										from: vDiff.valueId,
										to: to,
									});
								}
								else {
									// Plan removal
									valueRenames.remove(eDiff.enumId+"."+vDiff.valueId);
								}
								checkActions();
							});
						}
				}
			}
		}

		// Unchanged enums
		for(ed in project.defs.externalEnums)
			if( ed.externalRelPath==relSourcePath && !changedEnums.exists(ed.identifier) ) {
				var jLi = new J('<li class="enum unchanged">${ed.identifier} <div class="label unchanged">Unchanged</div> </li>');
				jLi.appendTo(jEnumsList);
			}

		// Validate sync
		jConfirm = addButton(L.t._("Apply these changes"), "confirm", function() {

			// Update diff with enum renames
			for(r in enumRenames) {
				var eDiff = diff.get(r.from);
				eDiff.valueDiffs = new Map();
				eDiff.change = Renamed(r.to);
				diff.remove(r.to);
			}

			// Update diff with value renames
			for(r in valueRenames) {
				var eDiff = diff.get(r.enumId);
				var vDiff = eDiff.valueDiffs.get(r.from).change = Renamed(r.to);
				eDiff.valueDiffs.remove(r.to);
			}

			onSync(diff);
			close();
		});

		addCancel();
		checkActions();
	}


	/** Refresh confirm button state **/
	function checkActions() {
		var ok = true;
		jContent.find("select").each( (i,e)->{
			var jSelect = new J(e);
			if( jSelect.val()=="" ) {
				ok = false;
				jSelect.addClass("required");
			}
			else
				jSelect.removeClass("required");
		});

		jConfirm.prop("disabled",!ok);
	}
}