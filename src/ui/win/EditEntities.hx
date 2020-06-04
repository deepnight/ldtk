package ui.win;

class EditEntities extends ui.Window {
	var jEntityList : js.jquery.JQuery;
	var jFieldList : js.jquery.JQuery;

	var jAllForms : js.jquery.JQuery;
	var jEntityForm : js.jquery.JQuery;
	var jFieldForm : js.jquery.JQuery;

	var curEntity : Null<EntityDef>;
	var curField : Null<FieldDef>;

	public function new() {
		super();

		loadTemplate( hxd.Res.tpl.editEntities, "defEditor entityDefs" );
		jEntityList = jWin.find(".mainList ul");
		jFieldList = jWin.find(".fieldList ul");

		jAllForms = jWin.find(".formsWrapper");
		jEntityForm = jWin.find("ul.form.entityDef");
		jFieldForm = jWin.find(".fields ul.form");

		// Create entity
		jWin.find(".mainList button.create").click( function(_) {
			var ed = project.createEntityDef();
			selectEntity(ed);
			// client.ge.emit(LayerDefChanged);
			jEntityForm.find("input").first().focus().select();
		});

		// Delete entity
		jWin.find(".mainList button.delete").click( function(ev) {
			if( curEntity==null ) {
				N.error("No entity selected.");
				return;
			}
			project.removeEntityDef(curEntity);
			client.ge.emit(EntityDefChanged);
			if( project.entityDefs.length>0 )
				selectEntity(project.entityDefs[0]);
			else
				selectEntity(null);
		});

		// Create field
		jWin.find(".fields button.create").click( function(ev) {
			function _create(type:FieldType) {
				var f = curEntity.createField(project, type);
				client.ge.emit(EntityFieldChanged);
				selectField(f);
				jFieldForm.find("input:first").focus().select();
			}

			// Type picker
			var w = new ui.Dialog(ev.getThis(),"fieldTypes");
			for(k in FieldType.getConstructors()) {
				var type = FieldType.createByName(k);
				var b = new J("<button/>");
				w.jContent.append(b);
				b.addClass("fieldType");
				b.addClass(k);
				b.click( function(_) {
					_create(type);
					w.close();
				});
				b.text( L.getFieldTypeShortName(type) );
				b.append('<em>'+L.getFieldType(type)+'</em>');
			}
		});

		// Delete field
		jWin.find(".fields button.delete").click( function(_) {
			N.notImplemented();
		});

		selectEntity(project.entityDefs[0]);
	}

	override function onGlobalEvent(e:GlobalEvent) {
		super.onGlobalEvent(e);
		switch e {
			case LayerDefChanged:
			case LayerDefSorted:
			case LayerContentChanged:

			case EntityDefChanged:
				updateEntityForm();
				updateLists();

			case EntityDefSorted:
				updateLists();

			case EntityFieldChanged:
				updateLists();
				updateFieldForm();
		}
	}

	function selectEntity(ed:Null<EntityDef>) {
		curEntity = ed;
		curField = ed==null ? null : ed.fieldDefs[0];
		updateEntityForm();
		updateFieldForm();
		updateLists();
	}

	function selectField(fd:FieldDef) {
		curField = fd;
		updateFieldForm();
		updateLists();
	}


	function updateEntityForm() {
		jEntityForm.find("*").off(); // cleanup event listeners

		if( curEntity==null ) {
			jAllForms.css("visibility","hidden");
			return;
		}
		else
			jAllForms.css("visibility","visible");


		// Name
		var i = Input.linkToHtmlInput(curEntity.name, jEntityForm.find("input[name='name']") );
		i.validityCheck = project.isEntityNameValid;
		i.onChange = function() {
			client.ge.emit(EntityDefChanged);
		};

		// Dimensions
		var i = Input.linkToHtmlInput( curEntity.width, jEntityForm.find("input[name='width']") );
		i.setBounds(1,256);
		i.onChange = client.ge.emit.bind(EntityDefChanged);

		var i = Input.linkToHtmlInput( curEntity.height, jEntityForm.find("input[name='height']") );
		i.setBounds(1,256);
		i.onChange = client.ge.emit.bind(EntityDefChanged);

		// Color
		var col = jEntityForm.find("input[name=color]");
		col.val( C.intToHex(curEntity.color) );
		col.change( function(ev) {
			curEntity.color = C.hexToInt( col.val() );
			client.ge.emit(EntityDefChanged);
			updateEntityForm();
		});

		// 	new ui.Confirm(ev.getThis(), "If you delete this layer, it will be deleted in all levels as well. Are you sure?", function() {
		// 		project.removeLayerDef(ld);
		// 		select(project.layerDefs[0]);
		// 		client.ge.emit(LayerDefChanged);
		// 	});
		// });
	}


	function updateFieldForm() {
		jFieldForm.find("*").off(); // cleanup events

		if( curField==null ) {
			jFieldForm.css("visibility","hidden");
			return;
		}
		else
			jFieldForm.css("visibility","visible");

		// Set form class
		for(k in Type.getEnumConstructs(FieldType))
			jFieldForm.removeClass("type-"+k);
		jFieldForm.addClass("type-"+curField.type);

		jFieldForm.find(".type").text( L.getFieldType(curField.type) );

		var i = Input.linkToHtmlInput( curField.name, jFieldForm.find("input[name=name]") );
		i.onChange = client.ge.emit.bind(EntityFieldChanged);

		// Default value
		var defInput = jFieldForm.find("input[name=def]");
		if( curField.defaultOverride != null )
			defInput.val( curField.defaultOverride );
		else
			defInput.val("");

		if( curField.type==F_String && !curField.canBeNull )
			defInput.attr("placeholder", "(empty string)");
		else if( curField.canBeNull )
			defInput.attr("placeholder", "(null)");
		else
			defInput.attr("placeholder", switch curField.type {
				case F_Int: "0";
				case F_Float: "0";
				case F_String: "";
			});

		defInput.change( function(ev) {
			curField.setDefault( defInput.val() );
			client.ge.emit(EntityFieldChanged);
			defInput.val(curField.defaultOverride==null ? "" : curField.defaultOverride);
		});


		// Nullable
		var i = Input.linkToHtmlInput( curField.canBeNull, jFieldForm.find("input[name=canBeNull]") );
		i.onChange = client.ge.emit.bind(EntityFieldChanged);
	}


	function updateLists() {
		jEntityList.empty();
		jFieldList.empty();

		// Entities
		for(ed in project.entityDefs) {
			var elem = new J("<li/>");
			jEntityList.append(elem);
			elem.append('<span class="name">'+ed.name+'</span>');
			if( curEntity==ed )
				elem.addClass("active");

			elem.click( function(_) selectEntity(ed) );
		}

		// Make layer list sortable
		JsTools.makeSortable(".window .mainList ul", function(from, to) {
			var moved = project.sortEntityDef(from,to);
			selectEntity(moved);
			client.ge.emit(EntityDefSorted);
		});

		// Fields
		if( curEntity!=null ) {
			for(f in curEntity.fieldDefs) {
				var elem = new J("<li/>");
				jFieldList.append(elem);
				elem.append('<span class="name">'+f.name+'</span>');
				if( curField==f )
					elem.addClass("active");

				elem.click( function(_) selectField(f) );
			}
		}

		// Make fields list sortable
		JsTools.makeSortable(".window .fieldList ul", function(from, to) {
			var moved = curEntity.sortField(from,to);
			selectField(moved);
			client.ge.emit(EntityDefSorted);
		});
	}
}
