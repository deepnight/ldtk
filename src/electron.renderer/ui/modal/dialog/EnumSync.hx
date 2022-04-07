package ui.modal.dialog;

class EnumSync extends ui.modal.Dialog {
	// TODO close existing EnumSyncs

	var jConfirm : js.jquery.JQuery;

	public function new(ops:Array<EnumSyncOp>, relSourcePath:String, onSync:Array<EnumSyncOp>->Void) {
		super();

		var fileName = dn.FilePath.fromFile(relSourcePath).fileWithExt;
		loadTemplate("sync");
		jContent.find("h2 .file").text( fileName );

		// Warning
		jContent.find(".warning").hide();
		for(op in ops)
			switch op.type {
				case AddEnum(_):
				case AddValue(val):
				case DateUpdated:
				case Special:
				case RemoveEnum(used), RemoveValue(_,used):
					if( used )
						jContent.find(".warning").show();
			}

		// Hide safe notice
		if( jContent.find(".warning").is(":visible") )
			jContent.find(".safe").hide();

		// Group ops by enums
		var enumIds = [];
		var changedEnums = new Map();
		for(op in ops)
			if( !changedEnums.exists(op.enumId) ) {
				changedEnums.set(op.enumId, true);
				enumIds.push(op.enumId);
			}

		// Print changes
		var jEnumsList = jContent.find(".log");
		for(enumId in enumIds) {
			var jEnum = new J('<li class="enum"/>').appendTo(jEnumsList);
			jEnum.append('<div class="title">$enumId</div>');
			var jValuesList = new J('<ul class="values"/>');
			jValuesList.appendTo(jEnum);

			// List possible "rename value" targets
			var renameValues = [];
			for(op in ops) {
				if( op.enumId!=enumId )
					continue;

				switch op.type {
					case AddValue(val): renameValues.push(val);
					case _:
				}
			}

			// List existing values
			var ed = project.defs.getEnumDef(enumId);
			if( ed!=null ) {
				var limit = 5;
				for(v in ed.values)
					if( limit--<=0 ) {
						jValuesList.append('<li>(...)</li>');
						break;
					}
					else
						jValuesList.append('<li value="${v.id}">${v.id}</li>');

			}

			// List pending operations near enum values
			var opIdx = -1;
			for(op in ops) {
				opIdx++;
				var opIdx = opIdx;

				if( op.enumId!=enumId )
					continue;

				var jLi = new J('<li/>');
				jLi.appendTo(jValuesList);
				switch op.type {
					case DateUpdated:

					case AddEnum(values):
						jEnum.find(".title").append('<div class="label added">Added</div>');
						jEnum.addClass("added");
						jValuesList.empty();
						for(v in values)
							jValuesList.append('<li class="added">$v <div class="label added">Added</div></li>');

					case RemoveEnum(used):
						jEnum.find(".title").append('<div class="label removed">Removed</div>');
						jEnum.addClass("removed");

					case AddValue(val):
						jLi.append( val );
						jLi.addClass("added");
						jLi.append('<div class="label added">Added</div>');

					case Special: // Should not be there at init

					case RemoveValue(val, used):
						jLi.append( val );
						jLi.addClass("removed");
						jValuesList.find('[value="$val"]').hide();
						jLi.append('<div class="label removed">Removed</div>');

						// Select to rename value
						if( renameValues.length>0 ) {
							var initialOp = op;
							var jSelect = new J('<select/>');
							jSelect.appendTo(jLi);
							jSelect.append('<option value="">-- Choose an action --</option>');
							for(v in renameValues)
								jSelect.append('<option value="rename:$v" to="$v">Rename $val ➜ $v</option>');
							jSelect.append('<option value="remove">REMOVE FROM PROJECT</option>');
							jSelect.change( _->{
								checkActions();
								var raw = Std.string( jSelect.val() );
								if( raw.indexOf("rename")==0 ) {
									// Rename instance values
									ops[opIdx] = {
										type: Special,
										enumId: initialOp.enumId,
										cb: (p)->{
											p.iterateAllFieldInstances( (fi:data.inst.FieldInstance)->{
												if( fi.def.isEnum() && fi.def.getEnumDef().identifier==initialOp.enumId )
													fi.renameEnumValue(val, raw.split(":")[1]);
											});
											initialOp.cb(p); // still delete old value
										}
									}
								}
								else
									ops[opIdx] = initialOp; // back to initial operation
							});
						}
				}
			}
		}

		// Unchanged enums
		for(ed in project.defs.externalEnums)
			if( ed.externalRelPath==relSourcePath && !changedEnums.exists(ed.identifier) ) {
				var jLi = new J('<li class="enum unchanged">${ed.identifier}</li>');
				jLi.appendTo(jEnumsList);
			}

		// Buttons
		jConfirm = addButton(L.t._("Apply these changes"), "confirm", function() {
			onSync(ops);
			close();
		});

		addCancel();

		checkActions();
	}

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