package ui.modal.panel;

import data.DataTypes;

class EditEntityDefs extends ui.modal.Panel {
	static var LAST_ENTITY_ID = -1;

	var jEntityList(get,never) : js.jquery.JQuery; inline function get_jEntityList() return jContent.find(".entityList>ul");
	var jEntityForm(get,never) : js.jquery.JQuery; inline function get_jEntityForm() return jContent.find(".entityForm>dl.form");
	var jPreview(get,never) : js.jquery.JQuery; inline function get_jPreview() return jContent.find(".previewWrapper");

	var curEntity : Null<data.def.EntityDef>;
	var fieldsForm : FieldDefsForm;


	public function new(?editDef:data.def.EntityDef) {
		super();

		loadTemplate( "editEntityDefs", "defEditor entityDefs" );
		linkToButton("button.editEntities");

		function _createEntity() {
			var ed = project.defs.createEntityDef();
			selectEntity(ed);
			editor.ge.emit(EntityDefAdded);
			jEntityForm.find("input").first().focus().select();
			return ed;
		}

		// Create entity
		jEntityList.parent().find("button.create").click( _->_createEntity() );

		// Presets
		jEntityList.parent().find("button.presets").click( (ev)->{
			var ctx = new ContextMenu(ev);
			ctx.add({
				label: L.t._("Rectangle region"),
				cb: ()->{
					var ed = _createEntity();
					ed.identifier = project.fixUniqueIdStr("RectRegion", true, (s)->project.defs.isEntityIdentifierUnique(s));
					ed.hollow = true;
					ed.resizableX = true;
					ed.resizableY = true;
					ed.pivotX = ed.pivotY = 0;
					ed.tags.set("region");
					selectEntity(ed);
					editor.ge.emit( EntityDefChanged );
				}
			});
			ctx.add({
				label: L.t._("Circle region"),
				cb: ()->{
					var ed = _createEntity();
					ed.identifier = project.fixUniqueIdStr("CircleRegion", true, (s)->project.defs.isEntityIdentifierUnique(s));
					ed.renderMode = Ellipse;
					ed.hollow = true;
					ed.resizableX = true;
					ed.resizableY = true;
					ed.keepAspectRatio = true;
					ed.pivotX = ed.pivotY = 0.5;
					ed.tags.set("region");
					selectEntity(ed);
					editor.ge.emit( EntityDefChanged );
				}
			});
		});

		// Create fields editor
		fieldsForm = new ui.FieldDefsForm( FP_Entity );
		jContent.find("#fields").replaceWith( fieldsForm.jWrapper );


		// Select same entity as current client selection
		if( editDef!=null )
			selectEntity( editDef );
		else if( editor.curLayerDef!=null && editor.curLayerDef.type==Entities )
			selectEntity( project.defs.getEntityDef(editor.curTool.getSelectedValue()) );
		else if( LAST_ENTITY_ID>=0 && project.defs.getEntityDef(LAST_ENTITY_ID)!=null )
			selectEntity( project.defs.getEntityDef(LAST_ENTITY_ID) );
		else
			selectEntity(project.defs.entities[0]);
	}


	function deleteEntityDef(ed:data.def.EntityDef, bypassConfirm=false) {
		var isUsed = project.isEntityDefUsed(ed);
		if( isUsed && !bypassConfirm) {
			new ui.modal.dialog.Confirm(
				Lang.t._("WARNING! This entity is used in one or more levels. The corresponding instances will also be deleted!"),
				true,
				deleteEntityDef.bind(ed,true)
			);
			return;
		}
			// : Lang.t._("This entity is not used and can be safely removed."),

		new ui.LastChance( L.t._("Entity ::name:: deleted", { name:ed.identifier }), project );
		project.defs.removeEntityDef(ed);
		editor.ge.emit(EntityDefRemoved);
		if( project.defs.entities.length>0 )
			selectEntity(project.defs.entities[0]);
		else
			selectEntity(null);
	}

	override function onGlobalEvent(e:GlobalEvent) {
		super.onGlobalEvent(e);
		switch e {
			case ProjectSettingsChanged, LevelSettingsChanged(_), LevelSelected(_):
				close();

			case ProjectSelected:
				updatePreview();
				updateEntityForm();
				updateFieldsForm();
				updateEntityList();
				selectEntity(project.defs.entities[0]);

			case LayerInstanceRestoredFromHistory(li):
				updatePreview();
				updateEntityForm();
				updateFieldsForm();
				updateEntityList();

			case EntityDefChanged, EntityDefAdded, EntityDefRemoved:
				updatePreview();
				updateEntityForm();
				updateFieldsForm();
				updateEntityList();

			case EntityDefSorted, FieldDefSorted:
				updateEntityList();

			case FieldDefAdded(_), FieldDefRemoved(_), FieldDefChanged(_):
				updateEntityList();
				updateFieldsForm();

			case _:
		}
	}

	function selectEntity(ed:Null<data.def.EntityDef>) {
		if( ed==null )
			ed = editor.project.defs.entities[0];

		curEntity = ed;
		LAST_ENTITY_ID = curEntity==null ? -1 : curEntity.uid;
		updatePreview();
		updateEntityForm();
		updateFieldsForm();
		updateEntityList();
	}

	function updateEntityForm() {
		ui.Tip.clear();
		jEntityForm.find("*").off(); // cleanup event listeners

		var jAll = jEntityForm.add( jPreview );
		if( curEntity==null ) {
			jAll.css("visibility","hidden");
			jContent.find(".none").show();
			// jContent.find(".noEntLayer").hide();
			return;
		}

		JsTools.parseComponents(jEntityForm);
		jAll.css("visibility","visible");
		jContent.find(".none").hide();
		// if( !project.defs.hasLayerType(Entities) )
		// 	jContent.find(".noEntLayer").show();
		// else
		// 	jContent.find(".noEntLayer").hide();


		// Name
		var i = Input.linkToHtmlInput(curEntity.identifier, jEntityForm.find("input[name='name']") );
		i.fixValue = (v)->project.fixUniqueIdStr(v, (id)->project.defs.isEntityIdentifierUnique(id, curEntity));
		i.linkEvent(EntityDefChanged);

		// Hollow (ie. click through)
		var i = Input.linkToHtmlInput(curEntity.hollow, jEntityForm.find("input[name=hollow]") );
		i.linkEvent(EntityDefChanged);

		// Tags editor
		var ted = new ui.TagEditor(
			curEntity.tags,
			()->editor.ge.emit(EntityDefChanged),
			()->project.defs.getRecallEntityTags([curEntity.tags])
		);
		jEntityForm.find("#tags").empty().append(ted.jEditor);

		// Dimensions
		var i = Input.linkToHtmlInput( curEntity.width, jEntityForm.find("input[name='width']") );
		i.setBounds(1,2048);
		i.onChange = editor.ge.emit.bind(EntityDefChanged);

		// Resizable
		var i = Input.linkToHtmlInput( curEntity.resizableX, jEntityForm.find("input#resizableX") );
		i.onChange = editor.ge.emit.bind(EntityDefChanged);
		var i = Input.linkToHtmlInput( curEntity.resizableY, jEntityForm.find("input#resizableY") );
		i.onChange = editor.ge.emit.bind(EntityDefChanged);
		var i = Input.linkToHtmlInput( curEntity.keepAspectRatio, jEntityForm.find("input#keepAspectRatio") );
		i.onChange = editor.ge.emit.bind(EntityDefChanged);
		i.setEnabled( curEntity.resizableX && curEntity.resizableY );

		var i = Input.linkToHtmlInput( curEntity.height, jEntityForm.find("input[name='height']") );
		i.setBounds(1,2048);
		i.onChange = editor.ge.emit.bind(EntityDefChanged);

		// Display renderMode form fields based on current mode
		var jRenderModeBlock = jEntityForm.find("dd.renderMode");
		JsTools.removeClassReg(jRenderModeBlock, ~/mode_\S+/g);
		jRenderModeBlock.addClass("mode_"+curEntity.renderMode);
		jRenderModeBlock.find(".tilePicker").empty();

		// Color
		var col = jEntityForm.find("input[name=color]");
		col.val( C.intToHex(curEntity.color) );
		col.change( function(ev) {
			curEntity.color = C.hexToInt( col.val() );
			editor.ge.emit(EntityDefChanged);
			updateEntityForm();
		});

		// Fill/line opacities
		var i = Input.linkToHtmlInput(curEntity.fillOpacity, jEntityForm.find("#fillOpacity"));
		i.setBounds(0.1, 1);
		i.enablePercentageMode();
		i.linkEvent( EntityDefChanged );
		i.setEnabled(!curEntity.hollow);
		var i = Input.linkToHtmlInput(curEntity.lineOpacity, jEntityForm.find("#lineOpacity"));
		i.setBounds(0, 1);
		i.enablePercentageMode();
		i.linkEvent( EntityDefChanged );
		i.setEnabled(curEntity.renderMode!=Tile);

		// Entity render mode
		var jSelect = jRenderModeBlock.find(".renderMode");
		jSelect.empty();
		for(k in ldtk.Json.EntityRenderMode.getConstructors()) {
			var e = ldtk.Json.EntityRenderMode.createByName(k);
			if( e==Tile )
				continue;

			var jOpt = new J('<option value="$k"/>');
			jOpt.appendTo(jSelect);
			jOpt.text(switch e {
				case Rectangle: Lang.t._("Rectangle");
				case Ellipse: Lang.t._("Ellipse");
				case Cross: Lang.t._("Cross");
				case Tile: null;
			});
		}
		// Append tilesets
		if( project.defs.tilesets.length==0 )
			jSelect.append( new J('<option value="Tile">-- No tileset available --</option>') );

		for( td in project.defs.tilesets ) {
			var jOpt = new J('<option value="Tile.${td.uid}"/>');
			jOpt.appendTo(jSelect);
			jOpt.text( Lang.t._("Tile from ::name::", {name:td.identifier}) );
		}

		// Pick render mode
		jSelect.change( function(ev) {
			var v : String = jSelect.val();
			var mode = ldtk.Json.EntityRenderMode.createByName( v.indexOf(".")<0 ? v : v.substr(0,v.indexOf(".")) );
			curEntity.renderMode = mode;
			curEntity.tileId = null;
			if( mode==Tile ) {
				var tdUid = Std.parseInt( v.substr(v.indexOf(".")+1) );
				curEntity.tilesetId = tdUid;
			}
			else {
				curEntity.tilesetId = null;
				curEntity.tileRenderMode = FitInside;
			}

			editor.ge.emit( EntityDefChanged );
		});
		jSelect.val( curEntity.renderMode.getName() + ( curEntity.renderMode==Tile ? "."+curEntity.tilesetId : "" ) );

		// Tile render mode
		var i = new form.input.EnumSelect(
			jEntityForm.find("select.tileRenderMode"),
			ldtk.Json.EntityTileRenderMode,
			()->curEntity.tileRenderMode,
			(v)->curEntity.tileRenderMode = v
		);
		i.linkEvent( EntityDefChanged );

		// Tile pick
		if( curEntity.renderMode==Tile ) {
			var jPicker = JsTools.createTilePicker(
				curEntity.tilesetId,
				PickAndClose,
				curEntity.tileId==null ? [] : [curEntity.tileId],
				(tileIds)->{
					curEntity.tileId = tileIds[0];
					editor.ge.emit(EntityDefChanged);
				}
			);
			jPicker.appendTo( jRenderModeBlock.find(".tilePicker") );
		}


		// Max count
		var i = Input.linkToHtmlInput(curEntity.maxCount, jEntityForm.find("input#maxCount") );
		i.setBounds(0,1024);
		i.onChange = editor.ge.emit.bind(EntityDefChanged);
		if( curEntity.maxCount==0 )
			i.jInput.val("");

		var i = new form.input.EnumSelect(
			i.jInput.siblings("[name=scope]"),
			ldtk.Json.EntityLimitScope,
			()->curEntity.limitScope,
			(e)->curEntity.limitScope = e,
			(e)->switch e {
				case PerLayer: L.t._("per layer");
				case PerLevel: L.t._("per level");
				case PerWorld: L.t._("in the world");
			}
		);
		i.setEnabled(curEntity.maxCount>0);

		// Behavior when max is reached
		var i = new form.input.EnumSelect(
			jEntityForm.find("select[name=limitBehavior]"),
			ldtk.Json.EntityLimitBehavior,
			function() return curEntity.limitBehavior,
			function(v) {
				curEntity.limitBehavior = v;
			},
			function(k) {
				return switch k {
					case DiscardOldOnes: Lang.t._("discard older ones");
					case PreventAdding: Lang.t._("prevent adding more");
					case MoveLastOne: Lang.t._("move the last one instead of adding");
				}
			}
		);
		i.setEnabled( curEntity.maxCount>0 );

		// Show name
		var i = Input.linkToHtmlInput(curEntity.showName, jEntityForm.find("#showIdentifier"));
		i.linkEvent(EntityDefChanged);

		// Pivot
		var jPivots = jEntityForm.find(".pivot");
		jPivots.empty();
		var p = JsTools.createPivotEditor(curEntity.pivotX, curEntity.pivotY, curEntity.color, function(x,y) {
			curEntity.pivotX = x;
			curEntity.pivotY = y;
			editor.ge.emit(EntityDefChanged);
		});
		jPivots.append(p);

		checkBackup();
	}


	function updateFieldsForm() {
		if( curEntity!=null )
			fieldsForm.useFields(curEntity.identifier, curEntity.fieldDefs);
		else {
			fieldsForm.useFields("Entity", []);
			fieldsForm.hide();
		}
		checkBackup();
	}


	function updateEntityList() {
		jEntityList.empty();

		var allTags = project.defs.getEntityTagCategories();

		// List context menu
		ContextMenu.addTo(jEntityList, false, [
			{
				label: L._Paste(),
				cb: ()->{
					var copy = project.defs.pasteEntityDef(App.ME.clipboard);
					editor.ge.emit(EntityDefAdded);
					selectEntity(copy);
				},
				enable: ()->App.ME.clipboard.is(CEntityDef),
			}
		]);

		// Tags
		for(t in allTags) {
			if( allTags.length>1 ) {
				var jSep = new J('<li class="title fixed"/>');
				jSep.text( t==null ? L.t._("Untagged") : t );
				jSep.appendTo(jEntityList);
			}

			var jLi = new J('<li class="subList"/>');
			jLi.appendTo(jEntityList);
			var jSubList = new J('<ul/>');
			jSubList.appendTo(jLi);

			// Entities per tag
			for(ed in project.defs.entities) {
				if( t==null && !ed.tags.isEmpty() || t!=null && !ed.tags.has(t) )
					continue;

				var jEnt = new J('<li class="iconLeft"/>');
				jEnt.appendTo(jSubList);
				jEnt.attr("uid", ed.uid);

				var preview = JsTools.createEntityPreview(editor.project, ed);
				preview.appendTo(jEnt);

				jEnt.append('<span class="name">${ed.identifier}</span>');
				if( curEntity==ed ) {
					jEnt.addClass("active");
					jEnt.css( "background-color", C.intToHex( C.toWhite(ed.color, 0.5) ) );
				}
				else
					jEnt.css( "color", C.intToHex( C.toWhite(ed.color, 0.5) ) );


				ContextMenu.addTo(jEnt, [
					{
						label: L._Copy(),
						cb: ()->App.ME.clipboard.copyData(CEntityDef, ed.toJson()),
					},
					{
						label: L._Cut(),
						cb: ()->{
							App.ME.clipboard.copyData(CEntityDef, ed.toJson());
							deleteEntityDef(ed);
						},
					},
					{
						label: L._PasteAfter(),
						cb: ()->{
							var copy = project.defs.pasteEntityDef(App.ME.clipboard, ed);
							editor.ge.emit(EntityDefAdded);
							selectEntity(copy);
						},
						enable: ()->App.ME.clipboard.is(CEntityDef),
					},
					{
						label: L._Duplicate(),
						cb:()->{
							var copy = project.defs.duplicateEntityDef(ed);
							editor.ge.emit(EntityDefAdded);
							selectEntity(copy);
						}
					},
					{ label: L._Delete(), cb:deleteEntityDef.bind(ed) },
				]);


				jEnt.click( function(_) selectEntity(ed) );
			}

			// Make sub list sortable
			JsTools.makeSortable(jSubList, function(ev:sortablejs.Sortable.SortableDragEvent) {
				var jItem = new J(ev.item);
				var fromIdx = project.defs.getEntityIndex( Std.parseInt( jItem.attr("uid") ) );
				var toIdx = ev.newIndex>ev.oldIndex
					? jItem.prev().length==0 ? 0 : project.defs.getEntityIndex( Std.parseInt( jItem.prev().attr("uid") ) )
					: jItem.next().length==0 ? project.defs.entities.length-1 : project.defs.getEntityIndex( Std.parseInt( jItem.next().attr("uid") ) );
				var moved = project.defs.sortEntityDef(fromIdx, toIdx);
				selectEntity(moved);
				editor.ge.emit(EntityDefSorted);
			});
		}

		checkBackup();
	}


	function updatePreview() {
		if( curEntity==null )
			return;

		jPreview.children(".entityPreview").remove();
		jPreview.append( JsTools.createEntityPreview(project, curEntity, 64) );
	}
}
