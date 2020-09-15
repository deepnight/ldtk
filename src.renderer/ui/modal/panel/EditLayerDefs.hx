package ui.modal.panel;

class EditLayerDefs extends ui.modal.Panel {
	var jList : js.jquery.JQuery;
	var jForm : js.jquery.JQuery;
	public var cur : Null<led.def.LayerDef>;

	public function new() {
		super();

		loadTemplate( "editLayerDefs", "defEditor layerDefs" );
		jList = jModalAndMask.find(".mainList ul");
		jForm = jModalAndMask.find("ul.form");
		linkToButton("button.editLayers");

		// Create layer
		jModalAndMask.find(".mainList button.create").click( function(ev) {
			function _create(type:led.LedTypes.LayerType) {
				var ld = project.defs.createLayerDef(type);
				select(ld);
				editor.ge.emit(LayerDefAdded);
				jForm.find("input").first().focus().select();
			}

			// Type picker
			var w = new ui.modal.Dialog(ev.getThis(),"layerTypes");
			for(k in led.LedTypes.LayerType.getConstructors()) {
				var type = led.LedTypes.LayerType.createByName(k);
				var b = new J("<button/>");
				b.appendTo( w.jContent );
				JsTools.createLayerTypeIcon(type, b);
				b.click( function(_) {
					_create(type);
					w.close();
				});
			}

		});

		// Delete layer
		jModalAndMask.find(".mainList button.delete").click( function(ev) {
			if( cur==null ) {
				N.error("No layer selected.");
				return;
			}
			new ui.modal.dialog.Confirm(ev.getThis(), "If you delete this layer, it will be deleted in all levels as well. Are you sure?", function() {
				new ui.LastChance( L.t._("Layer ::name:: deleted", { name:cur.identifier }), project );
				var oldUid = cur.uid;
				project.defs.removeLayerDef(cur);
				select(project.defs.layers[0]);
				editor.ge.emit( LayerDefRemoved(oldUid) );
			});
		});

		select(editor.curLayerDef);
	}

	override function onGlobalEvent(e:GlobalEvent) {
		super.onGlobalEvent(e);
		switch e {
			case ProjectSettingsChanged, ProjectSelected, LevelSettingsChanged, LevelSelected:
				close();

			case LayerInstanceRestoredFromHistory(li):
				updateForm();
				updateList();

			case LayerDefAdded, LayerDefRemoved(_):
				updateList();
				updateForm();

			case LayerDefChanged:
				updateList();
				updateForm();

			case TilesetDefChanged(td):
				updateForm();

			case LayerDefSorted:
				updateList();

			case _:
		}
	}

	function select(ld:Null<led.def.LayerDef>) {
		cur = ld;
		updateForm();
		updateList();
	}

	function updateForm() {
		jForm.find("*").off(); // cleanup event listeners
		jForm.find(".tmp").remove();

		if( cur==null ) {
			jForm.hide();
			return;
		}

		JsTools.parseComponents(jForm);
		editor.selectLayerInstance( editor.curLevel.getLayerInstance(cur) );
		jForm.show();

		// Set form class
		for(k in Type.getEnumConstructs(led.LedTypes.LayerType))
			jForm.removeClass("type-"+k);
		jForm.addClass("type-"+cur.type);

		jForm.find("span.type").text( Lang.getLayerType(cur.type) );
		jForm.find("span.typeIcon").empty().append( JsTools.createLayerTypeIcon(cur.type,false) );


		// Fields
		var i = Input.linkToHtmlInput( cur.identifier, jForm.find("input[name='name']") );
		i.validityCheck = function(id) return led.Project.isValidIdentifier(id) && project.defs.isLayerNameUnique(id);
		i.validityError = N.invalidIdentifier;
		i.onChange = editor.ge.emit.bind(LayerDefChanged);

		var i = Input.linkToHtmlInput( cur.gridSize, jForm.find("input[name='gridSize']") );
		i.setBounds(1,Const.MAX_GRID_SIZE);
		i.onChange = editor.ge.emit.bind(LayerDefChanged);

		var i = Input.linkToHtmlInput( cur.displayOpacity, jForm.find("input[name='displayOpacity']") );
		i.displayAsPct = true;
		i.setBounds(0.1, 1);
		i.onChange = editor.ge.emit.bind(LayerDefChanged);

		// Layer-type specific inits
		switch cur.type {

			case IntGrid:
				var valuesList = jForm.find("ul.intGridValues");
				valuesList.find("li.value").remove();

				// Add intGrid value button
				var addButton = valuesList.find("li.add");
				addButton.find("button").off().click( function(ev) {
					cur.addIntGridValue(0xff0000);
					editor.ge.emit(LayerDefChanged);
					updateForm();
				});

				// Existing values
				var idx = 0;
				for( intGridVal in cur.getAllIntGridValues() ) {
					var curIdx = idx;
					var e = jForm.find("xml#intGridValue").clone().children().wrapAll("<li/>").parent();
					e.addClass("value");
					e.insertBefore(addButton);
					e.find(".id").html("#"+idx);

					// Edit value identifier
					var i = new form.input.StringInput(
						e.find("input.name"),
						function() return intGridVal.identifier,
						function(v) {
							if( v!=null && StringTools.trim(v).length==0 )
								v = null;
							intGridVal.identifier = led.Project.cleanupIdentifier(v, false);
						}
					);
					i.validityCheck = cur.isIntGridValueIdentifierValid;
					i.validityError = N.invalidIdentifier;
					i.onChange = editor.ge.emit.bind(LayerDefChanged);

					if( cur.countIntGridValues()>1 && idx==cur.countIntGridValues()-1 )
						e.addClass("removable");

					// Edit color
					var col = e.find("input[type=color]");
					col.val( C.intToHex(intGridVal.color) );
					col.change( function(ev) {
						cur.getIntGridValueDef(curIdx).color = C.hexToInt( col.val() );
						editor.ge.emit(LayerDefChanged);
						updateForm();
					});

					// Remove
					e.find("a.remove").click( function(ev) {
						function run() {
							cur.getAllIntGridValues().splice(curIdx,1);
							editor.ge.emit(LayerDefChanged);
							updateForm();
						}
						if( project.isIntGridValueUsed(cur, curIdx) ) {
							new ui.modal.dialog.Confirm(
								e.find("a.remove"),
								L.t._("This value is used in some levels: removing it will also remove the value from all these levels. Are you sure?"),
								true,
								run
							);
							return;
						}
						else
							run();
					});
					idx++;
				}

				// Auto-tileset selection
				var jTileset = jForm.find("[name=autoTileset]");
				jTileset.empty();

				var opt = new J("<option/>");
				opt.appendTo(jTileset);
				opt.attr("value", -1);
				opt.text("-- Select a tileset --");

				for(td in project.defs.tilesets) {
					var opt = new J("<option/>");
					opt.appendTo(jTileset);
					opt.attr("value", td.uid);
					opt.text( td.identifier );
				}
				jTileset.change( function(ev) {
					function changeTileset(clear:Bool) {
						if( clear ) {
							new LastChance(Lang.t._("Deleted all auto-layer rules"), project);
							cur.ruleGroups = [];
						}
						cur.autoTilesetDefUid = jTileset.val()=="-1" ? null : Std.parseInt( jTileset.val() );
						if( cur.autoTilesetDefUid!=null && editor.curLayerInstance.isEmpty() )
							cur.gridSize = project.defs.getTilesetDef(cur.autoTilesetDefUid).tileGridSize;
						editor.ge.emit( LayerDefChanged);
					}

					if( cur.ruleGroups.length==0 )
						changeTileset(false);
					else {
						new ui.modal.dialog.Confirm(
							jTileset,
							Lang.t._("Warning: changing the tileset will DELETE all the existing rules in this auto-layer!"),
							true,
							changeTileset.bind(true),
							updateForm
						);
					}
				});
				if( cur.autoTilesetDefUid!=null )
					jTileset.val( cur.autoTilesetDefUid );



			case Entities:

			case Tiles:
				var select = jForm.find("select[name=tilesets]");
				var jInfos = select.siblings(".infos");
				var bt = select.siblings("button.create");
				select.empty();
				jInfos.empty();

				if( project.defs.tilesets.length==0 ) {
					// No tileset in project
					select.hide();
					jInfos.hide();

					bt.show().off().click( function(_) {
						close();
						new ui.modal.panel.EditTilesetDefs();
					});
				}
				else {
					// Tileset selector
					select.show();
					bt.hide();

					if( cur.tilesetDefUid==null )
						jInfos.hide();
					else {
						jInfos.show();
						jInfos.text(project.defs.getTilesetDef(cur.tilesetDefUid).tileGridSize+"px tiles");
					}

					var opt = new J("<option/>");
					opt.appendTo(select);
					opt.attr("value", -1);
					opt.text("-- Select a tileset --");

					for(td in project.defs.tilesets) {
						var opt = new J("<option/>");
						opt.appendTo(select);
						opt.attr("value", td.uid);
						opt.text( td.identifier );
					}

					select.val( cur.tilesetDefUid==null ? -1 : cur.tilesetDefUid );

					// Change tileset
					select.change( function(ev) {
						var v = Std.parseInt( select.val() );
						if( v<0 )
							cur.tilesetDefUid = null;
						else {
							cur.tilesetDefUid = v;
							cur.gridSize = project.defs.getTilesetDef(cur.tilesetDefUid).tileGridSize;
						}
						editor.ge.emit(LayerDefChanged);
					});

					var td = project.defs.getTilesetDef(cur.tilesetDefUid);
					if( td!=null && cur.gridSize!=td.tileGridSize && ( td.tileGridSize<cur.gridSize || td.tileGridSize%cur.gridSize!=0 ) ) {
						var warn = new J('<div class="tmp warning"/>');
						warn.appendTo( select.parent() );
						warn.text(Lang.t._("Warning: the TILESET grid (::tileset::px) differs from the LAYER grid (::layer::px), and the values aren't multiples, which can lead to unexpected behaviors when adding a group of tiles.", {
							tileset: td.tileGridSize,
							layer: cur.gridSize,
						}));
					}
				}


				var jPivots = jForm.find(".pivot");
				jPivots.empty();
				var p = JsTools.createPivotEditor(cur.tilePivotX, cur.tilePivotY, 0x0, function(x,y) {
					cur.tilePivotX = x;
					cur.tilePivotY = y;
					editor.ge.emit(LayerDefChanged);
				});
				p.appendTo(jPivots);
		}
	}


	function updateList() {
		jList.empty();

		for(ld in project.defs.layers) {
			var e = new J("<li/>");
			jList.append(e);

			var icon = new J('<div class="icon"/>');
			e.append(icon);
			switch ld.type {
				case IntGrid: icon.addClass("intGrid");
				case Entities: icon.addClass("entity");
				case Tiles: icon.addClass("tile");
			}

			e.append('<span class="name">'+ld.identifier+'</span>');
			if( cur==ld )
				e.addClass("active");

			e.click( function(_) select(ld) );
		}

		// Make layer list sortable
		JsTools.makeSortable(jList, function(ev) {
			var moved = project.defs.sortLayerDef(ev.oldIndex, ev.newIndex);
			select(moved);
			editor.ge.emit(LayerDefSorted);
		});
	}
}
