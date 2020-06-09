package ui.modal;

class EditEntityDefs extends ui.Modal {
	var jEntityList(get,never) : js.jquery.JQuery; inline function get_jEntityList() return jWin.find(".entityList ul");
	var jFieldList(get,never) : js.jquery.JQuery; inline function get_jFieldList() return jWin.find(".fieldList ul");

	var jAllForms(get,never) : js.jquery.JQuery; inline function get_jAllForms() return jWin.find(".formsWrapper");
	var jEntityForm(get,never) : js.jquery.JQuery; inline function get_jEntityForm() return jWin.find("ul.form.entityDef");
	var jFieldForm(get,never) : js.jquery.JQuery; inline function get_jFieldForm() return jWin.find(".fields ul.form");
	var jPreview(get,never) : js.jquery.JQuery; inline function get_jPreview() return jWin.find(".previewWrapper");

	var curEntity : Null<EntityDef>;
	var curField : Null<FieldDef>;

	public function new() {
		super();

		loadTemplate( "editEntityDefs", "defEditor entityDefs" );
		linkToButton("button.editEntities");

		// Create entity
		jWin.find(".entityList button.create").click( function(_) {
			var ed = project.createEntityDef();
			selectEntity(ed);
			// client.ge.emit(LayerDefChanged);
			jEntityForm.find("input").first().focus().select();
		});

		// Delete entity
		jWin.find(".entityList button.delete").click( function(ev) {
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
				JsTools.createFieldTypeIcon(type, b);
				b.click( function(_) {
					_create(type);
					w.close();
				});
			}
		});

		// Delete field
		jWin.find(".fields button.delete").click( function(_) {
			if( curField==null ) {
				N.error("No field selected.");
				return;
			}
			curEntity.removeField(project, curField);
			client.ge.emit(EntityFieldChanged);
			selectField( curEntity.fieldDefs[0] );
		});

		selectEntity(project.entityDefs[0]);
	}

	override function onGlobalEvent(e:GlobalEvent) {
		super.onGlobalEvent(e);
		switch e {
			case ProjectChanged: close();

			case LayerDefChanged:
			case LayerDefSorted:
			case LayerInstanceChanged:

			case EntityDefChanged:
				updatePreview();
				updateEntityForm();
				updateLists();

			case EntityDefSorted, EntityFieldSorted:
				updateLists();

			case EntityFieldChanged:
				updateLists();
				updateFieldForm();
		}
	}

	function selectEntity(ed:Null<EntityDef>) {
		curEntity = ed;
		curField = ed==null ? null : ed.fieldDefs[0];
		updatePreview();
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

		// Max per level
		var i = Input.linkToHtmlInput(curEntity.maxPerLevel, jEntityForm.find("input[name='maxPerLevel']") );
		i.setBounds(0,1024);
		i.onChange = client.ge.emit.bind(EntityDefChanged);

		// Pivot
		var jPivots = jEntityForm.find(".pivot");
		jPivots.empty();
		var p = JsTools.createPivotEditor(curEntity.pivotX, curEntity.pivotY, curEntity.color, function(x,y) {
			curEntity.pivotX = x;
			curEntity.pivotY = y;
			client.ge.emit(EntityDefChanged);
		});
		jPivots.append(p);
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

		jFieldForm.find(".type").empty().append( Std.string(L.getFieldType(curField.type)) );
		#if debug
		jFieldForm.find(".type").append("<p>"+StringTools.htmlEscape(curField.toString())+"</p>");
		#end

		var i = Input.linkToHtmlInput( curField.name, jFieldForm.find("input[name=name]") );
		i.onChange = client.ge.emit.bind(EntityFieldChanged);

		// Default value
		switch curField.type {
			case F_Int, F_Float, F_String:
				var defInput = jFieldForm.find("input[name=fDef]");
				if( curField.defaultOverride != null )
					defInput.val( Std.string( curField.getUntypedDefault() ) );
				else
					defInput.val("");

				if( curField.type==F_String && !curField.canBeNull )
					defInput.attr("placeholder", "(empty string)");
				else if( curField.canBeNull )
					defInput.attr("placeholder", "(null)");
				else
					defInput.attr("placeholder", switch curField.type {
						case F_Int: Std.string( curField.iClamp(0) );
						case F_Float: Std.string( curField.fClamp(0) );
						case F_Bool: "false";
						case F_String: "";
					});

				defInput.change( function(ev) {
					curField.setDefault( defInput.val() );
					client.ge.emit(EntityFieldChanged);
					defInput.val( curField.defaultOverride==null ? "" : Std.string(curField.getUntypedDefault()) );
				});

			case F_Bool:
				var defInput = jFieldForm.find("input[name=bDef]");
				defInput.prop("checked", curField.getBoolDefault());
				defInput.change( function(ev) {
					var checked = defInput.prop("checked") == true;
					curField.setDefault( Std.string(checked) );
					client.ge.emit(EntityFieldChanged);
				});
		}

		// Nullable
		var i = Input.linkToHtmlInput( curField.canBeNull, jFieldForm.find("input[name=canBeNull]") );
		i.onChange = client.ge.emit.bind(EntityFieldChanged);

		// Min
		var input = jFieldForm.find("input[name=min]");
		input.val( curField.min==null ? "" : curField.min );
		input.change( function(ev) {
			curField.setMin( input.val() );
			client.ge.emit(EntityFieldChanged);
		});

		// Max
		var input = jFieldForm.find("input[name=max]");
		input.val( curField.max==null ? "" : curField.max );
		input.change( function(ev) {
			curField.setMax( input.val() );
			client.ge.emit(EntityFieldChanged);
		});
	}


	function updateLists() {
		jEntityList.empty();
		jFieldList.empty();

		// Entities
		for(ed in project.entityDefs) {
			var elem = new J("<li/>");
			jEntityList.append(elem);
			elem.addClass("iconLeft");

			var preview = JsTools.createEntityPreview(ed, 32);
			preview.appendTo(elem);

			elem.append('<span class="name">'+ed.name+'</span>');
			if( curEntity==ed )
				elem.addClass("active");

			elem.click( function(_) selectEntity(ed) );
		}

		// Make layer list sortable
		JsTools.makeSortable(".window .entityList ul", function(from, to) {
			var moved = project.sortEntityDef(from,to);
			selectEntity(moved);
			client.ge.emit(EntityDefSorted);
		});

		// Fields
		if( curEntity!=null ) {
			for(f in curEntity.fieldDefs) {
				var li = new J("<li/>");
				li.appendTo(jFieldList);
				li.append('<span class="name">'+f.name+'</span>');
				if( curField==f )
					li.addClass("active");

				var sub = new J('<span class="sub"></span>');
				sub.appendTo(li);
				sub.text( f.getDescription() );

				li.click( function(_) selectField(f) );
			}
		}

		// Make fields list sortable
		JsTools.makeSortable(".window .fieldList ul", function(from, to) {
			var moved = curEntity.sortField(from,to);
			selectField(moved);
			client.ge.emit(EntityFieldSorted);
		});
	}


	function updatePreview() {
		if( curEntity==null )
			return;

		jPreview.children(".entityPreview").remove();
		jPreview.append( JsTools.createEntityPreview(curEntity) );
	}
}
