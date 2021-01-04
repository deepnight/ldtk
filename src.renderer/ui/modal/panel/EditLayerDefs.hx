package ui.modal.panel;

class EditLayerDefs extends ui.modal.Panel {
	var jList : js.jquery.JQuery;
	var jForm : js.jquery.JQuery;
	public var cur : Null<data.def.LayerDef>;

	public function new() {
		super();

		loadTemplate( "editLayerDefs", "defEditor layerDefs" );
		jList = jModalAndMask.find(".mainList ul");
		jForm = jModalAndMask.find("ul.form");
		linkToButton("button.editLayers");

		// Create layer
		jModalAndMask.find(".mainList button.create").click( function(ev) {
			function _create(type:ldtk.Json.LayerType) {
				var ld = project.defs.createLayerDef(type);
				select(ld);
				editor.ge.emit(LayerDefAdded);
				jForm.find("input").first().focus().select();
			}

			// Type picker
			var w = new ui.modal.Dialog(ev.getThis(),"layerTypes");
			for(k in ldtk.Json.LayerType.getConstructors()) {
				var type = ldtk.Json.LayerType.createByName(k);
				var b = new J("<button/>");
				b.appendTo( w.jContent );
				b.append( JsTools.createLayerTypeIconAndName(type) );
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
				deleteLayer(cur);
			});
		});

		select(editor.curLayerDef);
	}

	function deleteLayer(ld:data.def.LayerDef, bypassConfirm=false) {
		if( !bypassConfirm && project.defs.isLayerSourceOfAnotherOne(ld) ) {
			new ui.modal.dialog.Confirm(
				L.t._("Warning! This IntGrid layer is used by another one as SOURCE. Deleting it will also delete all rules in the corresponding auto-layer(s)!\n You may want to change these layers source to another one before..."),
				true,
				deleteLayer.bind(ld,true)
			);
			return;
		}
		new ui.LastChance(
			L.t._("Layer ::name:: deleted", { name:ld.identifier }),
			project
		);
		var oldUid = ld.uid;
		project.defs.removeLayerDef(ld);
		select(project.defs.layers[0]);
		editor.ge.emit( LayerDefRemoved(oldUid) );
	}



	function bakeLayer(ld:data.def.LayerDef) {
		for(other in project.defs.layers)
			if( other.autoSourceLayerDefUid==ld.uid ) {
				new ui.modal.dialog.Message(L.t._("This layer cannot be baked, as other auto-layers rely on this one as source for their data."));
				return;
			}
		// Backup project
		var oldProject = data.Project.fromJson( project.toJson() );

		// Update layer instances
		var ops : Array<ui.modal.Progress.ProgressOp> = [];
		for(l in project.levels) {
			var li = l.getLayerInstance(ld);
			ops.push({
				label: l.identifier,
				cb: ()->{
					ld.iterateActiveRulesInDisplayOrder( (r)->{
						if( li.autoTilesCache.exists( r.uid ) ) {
							for( allTiles in li.autoTilesCache.get( r.uid ).keyValueIterator() )
							for( tileInfos in allTiles.value ) {
								li.addGridTile(
									Std.int(tileInfos.x/ld.gridSize),
									Std.int(tileInfos.y/ld.gridSize),
									tileInfos.tid,
									tileInfos.flips
								);
							}
						}
					});
					li.autoTilesCache = null;
				}
			});
		}

		// Execute ops
		new Progress(
			L.t._("Baking layer instances"),
			ops,
			()->{
				// Done, update layer def
				ld.type = Tiles;
				ld.tilesetDefUid = ld.autoTilesetDefUid;
				ld.autoRuleGroups = [];
				ld.autoSourceLayerDefUid = null;
				ld.autoTilesetDefUid = null;

				select(ld);
				editor.ge.emit( LayerInstanceChanged );
				editor.ge.emit( LayerDefConverted );
				new LastChance( L.t._("Baked layer ::name::", {name:ld.identifier}), oldProject );
			}
		);
	}



	override function onGlobalEvent(e:GlobalEvent) {
		super.onGlobalEvent(e);
		switch e {
			case ProjectSettingsChanged, ProjectSelected, LevelSettingsChanged(_), LevelSelected(_):
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

	function select(ld:Null<data.def.LayerDef>) {
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

		editor.selectLayerInstance( editor.curLevel.getLayerInstance(cur) );
		jForm.show();
		jForm.find("#gridSize").prop("readonly",false);

		// Set form class
		for(k in Type.getEnumConstructs(ldtk.Json.LayerType))
			jForm.removeClass("type-"+k);
		jForm.addClass("type-"+cur.type);
		if( cur.type==IntGrid && cur.isAutoLayer() )
			jForm.addClass("type-IntGridAutoLayer");

		jForm.find("span.typeIcon").empty().append( JsTools.createLayerTypeIconAndName(cur.type) );


		// Fields
		var i = Input.linkToHtmlInput( cur.identifier, jForm.find("input[name='name']") );
		i.validityCheck = function(id) return data.Project.isValidIdentifier(id) && project.defs.isLayerNameUnique(id);
		i.validityError = N.invalidIdentifier;
		i.onChange = editor.ge.emit.bind(LayerDefChanged);

		var i = Input.linkToHtmlInput( cur.gridSize, jForm.find("input[name='gridSize']") );
		i.setBounds(1,Const.MAX_GRID_SIZE);
		i.onChange = editor.ge.emit.bind(LayerDefChanged);

		var i = Input.linkToHtmlInput( cur.displayOpacity, jForm.find("input[name='displayOpacity']") );
		i.displayAsPct = true;
		i.setBounds(0.1, 1);
		i.onChange = editor.ge.emit.bind(LayerDefChanged);

		var i = Input.linkToHtmlInput( cur.pxOffsetX, jForm.find("input[name='offsetX']") );
		i.onChange = editor.ge.emit.bind(LayerDefChanged);

		var i = Input.linkToHtmlInput( cur.pxOffsetY, jForm.find("input[name='offsetY']") );
		i.onChange = editor.ge.emit.bind(LayerDefChanged);


		// Baking
		if( cur.isAutoLayer() ) {
			var jButton = jForm.find("button.bake");
			jButton.click( (_)->{
				if( !cur.autoLayerRulesCanBeUsed() )
					new ui.modal.dialog.Message(L.t._("Errors in current layer settings prevent rules to be applied. It can't be baked now."));
				else
					new ui.modal.dialog.Confirm(
						jButton,
						L.t._("Transform this layer into a traditional Tile layer?"),
						true,
						()->bakeLayer(cur)
					);
			});
		}


		// Layer-type specific inits
		function initAutoTilesetSelect() {

			var jTileset = jForm.find("[name=autoTileset]");
			jTileset.empty();
			jTileset.removeClass("required");
			jTileset.removeClass("noValue");

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
				var newTilesetUid = jTileset.val()=="-1" ? null : Std.parseInt( jTileset.val() );

				if( cur.autoRuleGroups.length!=0 )
					new LastChance(Lang.t._("Changed auto-layer tileset"), project);

				cur.autoTilesetDefUid = newTilesetUid;
				if( cur.autoTilesetDefUid!=null && editor.curLayerInstance.isEmpty() )
					cur.gridSize = project.defs.getTilesetDef(cur.autoTilesetDefUid).tileGridSize;

				// TODO cleanup rules with invalid tileIDs

				editor.ge.emit( LayerDefChanged);
			});
			if( cur.autoTilesetDefUid!=null )
				jTileset.val( cur.autoTilesetDefUid );
			else
				jTileset.addClass("noValue");
		}

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
							intGridVal.identifier = data.Project.cleanupIdentifier(v, false);
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
							project.tidy();
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

				initAutoTilesetSelect();

			case AutoLayer:
				// Linked layer
				var jSelect = jForm.find("select[name=autoLayerSources]");
				jSelect.empty();

				var opt = new J("<option/>");
				opt.appendTo(jSelect);
				opt.attr("value", -1);
				opt.text("-- Select an IntGrid layer --");

				var intGridLayers = project.defs.layers.filter( function(ld) return ld.type==IntGrid );
				for( ld in intGridLayers ) {
					var opt = new J("<option/>");
					opt.appendTo(jSelect);
					opt.attr("value", ld.uid);
					opt.text(ld.identifier);
				}

				jSelect.val( cur.autoSourceLayerDefUid==null ? -1 : cur.autoSourceLayerDefUid );
				if( cur.autoSourceLayerDefUid==null )
					jSelect.addClass("required");
				else
					jSelect.removeClass("required");

				// Change linked layer
				jSelect.change( function(ev) {
					var v = Std.parseInt( jSelect.val() );
					if( v<0 )
						cur.autoSourceLayerDefUid = null;
					else {
						var source = project.defs.getLayerDef(v);
						for(rg in cur.autoRuleGroups)
						for(r in rg.rules) {
							if( r.isUsingUnknownIntGridValues(source) )
								App.LOG.error(r+" intGrid value not found in "+source);
						}

						cur.autoSourceLayerDefUid = v;
						cur.gridSize = project.defs.getLayerDef(v).gridSize;
					}
					editor.ge.emit(LayerDefChanged);
				});

				jForm.find("#gridSize").prop("readonly",true);

				// Tileset
				initAutoTilesetSelect();
				var jSelect = jForm.find("[name=autoTileset]");
				if( cur.autoTilesetDefUid==null )
					jSelect.addClass("required");



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

		JsTools.parseComponents(jForm);

	}


	function updateList() {
		jList.empty();

		for(ld in project.defs.layers) {
			var e = new J("<li/>");
			jList.append(e);

			e.append( JsTools.createLayerTypeIcon2(ld.type) );

			e.append('<span class="name">'+ld.identifier+'</span>');
			if( cur==ld )
				e.addClass("active");

			ContextMenu.addTo(e, [
				{
					label: L._Duplicate(),
					cb: ()->{
						project.defs.duplicateLayerDef(ld);
						editor.checkAutoLayersCache( (_)->{} );
						editor.ge.emit(LayerDefAdded);
					},
				},
				{
					label: L._Delete(),
					cb: ()->deleteLayer(ld),
				}
			]);

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
