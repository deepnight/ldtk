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
			client.ge.emit(EnumDefAdded);
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
				new ui.LastChance( L.t._("Enum deleted"), project.toJson() );
				project.defs.removeEnumDef(curEnum);
				client.ge.emit(EnumDefRemoved);
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
				selectEnum( project.defs.enums[0] );

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
			client.ge.emit(EnumDefSorted);
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

		var i = Input.linkToHtmlInput( curEnum.identifier, jForm.find("[name=eName]") );
		i.validityCheck = function(v) {
			return project.defs.isEnumIdentifierUnique(v);
		}
		i.linkEvent(EnumDefChanged);

		var jList = jForm.find("ul.enumValues");
		jList.empty();
		var xml = jForm.find("xml").clone().children();
		for(v in curEnum.values) {
			var li = new J("<li/>");
			li.appendTo(jList);
			li.append( xml.clone() );

			var i = new form.input.StringInput(li.find(".name"),
				function() return v,
				function(newV) {
					if( curEnum.renameValue(v, newV) ) {
						project.iterateAllFieldInstances(F_Enum(curEnum.uid), function(fi) {
							if( fi.getEnumValue()==v )
								fi.parseValue(newV);
						});
					}
					else
						N.invalidIdentifier(v);
				}
			);
			i.linkEvent(EnumDefChanged);

			li.find(".delete").click( function(ev) {
				new ui.modal.dialog.Confirm(ev.getThis(), Lang.t._("Warning! This operation will affect any Entity using this Enum in ALL LEVELS!"), function() {
					project.iterateAllFieldInstances(F_Enum(curEnum.uid), function(fi) {
						if( fi.getEnumValue()==v )
							fi.parseValue(null);
					});
					curEnum.values.remove(v);
					client.ge.emit(EnumDefChanged);
				});
			});
		}

		jForm.find(".createEnumValue").click( function(_) {
			var uid = 0;
			while( !curEnum.addValue(curEnum.identifier+uid) )
				uid++;
			client.ge.emit(EnumDefChanged);
			jContent.find("ul.enumValues li:last input[type=text]").select();
		});

		// Make fields list sortable
		JsTools.makeSortable(".window ul.enumValues", function(from, to) {
			var v = curEnum.values.splice(from,1)[0];
			curEnum.values.insert(to, v);
			client.ge.emit(EnumDefChanged);
		});
	}
}
