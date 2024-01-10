package ui.modal.panel;

import data.DataTypes;

class EditEntityDefs extends ui.modal.Panel {
	static var LAST_ENTITY_ID = -1;

	var jEntityList(get,never) : js.jquery.JQuery; inline function get_jEntityList() return jContent.find(".entityList>ul");
	var jEntityForm(get,never) : js.jquery.JQuery; inline function get_jEntityForm() return jContent.find(".entityForm>dl.form");
	var jPreview(get,never) : js.jquery.JQuery; inline function get_jPreview() return jContent.find(".previewWrapper");

	var curEntity : Null<data.def.EntityDef>;
	public var fieldsForm : FieldDefsForm;
	var search : QuickSearch;


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
			ctx.addAction({
				label: L.t._("Rectangle region"),
				cb: ()->{
					var ed = _createEntity();
					ed.identifier = project.fixUniqueIdStr("RectRegion", (s)->project.defs.isEntityIdentifierUnique(s));
					ed.hollow = true;
					ed.resizableX = true;
					ed.resizableY = true;
					ed.pivotX = ed.pivotY = 0;
					ed.tags.set("region");
					selectEntity(ed);
					editor.ge.emit( EntityDefChanged );
				}
			});
			ctx.addAction({
				label: L.t._("Circle region"),
				cb: ()->{
					var ed = _createEntity();
					ed.identifier = project.fixUniqueIdStr("CircleRegion", (s)->project.defs.isEntityIdentifierUnique(s));
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
		fieldsForm = new ui.FieldDefsForm( FP_Entity(null) );
		jContent.find("#fields").replaceWith( fieldsForm.jWrapper );

		// Create quick search
		search = new ui.QuickSearch( jContent.find(".entityList ul") );
		search.jWrapper.appendTo( jContent.find(".search") );

		// Select same entity as current client selection
		if( editDef!=null )
			selectEntity( editDef );
		else if( editor.curLayerDef!=null && editor.curLayerDef.type==Entities )
			selectEntity( project.defs.getEntityDef(editor.curTool.getSelectedValue()) );
		else if( LAST_ENTITY_ID>=0 && project.defs.getEntityDef(LAST_ENTITY_ID)!=null )
			selectEntity( project.defs.getEntityDef(LAST_ENTITY_ID) );
		else
			selectEntity(project.defs.entities[0]);

		checkHelpBanner( ()->project.defs.entities.length<=3 );
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

			case LayerInstancesRestoredFromHistory(_):
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

			case ExternalEnumsLoaded(anyCriticalChange):
				updateEntityList();
				updateFieldsForm();

			case _:
		}
	}

	public function selectEntity(ed:Null<data.def.EntityDef>) {
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
		var jAll = jEntityForm.add( jContent.find(".collapser") );
		if( curEntity==null ) {
			jAll.css("visibility","hidden");
			jContent.find(".none").show();
			return;
		}

		jAll.css("visibility","visible");
		jContent.find(".none").hide();


		// Identifier
		var i = Input.linkToHtmlInput(curEntity.identifier, jEntityForm.find("input[name='name']") );
		i.fixValue = (v)->project.fixUniqueIdStr(v, (id)->project.defs.isEntityIdentifierUnique(id, curEntity));
		i.linkEvent(EntityDefChanged);

		// Doc
		var i = Input.linkToHtmlInput( curEntity.doc, jEntityForm.find("input[name=entityDoc]") );
		i.linkEvent(EntityDefChanged);
		i.allowNull = true;

		// Hollow (ie. click through)
		var i = Input.linkToHtmlInput(curEntity.hollow, jEntityForm.find("input[name=hollow]") );
		i.linkEvent(EntityDefChanged);

		// Tags editor
		var ted = new ui.TagEditor(
			curEntity.tags,
			()->editor.ge.emit(EntityDefChanged),
			()->project.defs.getRecallEntityTags([curEntity.tags]),
			()->return project.defs.entities.map( ed->ed.tags ),
			(oldT,newT)->{
				for(ed in project.defs.entities)
					for(fd in ed.fieldDefs)
						fd.allowedRefTags.rename(oldT, newT);

				for(ld in project.defs.layers) {
					ld.requiredTags.rename(oldT, newT);
					ld.excludedTags.rename(oldT, newT);
				}
				editor.ge.emit( EntityDefChanged );
			}
		);
		jEntityForm.find("#tags").empty().append(ted.jEditor);

		// Dimensions
		var i = Input.linkToHtmlInput( curEntity.width, jEntityForm.find("input[name='width']") );
		i.setBounds(1,2048);
		i.onChange = editor.ge.emit.bind(EntityDefChanged);

		// Resizable
		var i = Input.linkToHtmlInput( curEntity.resizableX, jEntityForm.find("input#resizableX") );
		i.onValueChange = (v)->if( !v ) {
			curEntity.minWidth = null;
			curEntity.maxWidth = null;
		}
		else {
			curEntity.minWidth = curEntity.width;
		}
		i.linkEvent(EntityDefChanged);
		var i = Input.linkToHtmlInput( curEntity.resizableY, jEntityForm.find("input#resizableY") );
		i.linkEvent(EntityDefChanged);
		i.onValueChange = (v)->if( !v ) {
			curEntity.minHeight = null;
			curEntity.maxHeight = null;
		}
		else {
			curEntity.minHeight = curEntity.height;
		}
		var i = Input.linkToHtmlInput( curEntity.keepAspectRatio, jEntityForm.find("input#keepAspectRatio") );
		i.linkEvent(EntityDefChanged);
		i.setEnabled( curEntity.resizableX && curEntity.resizableY );

		var i = Input.linkToHtmlInput( curEntity.height, jEntityForm.find("input[name='height']") );
		i.setBounds(1,2048);
		i.onChange = editor.ge.emit.bind(EntityDefChanged);

		// Min/max for resizables
		var jMinMax = jEntityForm.find(".minMax");
		if( curEntity.isResizable() ) {
			jMinMax.show();
			// Min width
			var i = Input.linkToHtmlInput( curEntity.minWidth, jMinMax.find("input[name=minWidth]") );
			i.setEnabled(curEntity.resizableX);
			i.setPlaceholder(curEntity.resizableX ? "None" : "");
			i.setBounds(0, curEntity.maxWidth);
			i.fixValue = (v)->return v<=0 ? null : v;
			i.linkEvent(EntityDefChanged);
			// Min height
			var i = Input.linkToHtmlInput( curEntity.minHeight, jMinMax.find("input[name=minHeight]") );
			i.setEnabled(curEntity.resizableY);
			i.setPlaceholder(curEntity.resizableY ? "None" : "");
			i.setBounds(0, curEntity.maxHeight);
			i.fixValue = (v)->return v<=0 ? null : v;
			i.linkEvent(EntityDefChanged);
			// Max width
			var i = Input.linkToHtmlInput( curEntity.maxWidth, jMinMax.find("input[name=maxWidth]") );
			i.setEnabled(curEntity.resizableX);
			i.setPlaceholder(curEntity.resizableX ? "None" : "");
			i.setBounds(curEntity.minWidth, null);
			i.fixValue = (v)->return v<=0 ? null : v;
			i.linkEvent(EntityDefChanged);
			// Max height
			var i = Input.linkToHtmlInput( curEntity.maxHeight, jMinMax.find("input[name=maxHeight]") );
			i.setEnabled(curEntity.resizableY);
			i.setPlaceholder(curEntity.resizableY ? "None" : "");
			i.setBounds(curEntity.minHeight, null);
			i.fixValue = (v)->return v<=0 ? null : v;
			i.linkEvent(EntityDefChanged);
		}
		else
			jMinMax.hide();

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
		var i = Input.linkToHtmlInput(curEntity.tileOpacity, jEntityForm.find("#tileOpacity"));
		i.setBounds(0, 1);
		i.enablePercentageMode();
		i.linkEvent( EntityDefChanged );
		i.setEnabled(curEntity.renderMode==Tile);

		var i = Input.linkToHtmlInput(curEntity.fillOpacity, jEntityForm.find("#fillOpacity"));
		i.setBounds(0, 1);
		i.enablePercentageMode();
		i.setEnabled(!curEntity.hollow);
		i.linkEvent( EntityDefChanged );

		var i = Input.linkToHtmlInput(curEntity.lineOpacity, jEntityForm.find("#lineOpacity"));
		i.setBounds(0, 1);
		i.enablePercentageMode();
		i.linkEvent( EntityDefChanged );

		// Entity render mode
		var jRenderSelect = jRenderModeBlock.find(".renderMode");
		jRenderSelect.empty();
		var jOptGroup = new J('<optgroup label="Shapes"/>');
		jOptGroup.appendTo(jRenderSelect);
		for(k in ldtk.Json.EntityRenderMode.getConstructors()) {
			var mode = ldtk.Json.EntityRenderMode.createByName(k);
			if( mode==Tile )
				continue;

			var jOpt = new J('<option value="!$k"/>');
			jOpt.appendTo(jOptGroup);
			jOpt.text(switch mode {
				case Rectangle: Lang.t._("Rectangle");
				case Ellipse: Lang.t._("Ellipse");
				case Cross: Lang.t._("Cross");
				case Tile: null;
			});
		}
		JsTools.appendTilesetsToSelect(project, jRenderSelect);

		// Pick render mode
		jRenderSelect.change( function(ev) {
			var oldMode = curEntity.renderMode;
			curEntity._oldTileId = null;
			curEntity.tileRect = null; // NOTE: important to clear as tilesetUid is also stored in it!

			var raw : String = jRenderSelect.val();
			if( M.isValidNumber(Std.parseInt(raw)) ) {
				// Tileset UID
				curEntity.renderMode = Tile;
				curEntity.tilesetId = Std.parseInt(raw);
		}
			else {
				if( raw.indexOf("!")==0 ) {
					// Shape
					curEntity.renderMode = ldtk.Json.EntityRenderMode.createByName( raw.substr(1) );
					curEntity.tilesetId = null;
				}
				else {
					// Embed tileset
					var embedId = ldtk.Json.EmbedAtlas.createByName(raw);
					var td = project.defs.getEmbedTileset(embedId);
					curEntity.renderMode = Tile;
					curEntity.tilesetId = td.uid;
				}
			}

			// Re-init opacities
			if( oldMode!=Tile && curEntity.renderMode==Tile ) {
				curEntity.tileOpacity = 1;
				curEntity.fillOpacity = 0.08;
				curEntity.lineOpacity = 0;
			}
			if( oldMode==Tile && curEntity.renderMode!=Tile ) {
				curEntity.tileOpacity = 1;
				curEntity.fillOpacity = 1;
				curEntity.lineOpacity = 1;
			}

			editor.ge.emit( EntityDefChanged );
		});

		if( curEntity.tilesetId!=null ) {
			var td = project.defs.getTilesetDef(curEntity.tilesetId);
			if( td.isUsingEmbedAtlas() )
				jRenderSelect.val( td.embedAtlas.getName() );
			else
				jRenderSelect.val( Std.string(td.uid) );
		}
		else
			jRenderSelect.val( "!"+curEntity.renderMode.getName() );


		// Tile render mode
		var i = new form.input.EnumSelect(
			jEntityForm.find("select.tileRenderMode"),
			ldtk.Json.EntityTileRenderMode,
			()->curEntity.tileRenderMode,
			(v)->curEntity.tileRenderMode = v,
			(v)->switch v {
				case Cover: L.t._("Cover bounds");
				case FitInside: L.t._("Fit inside bounds");
				case Repeat: L.t._("Repeat");
				case Stretch: L.t._("Dirty stretch to bounds");
				case FullSizeCropped: L.t._("Full size (cropped in bounds)");
				case FullSizeUncropped: L.t._("Full size (not cropped)");
				case NineSlice: L.t._("9-slices scaling");
			}
		);
		i.linkEvent( EntityDefChanged );

		if( curEntity.tileRenderMode!=NineSlice )
			jEntityForm.find(".nineSlice").hide();
		else {
			jEntityForm.find(".nineSlice").show();
			if( curEntity.nineSliceBorders.length!=4 )
				curEntity.nineSliceBorders = [2,2,2,2];

			function createNineSliceInput(idx:Int, htmlName:String) {
				var i = new form.input.IntInput(
					jEntityForm.find("[name="+htmlName+"]"),
					()->curEntity.nineSliceBorders[idx],
					(v)->{
						if( v==null )
							if( idx==0 )
								v = 1;
							else
								v = curEntity.nineSliceBorders[0];

						if( idx==0 ) {
							// Auto set other borders
							final arr = curEntity.nineSliceBorders;
							if( arr[1]==arr[0] && arr[2]==arr[0] && arr[3]==arr[0] )
								for(i in 1...4)
									arr[i] = v;
						}

						curEntity.nineSliceBorders[idx] = v;
						editor.ge.emit(EntityDefChanged);
					}
				);
				i.setBounds(1,null);
				i.allowNull = true;
			}
			createNineSliceInput(0, "nineSliceUp");
			createNineSliceInput(1, "nineSliceRight");
			createNineSliceInput(2, "nineSliceDown");
			createNineSliceInput(3, "nineSliceLeft");
		}

		// Tile rect picker
		if( curEntity.renderMode==Tile ) {
			var jPicker = JsTools.createTileRectPicker(
				curEntity.tilesetId,
				curEntity.tileRect,
				(rect)->{
					if( rect!=null ) {
						curEntity.tileRect = rect;
						editor.ge.emit(EntityDefChanged);
					}
				}
			);
			jPicker.appendTo( jRenderModeBlock.find(".tilePicker") );
		}


		// UI override tile
		JsTools.createTilesetSelect(
			project,
			jEntityForm.find(".uiTileset"),
			curEntity.uiTileRect!=null ? curEntity.uiTileRect.tilesetUid : null,
			true,
			"Use default editor visual",
			(uid)->{
				if( uid!=null )
					curEntity.uiTileRect = { tilesetUid: uid, x: 0, y: 0, w: 0, h:0, }
				else
					curEntity.uiTileRect = null;
				editor.ge.emit(EntityDefChanged);
			}
		);
		var jUiTilePickerWrapper = jEntityForm.find(".uiTilePicker").empty();
		if( curEntity.uiTileRect!=null ) {
			var jPicker = JsTools.createTileRectPicker(
				curEntity.uiTileRect.tilesetUid,
				curEntity.uiTileRect.w>0 ? curEntity.uiTileRect : null,
				(rect)->{
					if( rect!=null ) {
						curEntity.uiTileRect = rect;
						editor.ge.emit(EntityDefChanged);
					}
				}
			);
			jUiTilePickerWrapper.append( jPicker );
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

		// Show identfier
		var i = Input.linkToHtmlInput(curEntity.showName, jEntityForm.find("#showIdentifier"));
		i.linkEvent(EntityDefChanged);

		// Export to table of content
		var i = Input.linkToHtmlInput(curEntity.exportToToc, jEntityForm.find("#exportToToc"));
		i.linkEvent(EntityDefChanged);
		i.onChange = ()->{
			for(fd in curEntity.fieldDefs)
				if( fd.exportToToc ) {
					fd.exportToToc = false;
					editor.ge.emit(FieldDefChanged(fd));
				}
		}

		// Out-of-bounds policy
		var i = Input.linkToHtmlInput(curEntity.allowOutOfBounds, jEntityForm.find("#allowOutOfBounds"));
		i.linkEvent(EntityDefChanged);

		// Pivot
		var jPivots = jEntityForm.find(".pivot");
		jPivots.empty();
		var p = JsTools.createPivotEditor(
			curEntity.pivotX, curEntity.pivotY,
			curEntity.color,
			true, curEntity.width, curEntity.height,
			function(x,y) {
				curEntity.pivotX = x;
				curEntity.pivotY = y;
				editor.ge.emit(EntityDefChanged);
			}
		);
		jPivots.append(p);

		checkBackup();
		JsTools.parseComponents(jEntityForm);
	}


	function updateFieldsForm() {
		if( curEntity!=null )
			fieldsForm.useFields(FP_Entity(curEntity), curEntity.fieldDefs);
		else {
			fieldsForm.useFields(FP_Entity(null), []);
			fieldsForm.hide();
		}
		checkBackup();
	}


	function updateEntityList() {
		jEntityList.empty();

		// List context menu
		ContextMenu.attachTo(jEntityList, false, [
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
		var tagGroups = project.defs.groupUsingTags(project.defs.entities, (ed)->ed.tags);
		for( group in tagGroups ) {
			// Tag name
			if( tagGroups.length>1 ) {
				var jSep = new J('<li class="title collapser"/>');
				jSep.text( group.tag==null ? L._Untagged() : group.tag );
				jSep.attr("id", project.iid+"_entity_tag_"+group.tag);
				jSep.attr("default", "open");
				jSep.appendTo(jEntityList);

			}

			// Create sub list
			var jLi = new J('<li class="subList"/>');
			jLi.appendTo(jEntityList);
			var jSubList = new J('<ul class="niceList compact"/>');
			jSubList.appendTo(jLi);

			for(ed in group.all) {
				var jEnt = new J('<li class="iconLeft draggable"/>');
				jEnt.appendTo(jSubList);
				jEnt.attr("uid", ed.uid);
				jEnt.css("background-color", dn.Col.fromInt(ed.color).toCssRgba(0.2));

				// HTML entity display preview
				var preview = JsTools.createEntityPreview(editor.project, ed);
				preview.appendTo(jEnt);

				// Name
				jEnt.append('<span class="name">${ed.identifier}</span>');
				if( curEntity==ed ) {
					jEnt.addClass("active");
					jEnt.css( "background-color", C.intToHex( C.toWhite(ed.color, 0.5) ) );
				}
				else
					jEnt.css( "color", C.intToHex( C.toWhite(ed.color, 0.5) ) );

				// Menu
				ContextMenu.attachTo_new(jEnt, (ctx:ContextMenu)->{
					ctx.addElement( Ctx_CopyPaster({
						elementName: "entity",
						clipType: CEntityDef,
						copy: ()->App.ME.clipboard.copyData(CEntityDef, ed.toJson(project)),
						cut: ()->{
							App.ME.clipboard.copyData(CEntityDef, ed.toJson(project));
							deleteEntityDef(ed);
						},
						paste: ()->{
							var copy = project.defs.pasteEntityDef(App.ME.clipboard, ed);
							editor.ge.emit(EntityDefAdded);
							selectEntity(copy);
						},
						duplicate: ()->{
							var copy = project.defs.duplicateEntityDef(ed);
							editor.ge.emit(EntityDefAdded);
							selectEntity(copy);
						},
						delete: ()->deleteEntityDef(ed),
					}) );
				});

				// Click
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
			}, { onlyDraggables:true });
		}

		JsTools.parseComponents(jEntityList);
		checkBackup();
		search.run();
	}


	function updatePreview() {
		if( curEntity==null )
			return;

		jPreview.children(".entityPreview").remove();
		jPreview.append( JsTools.createEntityPreview(project, curEntity, 64) );
	}
}
