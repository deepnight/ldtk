package ui;

import data.def.FieldDef;

class FieldDefsForm {
	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;

	public var jWrapper : js.jquery.JQuery;
	var jList(get,never) : js.jquery.JQuery; inline function get_jList() return jWrapper.find("ul.fieldList ");
	var jForm(get,never) : js.jquery.JQuery; inline function get_jForm() return jWrapper.find("ul.form");
	var jButtons(get,never) : js.jquery.JQuery; inline function get_jButtons() return jList.siblings(".buttons");
	var fieldDefs : Array<FieldDef>;
	var curField : Null<FieldDef>;

	var create : (type:data.DataTypes.FieldType, baseName:String, isArray:Bool)->FieldDef;
	var onCreate : FieldDef->Void;
	var onChange : FieldDef->Void;
	var onRemove : FieldDef->Void;
	var onSort : Int->Int->Void;


	public function new(create, onCreate, onChange, onRemove, onSort) {
		this.fieldDefs = [];
		this.create = create;
		this.onCreate = onCreate;
		this.onChange = onChange;
		this.onRemove = onRemove;
		this.onSort = onSort;

		jWrapper = new J('<div class="fieldDefsEditor"/>');
		jWrapper.html( JsTools.getHtmlTemplate("fieldDefsEditor") );

		// Create single field
		jButtons.find("button.createSingle").click( function(ev) {
			onCreateField(ev.getThis(), false);
		});

		// Create single field
		jButtons.find("button.createArray").click( function(ev) {
			onCreateField(ev.getThis(), true);
		});

		// Delete field
		jButtons.find("button.delete").click( function(ev) {
			if( curField==null ) {
				N.error("No field selected.");
				return;
			}

			new ui.modal.dialog.Confirm(
				ev.getThis(),
				Lang.t._("Confirm this action?"),
				true,
				function() {
					deleteField(curField);
				}
			);
		});
	}


	public function setFields(fields:Array<FieldDef>) {
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
		function _create(type:data.DataTypes.FieldType) {
			switch type {
				case F_Enum(null):
					// Enum picker
					var w = new ui.modal.Dialog(anchor, "enums");
					if( project.defs.enums.length==0 && project.defs.externalEnums.length==0 ) {
						w.jContent.append('<div class="warning">This project has no Enum: add one from the Enum panel.</div>');
					}

					for(ed in project.defs.enums) {
						var b = new J("<button/>");
						b.appendTo(w.jContent);
						b.text(ed.identifier);
						b.click( function(_) {
							_create(F_Enum(ed.uid));
							w.close();
						});
					}

					for(ed in project.defs.externalEnums) {
						var b = new J("<button/>");
						b.appendTo(w.jContent);
						b.append('<span class="id">${ed.identifier}</span>');

						var fileName = dn.FilePath.extractFileWithExt(ed.externalRelPath);
						b.append('<span class="source">$fileName</span>');

						b.click( function(_) {
							_create(F_Enum(ed.uid));
							w.close();
						});
					}
					return;


				case _:
			}

			var baseName = switch type {
				case F_Enum(enumDefUid): project.defs.getEnumDef(enumDefUid).identifier;
				case _: L.getFieldType(type);
			}
			var f = create(type, baseName, isArray);
			// var f = curEntity.createFieldDef(project, type, baseName, isArray);
			onCreate(f);
			selectField(f);
			jForm.find("input:not([readonly]):first").focus().select();
		}

		// Type picker
		var w = new ui.modal.Dialog(anchor,"fieldTypes");
		var types : Array<data.DataTypes.FieldType> = [
			F_Int, F_Float, F_Bool, F_String, F_Text, F_Enum(null), F_Color, F_Point, F_Path
		];
		for(type in types) {
			var b = new J("<button/>");
			w.jContent.append(b);
			JsTools.createFieldTypeIcon(type, b);
			b.click( function(ev) {
				_create(type);
				w.close();
			});
		}
	}


	function selectField(f:FieldDef) {
		curField = f;
		updateList();
		updateForm();
	}


	function isFieldIdentifierUnique(id:String) {
		id = data.Project.cleanupIdentifier(id,false);
		for(fd in fieldDefs)
			if( fd.identifier==id )
				return false;
		return true;
	}


	function duplicateField(fd:FieldDef) : FieldDef {
		var copy = FieldDef.fromJson( project, fd.toJson() );
		copy.uid = project.makeUniqId();

		var idx = 2;
		while( !isFieldIdentifierUnique(copy.identifier) )
			copy.identifier = fd.identifier+(idx++);

		fieldDefs.insert( dn.Lib.getArrayIndex(fd,fieldDefs)+1, copy );

		project.tidy();
		return copy;
	}


	function deleteField(fd:data.def.FieldDef) {
		new ui.LastChance( L.t._("Entity field ::name:: deleted", { name:fd.identifier }), project );
		fieldDefs.remove(fd);
		project.tidy();
		onRemove(fd);
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

			var sub = new J('<span class="sub"></span>');
			sub.appendTo(li);
			sub.text( fd.getShortDescription() );

			ui.modal.ContextMenu.addTo(li, [
				{
					label: L._Duplicate(),
					cb:()->{
						var copy = duplicateField(fd);
						onCreate(copy);
						selectField(copy);
					}
				},
				{ label: L._Delete(), cb:()->deleteField(fd) },
			]);

			li.click( function(_) selectField(fd) );
		}

		// Make fields list sortable
		JsTools.makeSortable(jList, function(ev) {
			onSort(ev.oldIndex, ev.newIndex);
		});
	}

	function updateForm() {
		jForm.find("*").off(); // cleanup events

		if( curField==null ) {
			jForm.css("visibility","hidden");
			return;
		}
		else
			jForm.css("visibility","visible");

		JsTools.parseComponents(jForm);

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
								()->onChange(curField)
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
					case PointStar: curField.isArray ? L.t._("Show star of points") : L.t._("Show point");
					case PointPath: L.t._("Show path of points");
					case RadiusPx: L.t._("As a radius (pixels)");
					case RadiusGrid: L.t._("As a radius (grid-based)");
					case EntityTile: L.t._("Replace entity tile");
				}
			},

			function(k) {
				return switch k {
					case Hidden: true;
					case ValueOnly: curField.type!=F_Point;
					case NameAndValue: true;
					case EntityTile: curField.isEnum();
					case PointStar: curField.type==F_Point;
					case PointPath: curField.type==F_Point && curField.isArray;
					case RadiusPx, RadiusGrid: !curField.isArray && ( curField.type==F_Int || curField.type==F_Float );
				}
			}
		);
		i.onChange = ()->onChange(curField);


		var i = new form.input.EnumSelect(
			jForm.find("select[name=editorDisplayPos]"),
			ldtk.Json.FieldDisplayPosition,
			function() return curField.editorDisplayPos,
			function(v) return curField.editorDisplayPos = v
		);
		switch curField.editorDisplayMode {
			case ValueOnly, NameAndValue:
				i.setEnabled(true);

			case Hidden, PointStar, PointPath, RadiusPx, RadiusGrid, EntityTile:
				i.setEnabled(false);
		}
		i.onChange = ()->onChange(curField);

		var i = Input.linkToHtmlInput( curField.editorAlwaysShow, jForm.find("input[name=editorAlwaysShow]") );
		i.onChange = ()->onChange(curField);
		i.setEnabled( curField.editorDisplayMode!=Hidden );


		var i = Input.linkToHtmlInput( curField.identifier, jForm.find("input[name=name]") );
		i.onChange = ()->onChange(curField);
		i.validityCheck = function(id) {
			return true; // HACK
			// return data.Project.isValidIdentifier(id) && curEntity.isFieldIdentifierUnique(id); // TODO
		}
		i.validityError = N.invalidIdentifier;

		// Default value
		switch curField.type {
			case F_Path:

			case F_Int, F_Float, F_String, F_Text, F_Point:
				var defInput = jForm.find("input[name=fDef]");
				if( curField.defaultOverride != null )
					defInput.val( Std.string( curField.getUntypedDefault() ) );
				else
					defInput.val("");

				if( ( curField.type==F_String || curField.type==F_Text ) && !curField.canBeNull )
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
					onChange(curField);
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
					onChange(curField);
				});

			case F_Color:
				var defInput = jForm.find("input[name=cDef]");
				defInput.val( C.intToHex(curField.getColorDefault()) );
				defInput.change( function(ev) {
					curField.setDefault( defInput.val() );
					onChange(curField);
				});

			case F_Bool:
				var defInput = jForm.find("input[name=bDef]");
				defInput.prop("checked", curField.getBoolDefault());
				defInput.change( function(ev) {
					var checked = defInput.prop("checked") == true;
					curField.setDefault( Std.string(checked) );
					onChange(curField);
				});
		}

		// Nullable
		var i = Input.linkToHtmlInput( curField.canBeNull, jForm.find("input[name=canBeNull]") );
		i.onChange = ()->onChange(curField);

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
			i.onChange = ()->onChange(curField);
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
			i.onChange = ()->onChange(curField);
		}

		// Min
		var input = jForm.find("input[name=min]");
		input.val( curField.min==null ? "" : curField.min );
		input.change( function(ev) {
			curField.setMin( input.val() );
			onChange(curField);
		});

		// Max
		var input = jForm.find("input[name=max]");
		input.val( curField.max==null ? "" : curField.max );
		input.change( function(ev) {
			curField.setMax( input.val() );
			onChange(curField);
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
				()->curField.textLangageMode,
				(e)->{
					curField.textLangageMode = e;
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
			onChange(curField);
		});

		// File select button
		var input = jForm.find("button[name=fDefFile]");
		input.click( function(ev) {
			dn.electron.Dialogs.open(curField.acceptFileTypes, project.getProjectDir(), function( absPath ) {
				var relPath = project.makeRelativeFilePath(absPath);
				var defInput = jForm.find("input[name=fDef]");
				defInput.val(relPath);
				curField.setDefault(relPath);
				onChange(curField);
			});
		});

		JsTools.parseComponents( jForm );
	}
}
