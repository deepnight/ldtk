package ui.modal.panel;

import data.DataTypes;

class EditEntityDefs extends ui.modal.Panel {
	static var LAST_ENTITY_ID = -1;

	var jEntityList(get,never) : js.jquery.JQuery; inline function get_jEntityList() return jContent.find(".entityList ul");
	var jEntityForm(get,never) : js.jquery.JQuery; inline function get_jEntityForm() return jContent.find(".entityForm>ul.form");
	var jPreview(get,never) : js.jquery.JQuery; inline function get_jPreview() return jContent.find(".previewWrapper");

	var curEntity : Null<data.def.EntityDef>;
	var fieldsForm : FieldDefsForm;


	public function new(?editDef:data.def.EntityDef) {
		super();

		loadTemplate( "editEntityDefs", "defEditor entityDefs" );
		linkToButton("button.editEntities");

		// Create entity
		jEntityList.parent().find("button.create").click( function(_) {
			var ed = project.defs.createEntityDef();
			selectEntity(ed);
			editor.ge.emit(EntityDefAdded);
			jEntityForm.find("input").first().focus().select();
		});

		// Delete entity
		jEntityList.parent().find("button.delete").click( function(ev) {
			if( curEntity==null ) {
				N.error("No entity selected.");
				return;
			}
			deleteEntityDef(curEntity);
		});

		// Create fields editor
		fieldsForm = new ui.FieldDefsForm(
			(t,n,arr)->curEntity.createFieldDef(project, t, n, arr),
			fd->editor.ge.emit( EntityFieldAdded(curEntity) ),
			fd->editor.ge.emit( EntityFieldDefChanged(curEntity) ),
			fd->editor.ge.emit( EntityFieldRemoved(curEntity) ),
			(from,to)->{
				var moved = curEntity.sortField(from, to);
				editor.ge.emit( EntityFieldSorted );
				return moved;
			}
		);
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
				Lang.t._("WARNING! This entity is used in one more levels. The corresponding instances will also be deleted!"),
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

			case EntityDefSorted, EntityFieldSorted:
				updateEntityList();

			case EntityFieldAdded(ed), EntityFieldRemoved(ed), EntityFieldDefChanged(ed):
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
		jEntityForm.find("*").off(); // cleanup event listeners

		var jAll = jEntityForm.add( jPreview );
		if( curEntity==null ) {
			jAll.css("visibility","hidden");
			jContent.find(".none").show();
			jContent.find(".noEntLayer").hide();
			return;
		}

		JsTools.parseComponents(jEntityForm);
		jAll.css("visibility","visible");
		jContent.find(".none").hide();
		if( !project.defs.hasLayerType(Entities) )
			jContent.find(".noEntLayer").show();
		else
			jContent.find(".noEntLayer").hide();


		// Name
		var i = Input.linkToHtmlInput(curEntity.identifier, jEntityForm.find("input[name='name']") );
		i.validityCheck = function(id) return data.Project.isValidIdentifier(id) && project.defs.isEntityIdentifierUnique(id);
		i.validityError = N.invalidIdentifier;
		i.linkEvent(EntityDefChanged);

		// Dimensions
		var i = Input.linkToHtmlInput( curEntity.width, jEntityForm.find("input[name='width']") );
		i.setBounds(1,256);
		i.onChange = editor.ge.emit.bind(EntityDefChanged);

		var i = Input.linkToHtmlInput( curEntity.height, jEntityForm.find("input[name='height']") );
		i.setBounds(1,256);
		i.onChange = editor.ge.emit.bind(EntityDefChanged);

		// Display renderMode form fields based on current mode
		var jRenderModeBlock = jEntityForm.find("li.renderMode");
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
				curEntity.tileRenderMode = Stretch;
			}

			editor.ge.emit( EntityDefChanged );
		});
		jSelect.val( curEntity.renderMode.getName() + ( curEntity.renderMode==Tile ? "."+curEntity.tilesetId : "" ) );

		// Render mode
		// var i = new form.input.EnumSelect(
		// 	jEntityForm.find("select.renderMode"),
		// 	data.DataTypes.EntityRenderMode,
		// 	function() return curEntity.renderMode,
		// 	function(v) {
		// 		curEntity.tileId = null;
		// 		curEntity.tilesetId = null;
		// 		curEntity.renderMode = v;
		// 	}
		// );
		// i.linkEvent(EntityDefChanged);

		// // Tileset pick
		// var jTilesets = jEntityForm.find("select.tilesets");
		// jTilesets.find("option:not(:first)").remove();
		// if( curEntity.renderMode==Tile ) {
		// 	for( td in project.defs.tilesets ) {
		// 		var opt = new J('<option/>');
		// 		opt.appendTo(jTilesets);
		// 		opt.attr("value",td.uid);
		// 		opt.text( td.identifier );
		// 		if( td.uid==curEntity.tilesetId )
		// 			opt.attr("selected","selected");
		// 	}
		// 	jTilesets.change( function(_) {
		// 		var id = Std.parseInt( jTilesets.val() );
		// 		curEntity.tileId = null;
		// 		if( !M.isValidNumber(id) || id<0 )
		// 			curEntity.tilesetId = null;
		// 		else
		// 			curEntity.tilesetId = id;
		// 		editor.ge.emit(EntityDefChanged);
		// 	});
		// }

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
			var jPicker = JsTools.createTilePicker(curEntity.tilesetId, SingleTile, [curEntity.tileId], function(tileIds) {
				curEntity.tileId = tileIds[0];
				editor.ge.emit(EntityDefChanged);
			});
			jPicker.appendTo( jRenderModeBlock.find(".tilePicker") );
		}


		// Max per level
		var i = Input.linkToHtmlInput(curEntity.maxPerLevel, jEntityForm.find("input[name='maxPerLevel']") );
		i.setBounds(0,1024);
		i.onChange = editor.ge.emit.bind(EntityDefChanged);
		if( curEntity.maxPerLevel==0 )
			i.jInput.val("");

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
		i.setEnabled( curEntity.maxPerLevel>0 );

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
	}


	function updateFieldsForm() {
		if( curEntity!=null )
			fieldsForm.setFields(curEntity.fieldDefs);
	}


	function updateEntityList() {
		jEntityList.empty();

		// Entities
		for(ed in project.defs.entities) {
			var elem = new J("<li/>");
			jEntityList.append(elem);
			elem.addClass("iconLeft");

			var preview = JsTools.createEntityPreview(editor.project, ed);
			preview.appendTo(elem);

			elem.append('<span class="name">'+ed.identifier+'</span>');
			if( curEntity==ed ) {
				elem.addClass("active");
				elem.css( "background-color", C.intToHex( C.toWhite(ed.color, 0.5) ) );
			}
			else
				elem.css( "color", C.intToHex( C.toWhite(ed.color, 0.5) ) );


			ContextMenu.addTo(elem, [
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


			elem.click( function(_) selectEntity(ed) );
		}

		// Make list sortable
		JsTools.makeSortable(jEntityList, function(ev) {
			var moved = project.defs.sortEntityDef(ev.oldIndex, ev.newIndex);
			selectEntity(moved);
			editor.ge.emit(EntityDefSorted);
		});
	}


	function updatePreview() {
		if( curEntity==null )
			return;

		jPreview.children(".entityPreview").remove();
		jPreview.append( JsTools.createEntityPreview(project, curEntity, 64) );
	}
}
