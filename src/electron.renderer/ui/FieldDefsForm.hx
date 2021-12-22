package ui;

import data.def.FieldDef;

enum FieldParent {
	FP_Entity;
	FP_Level;
}

class FieldDefsForm {
	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;

	var fieldParent : FieldParent;
	public var jWrapper : js.jquery.JQuery;
	var jList(get,never) : js.jquery.JQuery; inline function get_jList() return jWrapper.find("ul.fieldList");
	var jForm(get,never) : js.jquery.JQuery; inline function get_jForm() return jWrapper.find("ul.form");
	var jButtons(get,never) : js.jquery.JQuery; inline function get_jButtons() return jList.siblings(".buttons");
	var fieldDefs : Array<FieldDef>;
	var curField : Null<FieldDef>;

	public function new(fieldParent:FieldParent) {
		this.fieldParent = fieldParent;
		this.fieldDefs = [];

		jWrapper = new J('<div class="fieldDefsForm"/>');
		var parentName = switch fieldParent {
			case FP_Entity: "Entity";
			case FP_Level: "Level";
		}
		jWrapper.html( JsTools.getHtmlTemplate("fieldDefsForm", { parent:parentName }) );

		// Create single field
		jButtons.find("button.createSingle").click( function(ev) {
			onCreateField(ev.getThis(), false);
		});

		// Create single field
		jButtons.find("button.createArray").click( function(ev) {
			onCreateField(ev.getThis(), true);
		});

		JsTools.parseComponents( jButtons );

		updateList();
		updateForm();
	}


	public function hide() {
		jWrapper.css({ visibility: "hidden" });
	}


	public function useFields(fields:Array<FieldDef>) {
		jWrapper.css({ visibility: "visible" });
		fieldDefs = fields;

		// Default field selection
		var found = false;
		if( curField!=null )
			for(f in fieldDefs)
				if( f.uid==curField.uid ) {
					found = true;
					break;
				}
		if( !found )
			selectField( fieldDefs[0] );
	}

	function onCreateField(anchor:js.jquery.JQuery, isArray:Bool) {
		var w = new ui.modal.Dialog(anchor,"fieldTypes");

		function _create(ev:js.jquery.Event, type:data.DataTypes.FieldType) {
			switch type {
				case F_Enum(null):
					if( project.defs.enums.length==0 && project.defs.externalEnums.length==0 ) {
						w.close();
						new ui.modal.dialog.Choice(
							L.t._("This project contains no Enum yet. You first need to create one from the Enum panel."),
							[
								{ label:L.t._("Open enum panel"), cb:()->new ui.modal.panel.EditEnumDefs() }
							]
						);
						return;
					}

					// Enum picker
					var ctx = new ui.modal.ContextMenu(ev);
					ctx.addTitle(L.t._("Pick an existing enum"));
					for(ed in project.defs.enums) {
						ctx.add({
							label: L.untranslated(ed.identifier),
							cb: ()->_create(ev, F_Enum(ed.uid)),
						});
					}

					for(ext in project.defs.getGroupedExternalEnums().keyValueIterator()) {
						ctx.addTitle( L.untranslated( dn.FilePath.fromFile(ext.key).fileWithExt ) );
						for(ed in ext.value)
							ctx.add({
								label: L.untranslated(ed.identifier),
								cb: ()->_create(ev, F_Enum(ed.uid)),
							});
					}
					return;


				case _:
			}

			// Create field def
			var fd = new FieldDef(project, project.makeUniqueIdInt(), type, isArray);
			var baseName = switch type {
				case F_Enum(enumDefUid): project.defs.getEnumDef(enumDefUid).identifier;
				case _: L.getFieldType(type);
			}
			if( isArray )
				baseName+"_array";
			fd.identifier = project.makeUniqueIdStr(baseName, false, id->isFieldIdentifierUnique(id) );
			fieldDefs.push(fd);

			w.close();
			editor.ge.emit( FieldDefAdded(fd) );
			onAnyChange();
			selectField(fd);
			jForm.find("input:not([readonly]):first").focus().select();
		}

		// Type picker
		var types : Array<data.DataTypes.FieldType> = [
			F_Int, F_Float, F_Bool, F_String, F_Text, F_Path, F_Color, F_Enum(null)
		];
		if( fieldParent==FP_Entity )
			types.push(F_Point);

		for(type in types) {
			var b = new J("<button/>");
			w.jContent.append(b);
			b.css({
				backgroundColor: FieldDef.getTypeColorHex(type, 0.55),
			});
			JsTools.createFieldTypeIcon(type, b);
			b.click( function(ev) {
				_create(ev,type);
			});
		}
	}


	function selectField(f:FieldDef) {
		curField = f;
		updateList();
		updateForm();
	}


	function isFieldIdentifierUnique(id:String, ?except:FieldDef) {
		id = data.Project.cleanupIdentifier(id,false);
		for(fd in fieldDefs)
			if( ( except==null || fd!=except ) && fd.identifier==id )
				return false;
		return true;
	}


	function duplicateField(fd:FieldDef) : FieldDef {
		var copy = FieldDef.fromJson( project, fd.toJson() );
		copy.uid = project.makeUniqueIdInt();
		copy.identifier = project.makeUniqueIdStr(fd.identifier, false, (id)->isFieldIdentifierUnique(id));
		fieldDefs.insert( dn.Lib.getArrayIndex(fd,fieldDefs)+1, copy );

		project.tidy();
		return copy;
	}


	function deleteField(fd:data.def.FieldDef) {
		new ui.LastChance( L.t._("Field ::name:: deleted", { name:fd.identifier }), project );
		fieldDefs.remove(fd);
		project.tidy();
		editor.ge.emit( FieldDefRemoved(fd) );
		onAnyChange();
		selectField( fieldDefs[0] );
	}


	function updateList() {
		jList.off().empty();

		for(fd in fieldDefs) {
			var li = new J("<li/>");
			li.appendTo(jList);
			li.append('<span class="name">'+fd.identifier+'</span>');
			if( curField==fd )
				li.addClass("active");

			var fType = new J('<span class="type"></span>');
			if( fd.isArray ) {
				fType.css({ backgroundColor: FieldDef.getTypeColorHex(fd.type, 0.4) });
				fType.addClass("array");
			}
			fType.appendTo(li);
			fType.text( L.getFieldTypeShortName(fd.type) );
			fType.css({
				borderColor: FieldDef.getTypeColorHex(fd.type, fd.isArray ? 1 : 0.4),
				color: FieldDef.getTypeColorHex(fd.type),
			});

			ui.modal.ContextMenu.addTo(li, [
				{
					label: L._Duplicate(),
					cb:()->{
						var copy = duplicateField(fd);
						editor.ge.emit( FieldDefAdded(fd) );
						onAnyChange();
						selectField(copy);
					}
				},
				{ label: L._Delete(), cb:()->deleteField(fd) },
			]);

			li.click( function(_) selectField(fd) );
		}

		// Make fields list sortable
		JsTools.makeSortable(jList, false, function(ev) {
			var from = ev.oldIndex;
			var to = ev.newIndex;

			if( from<0 || from>=fieldDefs.length || from==to )
				return;

			if( to<0 || to>=fieldDefs.length )
				return;

			var moved = fieldDefs.splice(from,1)[0];
			fieldDefs.insert(to, moved);

			selectField(moved);
			editor.ge.emit( FieldDefSorted );
			onAnyChange();
		});

		JsTools.parseComponents(jList);
	}


	function onAnyChange() {
		switch fieldParent {
			case FP_Entity:
				for( l in project.levels )
					editor.invalidateLevelCache(l);

			case FP_Level:
				for( l in project.levels )
					editor.invalidateLevelCache(l);
				editor.worldRender.invalidateAllLevelFields();
		}
	}


	function onFieldChange() {
		editor.ge.emit( FieldDefChanged(curField) );
		updateList();
		updateForm();
		onAnyChange();
	}


	function updateForm() {
		jForm.find("*").off(); // cleanup events

		if( curField==null ) {
			jForm.css("visibility","hidden");
			return;
		}
		else
			jForm.css("visibility","visible");

		// Set form classes
		for(k in Type.getEnumConstructs(data.DataTypes.FieldType))
			jForm.removeClass("type-"+k);
		jForm.addClass("type-"+curField.type.getName());

		if( curField.isArray )
			jForm.addClass("type-Array");
		else
			jForm.removeClass("type-Array");

		// Type desc
		jForm.find(".type").val( curField.getShortDescription() );

		// Type conversion
		jForm.find("button.convert").click( (ev)->{
			var convertors = FieldTypeConverter.getAllConvertors(curField);
			if( convertors.length==0 ) {
				// No convertor
				new ui.modal.dialog.Message(
					L.t._('Sorry, there\'s no conversion option available for the type "::name::".', { name:L.getFieldType(curField.type) })
				);
			}
			else {
				// Field convertor picker
				var w = new ui.modal.Dialog(ev.getThis(), "convertFieldType");
				for(c in convertors) {
					var toName = Lang.getFieldType(c.to!=null ? c.to : curField.type);
					var jButton = new J('<button class="dark"/>');
					if( c.displayName!=null )
						jButton.text(c.displayName);
					else if( c.to!=null )
						jButton.text('To '+L.getFieldType(c.to));
					else
						jButton.text('???');

					if( c.mode!=null )
						jButton.append(' (${c.mode})');

					jButton.appendTo(w.jContent);
					jButton.click( (_)->{
						function _convert() {
							w.close();
							misc.FieldTypeConverter.convert(
								project,
								curField,
								c,
								onFieldChange
							);
						}

						if( c.lossless )
							_convert();
						else
							new ui.modal.dialog.Confirm(
								L.t._("This conversion will TRANSFORM EXISTING VALUES because the target type isn't fully compatible with the previous one!\nSome data might be lost in the process because of this conversion.\nPlease make sure that you known what you're doing here."),
								true,
								_convert
							);
					});
				}
			}
		} );


		var i = new form.input.EnumSelect(
			jForm.find("select[name=editorDisplayMode]"),
			ldtk.Json.FieldDisplayMode,
			function() return curField.editorDisplayMode,
			function(v) return curField.editorDisplayMode = v,

			function(k) {
				return switch k {
					case Hidden: L.t._("Do not show");
					case ValueOnly: curField.isArray ? L.t._("Show values only") : L.t._("Show value only");
					case NameAndValue:
						curField.isArray
						? L.t._('Show "::name::=[...values...]"', { name:curField.identifier })
						: L.t._('Show "::name::=..."', { name:curField.identifier });
					case Points: curField.isArray ? L.t._("Show isolated points") : L.t._("Show isolated point");
					case PointStar: curField.isArray ? L.t._("Show star of points") : L.t._("Show point");
					case PointPath: L.t._("Show path of points");
					case PointPathLoop: L.t._("Show path of points (looping)");
					case RadiusPx: L.t._("As a radius (pixels)");
					case RadiusGrid: L.t._("As a radius (grid-based)");
					case EntityTile: L.t._("Replace entity tile");
					case ArrayCountWithLabel: L.t._("Show array length with label");
					case ArrayCountNoLabel: L.t._("Show array length only");
				}
			},

			function(k) {
				return switch k {
					case Hidden: true;
					case ValueOnly: curField.type!=F_Point;
					case NameAndValue: true;
					case ArrayCountNoLabel, ArrayCountWithLabel: curField.isArray;

					case EntityTile:
						curField.isEnum() && fieldParent==FP_Entity;

					case Points, PointStar:
						curField.type==F_Point && fieldParent==FP_Entity;

					case PointPath, PointPathLoop:
						curField.type==F_Point && curField.isArray && fieldParent==FP_Entity;

					case RadiusPx, RadiusGrid:
						!curField.isArray && ( curField.type==F_Int || curField.type==F_Float ) && fieldParent==FP_Entity;
				}
			}
		);
		i.onChange = onFieldChange;


		var i = new form.input.EnumSelect(
			jForm.find("select[name=editorDisplayPos]"),
			ldtk.Json.FieldDisplayPosition,
			()->curField.editorDisplayPos,
			(v)->curField.editorDisplayPos = v,
			(pos)->switch fieldParent {
				case FP_Entity: true;
				case FP_Level:
					switch pos {
						case Above: true;
						case Center: false;
						case Beneath: true;
					}
			}
		);
		switch curField.editorDisplayMode {
			case ValueOnly, NameAndValue, ArrayCountWithLabel, ArrayCountNoLabel:
				i.setEnabled(true);

			case Hidden, Points, PointStar, PointPath, PointPathLoop, RadiusPx, RadiusGrid, EntityTile:
				i.setEnabled(false);
		}
		i.onChange = onFieldChange;

		var i = Input.linkToHtmlInput( curField.editorAlwaysShow, jForm.find("input[name=editorAlwaysShow]") );
		i.onChange = onFieldChange;
		i.setEnabled( curField.editorDisplayMode!=Hidden );


		var i = Input.linkToHtmlInput( curField.editorTextPrefix, jForm.find("input[name=editorTextPrefix]") );
		i.onChange = onFieldChange;
		i.trimRight = false;

		var i = Input.linkToHtmlInput( curField.editorTextSuffix, jForm.find("input[name=editorTextSuffix]") );
		i.onChange = onFieldChange;
		i.trimLeft = false;


		var i = Input.linkToHtmlInput( curField.identifier, jForm.find("input[name=name]") );
		i.onChange = onFieldChange;
		i.fixValue = (v)->project.makeUniqueIdStr(v, false, (id)->isFieldIdentifierUnique(id,curField));

		// Default value
		switch curField.type {
			case F_Path:

			case F_Text:
				var defInput = jForm.find("div#fDefMultiLines");
				if( curField.defaultOverride != null ) {
					var str = curField.getStringDefault();
					if( str.length>256 )
						str = str.substr(0,256)+"[...]";
					defInput.text( str );
				}
				else
					defInput.text( curField.canBeNull ? "(null)" : "(empty string)" );

				defInput.click( ev->{
					new ui.modal.dialog.TextEditor(
						curField.getStringDefault(),
						curField.identifier,
						curField.textLanguageMode,
						(v)->{
							curField.setDefault(v);
							onFieldChange();
						}
					);
				});


			case F_Int, F_Float, F_String, F_Point:
				var defInput = jForm.find("input[name=fDef]");
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
						case F_String, F_Text, F_Path: "";
						case F_Point: "0"+Const.POINT_SEPARATOR+"0";
						case F_Bool, F_Color, F_Enum(_): "N/A";
					});

				defInput.change( function(ev) {
					curField.setDefault( defInput.val() );
					onFieldChange();
					defInput.val( curField.defaultOverride==null ? "" : Std.string(curField.getUntypedDefault()) );
				});

			case F_Enum(name):
				var ed = project.defs.getEnumDef(name);
				var enumDef = jForm.find("[name=enumDef]");
				enumDef.find("[value]").remove();
				if( curField.canBeNull ) {
					var opt = new J('<option/>');
					opt.appendTo(enumDef);
					opt.attr("value","");
					opt.text("-- null --");
					if( curField.getEnumDefault()==null )
						opt.attr("selected","selected");
				}
				for(v in ed.values) {
					var opt = new J('<option/>');
					opt.appendTo(enumDef);
					opt.attr("value",v.id);
					opt.text(v.id);
					if( curField.getEnumDefault()==v.id )
						opt.attr("selected","selected");
				}

				enumDef.change( function(ev) {
					var v = enumDef.val();
					if( v=="" && curField.canBeNull )
						curField.setDefault(null);
					else if( v!="" )
						curField.setDefault(v);
					onFieldChange();
				});

			case F_Color:
				var defInput = jForm.find("input[name=cDef]");
				defInput.val( C.intToHex(curField.getColorDefault()) );
				defInput.change( function(ev) {
					curField.setDefault( defInput.val() );
					onFieldChange();
				});

			case F_Bool:
				var defInput = jForm.find("input[name=bDef]");
				defInput.prop("checked", curField.getBoolDefault());
				defInput.change( function(ev) {
					var checked = defInput.prop("checked") == true;
					curField.setDefault( Std.string(checked) );
					onFieldChange();
				});
		}

		// Nullable
		var i = Input.linkToHtmlInput( curField.canBeNull, jForm.find("input[name=canBeNull]") );
		i.onChange = onFieldChange;

		// Cut long values
		var i = Input.linkToHtmlInput( curField.editorCutLongValues, jForm.find("input#editorCutLongValues") );
		i.onChange = onFieldChange;

		// Use for smart color
		var i = Input.linkToHtmlInput( curField.useForSmartColor, jForm.find("input#useForSmartColor") );
		i.onChange = onFieldChange;

		// Multi-lines
		// if( curField.isString() ) {
		// 	var i = new form.input.BoolInput(
		// 		jForm.find("input[name=multiLines]"),
		// 		()->switch curField.type {
		// 			case F_String(multilines): multilines;
		// 			case _: false;
		// 		},
		// 		(v)->{
		// 			curField.convertType( F_String(v) );
		// 		}
		// 	);
		// 	i.linkEvent( EntityFieldDefChanged(curEntity) );
		// }

		// Array size constraints
		if( curField.isArray ) {
			// Min
			var i = new form.input.IntInput(
				jForm.find("input[name=arrayMinLength]"),
				function() return curField.arrayMinLength,
				function(v) {
					curField.arrayMinLength = v<=0 ? null : v;
					if( curField.arrayMinLength!=null && curField.arrayMaxLength!=null )
						curField.arrayMaxLength = M.imax( curField.arrayMaxLength, curField.arrayMinLength );
				}
			);
			i.setBounds(0, 99999);
			i.onChange = onFieldChange;
			// Max
			var i = new form.input.IntInput(
				jForm.find("input[name=arrayMaxLength]"),
				function() return curField.arrayMaxLength,
				function(v) {
					curField.arrayMaxLength = v<=0 ? null : v;
					if( curField.arrayMinLength!=null && curField.arrayMaxLength!=null )
						curField.arrayMinLength = M.imin( curField.arrayMaxLength, curField.arrayMinLength );
				}
			);
			i.setBounds(0, 99999);
			i.onChange = onFieldChange;
		}

		// Min
		var input = jForm.find("input[name=min]");
		input.val( curField.min==null ? "" : curField.min );
		input.change( function(ev) {
			curField.setMin( input.val() );
			onFieldChange();
		});

		// Max
		var input = jForm.find("input[name=max]");
		input.val( curField.max==null ? "" : curField.max );
		input.change( function(ev) {
			curField.setMax( input.val() );
			onFieldChange();
		});

		// String regex
		var i = new form.input.StringInput(
			jForm.find("input#regex"),
			()->return curField.getRegexContent(),
			(s)-> {
				curField.setRegexContent(s);
			}
		);

		// Regex "i" flag
		var i = new form.input.BoolInput(
			jForm.find("input#flag_i"),
			()->curField.hasRegexFlag("i"),
			(v)->{
				curField.setRegexFlag("i",v);
			}
		);

		// Test regex
		if( curField.regex!=null ) {
			jForm.find(".testRegex").click( (_)->{
				electron.Shell.openExternal( "https://regex101.com/"
					+ "?regex="+curField.getRegexContent()
					+ "&flags="+curField.getRegexFlagsStr()
				);
			});
		}

		// Text language mode
		if( curField.type==F_Text ) {
			var i = new form.input.EnumSelect(
				jForm.find("#textLanguage"),
				ldtk.Json.TextLanguageMode,
				true,
				()->curField.textLanguageMode,
				(e)->{
					curField.textLanguageMode = e;
				},
				(e)->Lang.getTextLanguageMode(e)
			);
		}

		// Accept file types
		var input = jForm.find("input[name=acceptTypes]");
		if( curField.acceptFileTypes!=null )
			input.val( curField.acceptFileTypes.join("  ") );
		input.change( function(ev) {
			curField.setAcceptFileTypes( input.val() );
			onFieldChange();
		});

		// Finalize
		JsTools.parseComponents(jForm);
	}
}
