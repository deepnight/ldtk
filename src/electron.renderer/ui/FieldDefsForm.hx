package ui;

import data.def.FieldDef;

enum FieldParentType {
	FP_Entity(ed:data.def.EntityDef);
	FP_Level(level:data.Level);
}

class FieldDefsForm {
	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;
	var curWorld(get,never) : data.World; inline function get_curWorld() return Editor.ME.curWorld;

	var parentType : FieldParentType;
	public var jWrapper : js.jquery.JQuery;
	var jList(get,never) : js.jquery.JQuery; inline function get_jList() return jWrapper.find("ul.fieldList");
	var jForm(get,never) : js.jquery.JQuery; inline function get_jForm() return jWrapper.find("dl.form");
	var jButtons(get,never) : js.jquery.JQuery; inline function get_jButtons() return jList.siblings(".buttons");
	var fieldDefs : Array<FieldDef>;
	var curField : Null<FieldDef>;

	public function new(parentType:FieldParentType) {
		this.parentType = parentType;
		this.fieldDefs = [];

		jWrapper = new J('<div class="fieldDefsForm"/>');
		jWrapper.html( JsTools.getHtmlTemplate("fieldDefsForm", { parentType: switch parentType {
			case FP_Entity(_): "Entity";
			case FP_Level(_): "Level";
		}}) );

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


	inline function getParentName() {
		return switch parentType {
			case FP_Entity(ed): ed!=null ? ed.identifier : "Unknown entity";
			case FP_Level(l): l!=null ? l.identifier : "Unknown level";
		}
	}


	inline function isLevelField() {
		return getLevelParent()!=null;
	}
	inline function isEntityField() {
		return getEntityParent()!=null;
	}

	function getEntityParent() {
		return switch parentType {
			case FP_Entity(ed): ed;
			case FP_Level(level): null;
		}
	}

	function getLevelParent() {
		return switch parentType {
			case FP_Entity(ed): null;
			case FP_Level(level): level;
		}
	}

	public function hide() {
		jWrapper.css({ visibility: "hidden" });
	}


	public function useFields(parent:FieldParentType, fields:Array<FieldDef>) {
		parentType = parent;
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

		updateForm();
	}

	function onCreateField(anchor:js.jquery.JQuery, isArray:Bool) {
		var w = new ui.modal.Dialog(anchor,"fieldTypes");

		function _create(ev:js.jquery.Event, type:ldtk.Json.FieldType) {
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
					var tagGroups = project.defs.groupUsingTags(project.defs.enums, ed->ed.tags);
					if( tagGroups.length<=1 )
						ctx.addTitle(L.t._("Pick an existing enum"));
					for(group in tagGroups) {
						if( tagGroups.length>1 )
							ctx.addTitle( group.tag==null ? L._Untagged() : L.untranslated(group.tag) );
						for(ed in group.all) {
							ctx.addAction({
								label: L.untranslated(ed.identifier),
								cb: ()->_create(ev, F_Enum(ed.uid)),
							});
						}
					}

					for(ext in project.defs.getGroupedExternalEnums().keyValueIterator()) {
						ctx.addTitle( L.untranslated( dn.FilePath.fromFile(ext.key).fileWithExt ) );
						for(ed in ext.value)
							ctx.addAction({
								label: L.untranslated(ed.identifier),
								cb: ()->_create(ev, F_Enum(ed.uid)),
							});
					}
					return;


				case _:
			}

			// Create field def
			var fd = new FieldDef(project, project.generateUniqueId_int(), type, isArray);
			var baseName = switch type {
				case F_Enum(enumDefUid): project.defs.getEnumDef(enumDefUid).identifier;
				case _: L.getFieldType(type);
			}
			if( isArray )
				baseName+"_array";
			fd.identifier = project.fixUniqueIdStr(baseName, Free, id->isFieldIdentifierUnique(id) );
			fieldDefs.push(fd);

			w.close();
			editor.ge.emit( FieldDefAdded(fd) );
			onAnyChange();
			selectField(fd);
			jForm.find("input:not([readonly]):first").focus().select();
		}

		// Type picker
		var types : Array<ldtk.Json.FieldType> = [
			F_Int, F_Float, F_Bool, F_String, F_Text, F_Color, F_Enum(null), F_Path, F_Tile,
		];
		if( isEntityField() ) {
			types.push(F_EntityRef);
			types.push(F_Point);
		}

		for(type in types) {
			var b = new J("<button/>");
			w.jContent.append(b);
			b.css({
				backgroundColor: FieldDef.getTypeColorHex(type, 0.62),
			});
			JsTools.createFieldTypeIcon(type, b);
			b.click( function(ev) {
				_create(ev,type);
			});
		}
	}


	public function selectField(fd:FieldDef) {
		curField = fd;
		updateList();
		updateForm();
	}


	function isFieldIdentifierUnique(id:String, ?except:FieldDef) {
		id = data.Project.cleanupIdentifier(id, Free);
		for(fd in fieldDefs)
			if( ( except==null || fd!=except ) && fd.identifier==id )
				return false;
		return true;
	}


	function duplicateFieldDef(fd:FieldDef) : FieldDef {
		return pasteFieldDef( data.Clipboard.createTemp(CFieldDef,fd.toJson()), fd );
	}


	function pasteFieldDef(c:data.Clipboard, ?after:FieldDef) : Null<FieldDef> {
		if( !c.is(CFieldDef) )
			return null;

		var json : ldtk.Json.FieldDefJson = c.getParsedJson();
		var copy = FieldDef.fromJson( project, json );
		copy.uid = project.generateUniqueId_int();
		copy.identifier = project.fixUniqueIdStr(json.identifier, Free, (id)->isFieldIdentifierUnique(id));
		if( after==null )
			fieldDefs.push(copy);
		else
			fieldDefs.insert( dn.Lib.getArrayIndex(after,fieldDefs)+1, copy );

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

		// List context menu
		ui.modal.ContextMenu.attachTo(jList, false, [
			{
				label: L._Paste(),
				cb: ()->{
					var copy = pasteFieldDef(App.ME.clipboard);
					editor.ge.emit(FieldDefAdded(copy));
					selectField(copy);
				},
				enable: ()->App.ME.clipboard.is(CFieldDef),
			},
		]);

		for(fd in fieldDefs) {
			var li = new J("<li/>");
			li.appendTo(jList);
			li.append('<span class="name">'+fd.identifier+'</span>');
			if( curField==fd )
				li.addClass("active");

			var fType = new J('<span class="type"></span>');
			fType.css({ backgroundColor: FieldDef.getTypeColorHex(fd.type, 0.6) });
			if( fd.isArray )
				fType.addClass("array");
			fType.appendTo(li);
			fType.text( L.getFieldTypeShortName(fd.type) );
			fType.css({
				borderColor: FieldDef.getTypeColorHex(fd.type, 1),
				color: FieldDef.getTypeColorHex(fd.type, 1.5),
			});


			ui.modal.ContextMenu.attachTo_new(li, (ctx:ui.modal.ContextMenu)->{
				ctx.addElement( Ctx_CopyPaster({
					elementName: "field",
					clipType: CFieldDef,
					copy: ()->App.ME.clipboard.copyData(CFieldDef, fd.toJson()),
					cut: ()->{
						App.ME.clipboard.copyData(CFieldDef, fd.toJson());
						deleteField(fd);
					},
					paste: ()->{
						var copy = pasteFieldDef(App.ME.clipboard, fd);
						editor.ge.emit(FieldDefAdded(copy));
						selectField(copy);
					},
					duplicate: ()->{
						var copy = duplicateFieldDef(fd);
						editor.ge.emit( FieldDefAdded(copy) );
						onAnyChange();
						selectField(copy);
					},
					delete: ()->deleteField(fd),
				}) );
			});

			li.click( function(_) selectField(fd) );
		}

		// Make fields list sortable
		JsTools.makeSortable(jList, function(ev) {
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
		}, { disableAnim:true });

		JsTools.parseComponents(jList);
	}


	function onAnyChange() {
		switch parentType {
			case FP_Entity(_):
				for( w in project.worlds )
				for( l in w.levels )
					editor.invalidateLevelCache(l);

			case FP_Level(_):
				for( w in project.worlds )
				for( l in w.levels )
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


	function getSmartColor() : dn.Col {
		return switch parentType {
			case FP_Entity(ed): ed.color;
			case FP_Level(level): level.getSmartColor(true);
		}
	}


	function updateForm() {
		ui.Tip.clear();
		jForm.find("*").off(); // cleanup events

		if( curField==null ) {
			jForm.css("visibility","hidden");
			return;
		}
		else
			jForm.css("visibility","visible");

		// Set form classes
		for(k in Type.getEnumConstructs(ldtk.Json.FieldType))
			jForm.removeClass("type-"+k);
		jForm.addClass("type-"+curField.type.getName());
		if( isLevelField() )
			jForm.addClass("type-level");
		else
			jForm.addClass("type-entity");

		if( curField.isArray ) {
			jForm.addClass("type-Array");
			jForm.removeClass("type-NotArray");
		}
		else {
			jForm.removeClass("type-Array");
			jForm.addClass("type-NotArray");
		}

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


		// Display mode
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
					case PointStar: curField.isArray ? L.t._("Show star of points") : L.t._("Show connected point");
					case PointPath: L.t._("Show path of points");
					case PointPathLoop: L.t._("Show path of points (looping)");
					case RadiusPx: L.t._("As a radius (pixels)");
					case RadiusGrid: L.t._("As a radius (grid-based)");
					case EntityTile: L.t._("Replace entity tile");
					case LevelTile: L.t._("Replace level render in world view");
					case ArrayCountWithLabel: L.t._("Show array length with label");
					case ArrayCountNoLabel: L.t._("Show array length only");
					case RefLinkBetweenCenters: L.t._("Reference link (using center coord)");
					case RefLinkBetweenPivots: L.t._("Reference link (using pivot coord)");
				}
			},

			function(k) {
				return switch k {
					case Hidden: true;
					case ValueOnly: curField.type!=F_Point;
					case NameAndValue: true;
					case ArrayCountNoLabel, ArrayCountWithLabel: curField.isArray;

					case EntityTile:
						isEntityField() && ( curField.isEnum() || curField.type==F_Tile );

					case LevelTile:
						isLevelField() && ( curField.isEnum() || curField.type==F_Tile );

					case RefLinkBetweenCenters, RefLinkBetweenPivots:
						curField.type==F_EntityRef;

					case Points, PointStar:
						curField.type==F_Point && isEntityField();

					case PointPath, PointPathLoop:
						curField.type==F_Point && curField.isArray && isEntityField();

					case RadiusPx, RadiusGrid:
						!curField.isArray && ( curField.type==F_Int || curField.type==F_Float ) && isEntityField();
				}
			}
		);
		i.onChange = onFieldChange;

		// Link style
		var i = new form.input.EnumSelect(
			jForm.find("select[name=editorLinkStyle]"),
			ldtk.Json.FieldLinkStyle,
			function() return curField.editorLinkStyle,
			function(v) return curField.editorLinkStyle = v,

			function(k) {
				return switch k {
					case ZigZag: L.t._("Zig-zag");
					case CurvedArrow: L.t._("Curved arrow");
					case StraightArrow: L.t._("Straight arrow");
					case ArrowsLine: L.t._("Line of arrows");
					case DashedLine: L.t._("Dashed line");
				}
			}
		);
		switch curField.editorDisplayMode {
			case PointStar, PointPath, PointPathLoop, RefLinkBetweenPivots, RefLinkBetweenCenters:
				i.jInput.show();
			case _:
				i.jInput.hide();
		}
		i.onChange = onFieldChange;


		// Display pos
		var i = new form.input.EnumSelect(
			jForm.find("select[name=editorDisplayPos]"),
			ldtk.Json.FieldDisplayPosition,
			()->curField.editorDisplayPos,
			(v)->curField.editorDisplayPos = v
		);
		i.onChange = onFieldChange;
		i.setVisibility( isEntityField() && switch curField.editorDisplayMode {
			case ValueOnly, NameAndValue, ArrayCountWithLabel, ArrayCountNoLabel: true;
			case Hidden, Points, PointStar, PointPath, PointPathLoop, RadiusPx, RadiusGrid, LevelTile, EntityTile, RefLinkBetweenPivots, RefLinkBetweenCenters: false;
		} );


		// Display scale
		var i = Input.linkToHtmlInput(curField.editorDisplayScale, jForm.find("#editorDisplayScale"));
		i.enablePercentageMode();
		i.nullReplacement = 1;
		i.setBounds(0.1, null);
		i.onChange = onFieldChange;
		i.setVisibility( switch curField.editorDisplayMode {
			case ValueOnly, NameAndValue, ArrayCountWithLabel, ArrayCountNoLabel: true;
			case LevelTile, EntityTile: false;
			case Hidden, Points, PointStar, PointPath, PointPathLoop, RadiusPx, RadiusGrid, RefLinkBetweenPivots, RefLinkBetweenCenters: false;
		});

		// Display color
		var jColor = jForm.find("#editorDisplayColor");
		JsTools.createColorButton(jColor, curField.editorDisplayColor, getSmartColor(), true, (c)->{
			curField.editorDisplayColor = c;
			onFieldChange();
		});
		switch curField.editorDisplayMode {
			case ValueOnly, NameAndValue, ArrayCountWithLabel, ArrayCountNoLabel,
				Points, PointStar, PointPath, PointPathLoop, RadiusPx, RadiusGrid, RefLinkBetweenPivots, RefLinkBetweenCenters: jColor.show();
			case Hidden, LevelTile, EntityTile: jColor.hide();
		}

		// Show in World mode (Level field only)
		var i = Input.linkToHtmlInput( curField.editorShowInWorld, jForm.find("input[name=editorShowInWorld]") );
		i.onChange = onFieldChange;
		i.setVisibility( isLevelField() );


		// Nullable
		var nullableInput = Input.linkToHtmlInput( curField.canBeNull, jForm.find("input[name=canBeNull]:visible") );
		if( nullableInput!=null ) {
			nullableInput.onChange = onFieldChange;
			nullableInput.enable();
		}

		// Always show
		var i = Input.linkToHtmlInput( curField.editorAlwaysShow, jForm.find("input[name=editorAlwaysShow]") );
		i.onChange = onFieldChange;
		i.setEnabled( curField.editorDisplayMode!=Hidden );

		// Tileset
		var jTilesetSelect = jForm.find("#tilesetUid");
		jTilesetSelect.empty();
		for(td in project.defs.tilesets) {
			var jOpt = new J('<option/>');
			jOpt.appendTo(jTilesetSelect);
			jOpt.text( td.identifier );
			jOpt.attr("value", td.uid);
		}
		if( curField.tilesetUid==null ) {
			// No tileset
			var jOpt = new J('<option>-- Pick a tileset --</option>');
			jOpt.prependTo(jTilesetSelect);
			jTilesetSelect.addClass("required");
			jOpt.attr("value",-1);
			jTilesetSelect.val(-1);
		}
		else {
			jTilesetSelect.removeClass("required");
			jTilesetSelect.val(curField.tilesetUid);
		}
		jTilesetSelect.change( _->{
			var uid = Std.parseInt( jTilesetSelect.val() );
			if( !M.isValidNumber(uid) || uid<0 )
				curField.tilesetUid = null;
			else
				curField.tilesetUid = uid;
			onFieldChange();
		});

		// Default tile
		var jDef = jForm.find(".defaultTile");
		jDef.find(".picker").empty();
		if( curField.tilesetUid!=null ) {
			jDef.show();
			var td = project.defs.getTilesetDef(curField.tilesetUid);
			if( td!=null ) {
				var def = curField.getTileRectDefaultObj();

				// Picker
				var jPicker = JsTools.createTileRectPicker(
					td.uid,
					def,
					(r)->{
						if( r==null )
							return;
						curField.setDefault('${r.x},${r.y},${r.w},${r.h}');
						curField.canBeNull = true;
						onFieldChange();
					}
				);
				jPicker.appendTo( jDef.find(".picker") );

				// Clear
				var jClear = jDef.find(".clear");
				if( def==null ) {
					nullableInput.enable();
					jClear.hide();
				}
				else {
					nullableInput.disable();
					jClear.show();
					jClear.click(_->{
						curField.setDefault(null);
						onFieldChange();
					});
				}
			}
		}
		else
			jDef.hide();

		// Refs
		var i = Input.linkToHtmlInput( curField.symmetricalRef, jForm.find("input[name=symmetricalRef]") );
		i.onChange = onFieldChange;
		i.setEnabled( curField.allowedRefs==OnlySame );

		var i = Input.linkToHtmlInput( curField.autoChainRef, jForm.find("input[name=autoChainRef]") );
		i.onChange = onFieldChange;

		var s = new form.input.EnumSelect(
			jForm.find("[name=allowedRefs]"),
			ldtk.Json.EntityReferenceTarget,
			false,
			()->curField.allowedRefs,
			(v)->{
				switch v {
					case Any, OnlyTags:
						curField.symmetricalRef = false; // not compatible

					case OnlySame:
					case OnlySpecificEntity:
						curField.allowedRefsEntityUid = getEntityParent().uid;
				}
				curField.allowedRefs = v;
				onFieldChange();
			},
			(v)->return switch v {
				case Any: L.t._("Any entity");
				case OnlyTags: L.t._("Any entity with one of the specified tags");
				case OnlySame: L.t._("Only another '::name::'s", { name:getParentName() });
				case OnlySpecificEntity: L.t._("Only a specific Entity");
			}
		);

		// Specific entity for refs
		var jSelect = jForm.find("[name=allowedRefsEntity]");
		jSelect.off().empty();
		if( curField.allowedRefs==OnlySpecificEntity ) {
			jSelect.show();
			for(ed in project.defs.entities) {
				var jOpt = new J('<option value="${ed.uid}"></option>');
				jOpt.appendTo(jSelect);
				jOpt.text(ed.identifier);
				var r = ed.getDefaultTile();
				if( r!=null )
					jOpt.attr("tile", haxe.Json.stringify(r));
			}
			jSelect.val( Std.string(curField.allowedRefsEntityUid) );
			jSelect.change(_->{
				var uid = Std.parseInt( jSelect.val() );
				curField.allowedRefsEntityUid = uid;
				onFieldChange();
			});
		}
		else
			jSelect.hide();

		// Specific tag for refs
		jForm.find(".allowedRefTags").empty().hide();
		if( curField.allowedRefs==OnlyTags ) {
			var tagEditor = new TagEditor(
				curField.allowedRefTags,
				()->onFieldChange(),
				()->project.defs.getAllTagsFrom(project.defs.entities, ed->ed.tags),
				false
			);
			jForm.find(".allowedRefTags").show().append( tagEditor.jEditor );
		}

		var i = Input.linkToHtmlInput( curField.allowOutOfLevelRef, jForm.find("input[name=allowOutOfLevelRef]") );
		i.onChange = onFieldChange;


		var i = Input.linkToHtmlInput( curField.editorTextPrefix, jForm.find("input[name=editorTextPrefix]") );
		i.onChange = onFieldChange;
		i.trimRight = false;

		var i = Input.linkToHtmlInput( curField.editorTextSuffix, jForm.find("input[name=editorTextSuffix]") );
		i.onChange = onFieldChange;
		i.trimLeft = false;


		var i = Input.linkToHtmlInput( curField.identifier, jForm.find("input[name=name]") );
		i.onChange = onFieldChange;
		i.fixValue = (v)->project.fixUniqueIdStr(v, Free, (id)->isFieldIdentifierUnique(id,curField));

		var i = Input.linkToHtmlInput( curField.doc, jForm.find("input[name=doc]") );
		i.onChange = onFieldChange;
		i.allowNull = true;

		// Default value
		switch curField.type {
			case F_Path:

			case F_EntityRef:

			case F_Tile:
				// TODO

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
						case F_EntityRef: "N/A";
						case F_Tile: "N/A";
					});

				defInput.change( function(ev) {
					curField.setDefault( defInput.val() );
					onFieldChange();
					defInput.val( curField.defaultOverride==null ? "" : Std.string(curField.getUntypedDefault()) );
				});

			case F_Enum(name):
				var ed = project.defs.getEnumDef(name);
				var jEnumDefault = jForm.find("[name=enumDef]");
				jEnumDefault.find("option").remove();
				jEnumDefault.removeClass("required");
				jEnumDefault.addClass("advanced");
				if( ed.iconTilesetUid!=null )
					jEnumDefault.attr("tdUid", ed.iconTilesetUid);

				// Add "no default value"
				if( !curField.canBeNull ) {
					var jOpt = new J('<option/>');
					jOpt.appendTo(jEnumDefault);
					jOpt.attr("value","");
					jOpt.text("-- No default value --");
					// jEnumDefault.addClass("required");
					if( curField.getEnumDefault()==null )
						jOpt.attr("selected","selected");
				}

				// Add "null"
				if( curField.canBeNull ) {
					var jOpt = new J('<option/>');
					jOpt.appendTo(jEnumDefault);
					jOpt.attr("value","");
					jOpt.text("-- null --");
					if( curField.canBeNull && curField.getEnumDefault()==null )
						jOpt.attr("selected","selected");
				}

				// Add all enum values
				for(v in ed.values) {
					var jOpt = new J('<option/>');
					jOpt.appendTo(jEnumDefault);
					jOpt.attr("value",v.id);
					if( v.tileRect!=null )
						jOpt.attr("tile", haxe.Json.stringify(v.tileRect));
					jOpt.text(v.id);
					if( curField.getEnumDefault()==v.id )
						jOpt.attr("selected","selected");
				}

				jEnumDefault.change( function(ev) {
					var v = jEnumDefault.val();
					if( v=="" )
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

		// Cut long values
		var i = Input.linkToHtmlInput( curField.editorCutLongValues, jForm.find("input#editorCutLongValues") );
		i.onChange = onFieldChange;

		// Use for smart color
		var i = Input.linkToHtmlInput( curField.useForSmartColor, jForm.find("input#useForSmartColor") );
		i.onChange = onFieldChange;

		// TOC export
		var i = Input.linkToHtmlInput( curField.exportToToc, jForm.find("input#exportToToc") );
		i.onChange = onFieldChange;
		i.setEnabled( isEntityField() && getEntityParent().exportToToc );

		// Searchable
		var i = Input.linkToHtmlInput( curField.searchable, jForm.find("input#searchable") );
		i.onChange = onFieldChange;
		i.setEnabled( isEntityField() );

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
