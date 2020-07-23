package ui.modal.panel;

class EditEnums extends ui.modal.Panel {
	var curEnum : Null<led.def.EnumDef>;

	public function new() {
		super();

		loadTemplate( "editEnums", "editEnums" );
		linkToButton("button.editEnums");

		// Add enum
		jContent.find("button.createEnum").click( function(_) {
			var ed = project.defs.createEnumDef();
			editor.ge.emit(EnumDefAdded);
			selectEnum(ed);
			jContent.find("ul.enumForm input:first").focus();
		});

		// Delete enum
		jContent.find("button.deleteEnum").click( function(ev) {
			if( curEnum==null ) {
				N.error(L.t._("No enum selected."));
				return;
			}

			new ui.modal.dialog.Confirm(ev.getThis(), function() {
				new ui.LastChance( L.t._("Enum ::name:: deleted", { name: curEnum.identifier}), project );
				project.defs.removeEnumDef(curEnum);
				editor.ge.emit(EnumDefRemoved);
				selectEnum( project.defs.enums[0] );
			});
		});

		// Default enum selection
		if( project.defs.enums.length>0 )
			selectEnum( project.defs.enums[0] );

		updateEnumList();
		updateEnumForm();
	}

	override function onGlobalEvent(ge:GlobalEvent) {
		super.onGlobalEvent(ge);

		switch(ge) {
			case ProjectSelected:
				close();

			case _:
		}

		updateEnumList();
		updateEnumForm();
	}

	function selectEnum(ed:led.def.EnumDef) {
		curEnum = ed;
		updateEnumList();
		updateEnumForm();
	}

	function updateEnumList() {
		var jList = jContent.find(".enumList ul");
		jList.empty();

		for(ed in project.defs.enums) {
			var e = new J("<li/>");
			e.appendTo(jList);
			if( ed==curEnum )
				e.addClass("active");
			e.append('<span class="name">'+ed.identifier+'</span>');
			e.click( function(_) {
				selectEnum(ed);
			});
		}

		// Make list sortable
		JsTools.makeSortable(".window .enumList ul", function(from, to) {
			var moved = project.defs.sortEnumDef(from,to);
			selectEnum(moved);
			editor.ge.emit(EnumDefSorted);
		});
	}



	function updateEnumForm() {
		var jForm = jContent.find("ul.enumForm");
		jForm.find("*").off();

		if( curEnum==null ) {
			jForm.hide();
			return;
		}
		jForm.show();

		var i = Input.linkToHtmlInput( curEnum.identifier, jForm.find("[name=id]") );
		i.validityCheck = function(v) {
			return project.defs.isEnumIdentifierUnique(v);
		}
		i.linkEvent(EnumDefChanged);

		// Tilesets
		var jSelect = jForm.find("select#icons");
		jSelect.empty();
		if( curEnum.iconTilesetUid==null )
			jSelect.addClass("gray");
		else
			jSelect.removeClass("gray");

		var opt = new J('<option value="-1">-- Select a tileset --</option>');
		opt.appendTo(jSelect);

		for(td in project.defs.tilesets) {
			var opt = new J('<option value="${td.uid}"/>');
			opt.appendTo(jSelect);
			opt.text( td.identifier );
		}

		jSelect.val( curEnum.iconTilesetUid==null ? "-1" : Std.string(curEnum.iconTilesetUid) );
		jSelect.change( function(ev) {
			var tid = Std.parseInt( jSelect.val() );
			if( tid<0 )
				curEnum.iconTilesetUid = null;
			else
				curEnum.iconTilesetUid = tid;
			editor.ge.emit(EnumDefChanged);
			N.debug(jSelect.val());
			N.debug( Type.typeof(jSelect.val()) );
		});


		// Values
		var jList = jForm.find("ul.enumValues");
		jList.empty();
		var xml = jForm.find("xml").children();
		for(v in curEnum.values) {
			var li = new J("<li/>");
			li.appendTo(jList);
			li.append( xml.clone() );

			var i = new form.input.StringInput(li.find(".name"),
				function() return v.id,
				function(newV) {
					if( curEnum.renameValue(v.id, newV) ) {
						project.iterateAllFieldInstances(F_Enum(curEnum.uid), function(fi) {
							if( fi.getEnumValue()==v.id )
								fi.parseValue(newV);
						});
					}
					else
						N.invalidIdentifier(v.id);
				}
			);
			i.linkEvent(EnumDefChanged);

			// Remove value button
			li.find(".delete").click( function(ev) {
				new ui.modal.dialog.Confirm(ev.getThis(), Lang.t._("Warning! This operation will affect any Entity using this Enum in ALL LEVELS!"), function() {
					new LastChance(L.t._("Enum value ::name:: deleted", { name:curEnum.identifier+"."+v }), project);

					project.iterateAllFieldInstances(F_Enum(curEnum.uid), function(fi) {
						if( fi.getEnumValue()==v.id )
							fi.parseValue(null);
					});
					project.defs.removeEnumDefValue(curEnum, v.id);
					editor.ge.emit(EnumDefValueRemoved);
				});
			});
		}

		jForm.find(".createEnumValue").click( function(_) {
			var uid = 0;
			while( !curEnum.addValue(curEnum.identifier+uid) )
				uid++;
			editor.ge.emit(EnumDefChanged);
			jContent.find("ul.enumValues li:last input[type=text]").select();
		});

		// Make fields list sortable
		JsTools.makeSortable(".window ul.enumValues", function(from, to) {
			var v = curEnum.values.splice(from,1)[0];
			curEnum.values.insert(to, v);
			editor.ge.emit(EnumDefChanged);
		});
	}
}
