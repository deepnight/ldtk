package ui.modal.panel;

enum BakeMethod {
	DeleteBakedLayer;
	EmptyBakedLayer;
	KeepBakedLayer;
}

class EditLayerDefs extends ui.modal.Panel {
	var jList : js.jquery.JQuery;
	var jForms : js.jquery.JQuery;
	var jFormsWrapper : js.jquery.JQuery;
	public var cur : Null<data.def.LayerDef>;
	var search : QuickSearch;
	var intGridValuesIconsTdUid : Null<Int>;

	public function new() {
		super();

		loadTemplate( "editLayerDefs", "defEditor editLayerDefs",  {
			tilesUrl: Const.DOCUMENTATION_URL+"/tutorials/tile-layers",
			autoLayersUrl: Const.DOCUMENTATION_URL+"/tutorials/auto-layers",
		} );
		jList = jModalAndMask.find(".mainList ul");
		jForms = jModalAndMask.find("dl.form");
		jFormsWrapper = jModalAndMask.find(".rightColumn");
		linkToButton("button.editLayers");

		// Create layer
		jModalAndMask.find(".mainList button.create").click( function(ev) {
			function _create(type:ldtk.Json.LayerType) {
				var ld = project.defs.createLayerDef(type);
				select(ld);
				editor.ge.emit(LayerDefAdded);
				jForms.find("input").first().focus().select();
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

				var jDesc = new J('<div class="desc"/>');
				jDesc.appendTo(w.jContent);
				var desc = switch type {
					case IntGrid: "Contains grids of Integer numbers (ie. 1, 2, 3 etc.). It can be used to mark collisions in your levels or various other informations. It can be also rendered automatically to tiles using dynamic rules.";
					case Entities: "Contains Entity instances, which are generic objects such as the Player start position or Items to pick up.";
					case Tiles: "Contains image tiles picked from a Tileset.";
					case AutoLayer: "This special layer is rendered automatically using dynamic rules and an IntGrid layer as source for its data.";
				}
				jDesc.text(desc);
			}

		});

		// Create quick search
		search = new ui.QuickSearch( jContent.find(".mainList ul") );
		search.jWrapper.appendTo( jContent.find(".search") );

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
		editor.ge.emit( LayerDefRemoved(oldUid) );
		select(project.defs.layers[0]);
	}



	function bakeLayer(ld:data.def.LayerDef, ?method:BakeMethod) {
		for(other in project.defs.layers)
			if( other.autoSourceLayerDefUid==ld.uid ) {
				new ui.modal.dialog.Message(L.t._("This layer cannot be baked, as at least one other auto-layer rely on it as 'source' for its data."));
				return;
			}

		if( method==null ) {
			new ui.modal.dialog.Choice(
				L.t._("'Baking' an auto-layer will flatten it to create a new regular 'Tiles layer'. The copy will contain all the tiles generated from the auto-layer rules.\nWhat would you like to do with the original layer after baking it?"),
				[
					{ label:L.t._("Bake, then delete original layer"), cb:bakeLayer.bind(ld,DeleteBakedLayer) },
					{ label:L.t._("Bake, then empty original layer"), cb:bakeLayer.bind(ld,EmptyBakedLayer), cond:()->ld.type!=AutoLayer },
					{ label:L.t._("Keep both baked result and original"), cb:bakeLayer.bind(ld,KeepBakedLayer) },
				]
			);
			return;
		}

		// Backup project
		var oldProject = project.clone();

		// Create new baked layer
		var newLd = project.defs.duplicateLayerDef(ld, ld.identifier+"_baked");
		newLd.type = Tiles;
		newLd.autoRuleGroups = [];
		newLd.autoSourceLayerDefUid = null;
		newLd.tilesetDefUid = ld.tilesetDefUid;

		// Update layer instances
		var td = project.defs.getTilesetDef(newLd.tilesetDefUid);
		var ops : Array<ui.modal.Progress.ProgressOp> = [];
		for(w in project.worlds)
		for(l in w.levels) {
			var sourceLi = l.getLayerInstance(ld);
			var newLi = l.getLayerInstance(newLd);
			ops.push({
				label: l.identifier,
				cb: ()->{
					ld.iterateActiveRulesInDisplayOrder( newLi, (r)->{ // TODO not sure which "li" should be used here
						if( sourceLi.autoTilesCache.exists( r.uid ) ) {
							for( allTiles in sourceLi.autoTilesCache.get( r.uid ).keyValueIterator() )
							for( tileInfos in allTiles.value ) {
								newLi.addGridTile(
									Std.int(tileInfos.x/ld.gridSize),
									Std.int(tileInfos.y/ld.gridSize),
									tileInfos.tid,
									tileInfos.flips,
									!td.isTileOpaque(tileInfos.tid),
									false
								);
							}
						}
					});
					switch method {
						case null:
						case DeleteBakedLayer:
						case EmptyBakedLayer:
							@:privateAccess sourceLi.intGrid = new Map();
							sourceLi.autoTilesCache = null;
						case KeepBakedLayer:
					}

					editor.ge.emit( LayerInstanceChangedGlobally(newLi) );
				}
			});
		}

		// Execute ops
		new Progress(
			L.t._("Baking layer instances"),
			ops,
			()->{
				select(newLd);

				// Done, update layer def
				switch method {
					case null:
					case DeleteBakedLayer:
						project.defs.removeLayerDef(ld);
						editor.ge.emit( LayerDefRemoved(ld.uid) );

					case EmptyBakedLayer:
					case KeepBakedLayer:
				}

				editor.ge.emit( LayerDefAdded );
				new LastChance( L.t._("Baked layer ::name::", {name:ld.identifier}), oldProject );
			}
		);
	}



	override function onGlobalEvent(e:GlobalEvent) {
		super.onGlobalEvent(e);
		switch e {
			case ProjectSettingsChanged, ProjectSelected, LevelSettingsChanged(_), LevelSelected(_):
				close();

			case LayerInstancesRestoredFromHistory(_):
				updateForm();
				updateList();

			case LayerDefAdded, LayerDefRemoved(_):
				updateList();
				updateForm();

			case LayerDefChanged(defUid, contentInvalidated):
				updateList();
				updateForm();

			case TilesetDefChanged(td):
				updateForm();

			case LayerDefSorted:
				updateList();

			case LayerDefIntGridValuesSorted(defUid,groupChanged):
				updateForm();

			case LayerDefIntGridValueAdded(defUid,value):
				updateForm();
				jForms.find("ul.intGridValues li.value:last .name").focus();

			case LayerDefIntGridValueRemoved(defUid,value,used):
				updateForm();

			case _:
		}
	}

	public function select(ld:Null<data.def.LayerDef>) {
		cur = ld;
		intGridValuesIconsTdUid = null;
		updateForm();
		updateList();
	}

	function updateForm() {
		Tip.clear();
		jForms.find("*").off(); // cleanup event listeners
		jForms.find(".tmp").remove();

		if( cur==null ) {
			jContent.find(".none").show();
			jFormsWrapper.hide();
			return;
		}
		jContent.find(".none").hide();


		// Lost layer
		if( project.defs.getLayerDef(cur.uid)==null ) {
			select( project.defs.layers[0] );
			return;
		}

		editor.selectLayerInstance( editor.curLevel.getLayerInstance(cur) );
		jFormsWrapper.show();
		jForms.find("#gridSize").prop("readonly",false);

		// Set form class
		for(k in Type.getEnumConstructs(ldtk.Json.LayerType))
			jForms.removeClass("type-"+k);
		jForms.removeClass("type-IntGridAutoLayer");
		jForms.addClass("type-"+cur.type);
		if( cur.type==IntGrid && cur.isAutoLayer() )
			jForms.addClass("type-IntGridAutoLayer");

		jForms.find("span.typeIcon").empty().append( JsTools.createLayerTypeIconAndName(cur.type) );

		jContent.find("#typeSpecificTitle").text( cur.type.getName() );


		// Identifier
		var i = Input.linkToHtmlInput( cur.identifier, jForms.find("input[name='name']") );
		i.fixValue = (v)->project.fixUniqueIdStr(v, (id)->project.defs.isLayerNameUnique(id,cur));
		i.onChange = editor.ge.emit.bind( LayerDefChanged(cur.uid,false) );

		// Doc
		var i = Input.linkToHtmlInput( cur.doc, jForms.find("input[name='layerDoc']") );
		i.allowNull = true;
		i.onChange = editor.ge.emit.bind( LayerDefChanged(cur.uid, false) );

		// UI color
		var jCol = jForms.find("#uiColor");
		jCol.removeClass("null");
		if( cur.uiColor!=null )
			jCol.val(cur.uiColor.toHex());
		else {
			jCol.val("black");
			jCol.addClass("null");
		}
		jCol.change(_->{
			cur.uiColor = dn.Col.parseHex( jCol.val() );
			editor.ge.emit( LayerDefChanged(cur.uid, false) );
		});
		jForms.find(".resetUiColor").click(_->{
			cur.uiColor = null;
			editor.ge.emit( LayerDefChanged(cur.uid, false) );
		}).css("display", cur.uiColor==null ? "none" : "block");

		// Grid
		var i = Input.linkToHtmlInput( cur.gridSize, jForms.find("input[name='gridSize']") );
		i.setBounds(1,Const.MAX_GRID_SIZE);
		i.onBeforeSetter = (newGrid)->{
			new LastChance(L.t._("Layer grid changed"), project);

			for(w in project.worlds)
			for(l in w.levels)
			for(li in l.layerInstances) {
				if( li.layerDefUid==cur.uid )
					li.remapToGridSize(cur.gridSize, newGrid);

				if( li.def.autoSourceLayerDefUid==cur.uid )
					li.remapToGridSize(cur.gridSize, newGrid);
			}
		}
		i.onChange = ()->{
			project.recountIntGridValuesInAllLayerInstances();

			editor.ge.emit( LayerDefChanged(cur.uid, false) );

			for(ld in project.defs.layers)
				if( ld.autoSourceLayerDefUid==cur.uid ) {
					ld.gridSize = cur.gridSize;
					editor.ge.emit( LayerDefChanged(ld.uid, false) );
				}
		}

		var i = Input.linkToHtmlInput( cur.guideGridWid, jForms.find("input[name='guideGridWid']") );
		i.setBounds(0,Const.MAX_GRID_SIZE);
		i.onChange = editor.ge.emit.bind(LayerDefChanged(cur.uid, false));
		i.fixValue = v->return v<=1 ? 0 : v;
		i.setEmptyValue(0);

		var i = Input.linkToHtmlInput( cur.guideGridHei, jForms.find("input[name='guideGridHei']") );
		i.setBounds(0,Const.MAX_GRID_SIZE);
		i.onChange = editor.ge.emit.bind(LayerDefChanged(cur.uid, false));
		i.fixValue = v->return v<=1 ? 0 : v;
		i.setEmptyValue(0);

		var i = Input.linkToHtmlInput( cur.displayOpacity, jForms.find("input[name='displayOpacity']") );
		i.enablePercentageMode();
		i.setBounds(0.1, 1);
		i.onChange = editor.ge.emit.bind(LayerDefChanged(cur.uid, false));

		var i = Input.linkToHtmlInput( cur.inactiveOpacity, jForms.find("input[name='inactiveOpacity']") );
		i.enablePercentageMode();
		i.setBounds(0, 1);
		i.onChange = editor.ge.emit.bind(LayerDefChanged(cur.uid, false));

		var i = Input.linkToHtmlInput( cur.hideInList, jForms.find("input[name='hideInList']") );
		i.onChange = editor.ge.emit.bind(LayerDefChanged(cur.uid, false));

		var i = Input.linkToHtmlInput( cur.canSelectWhenInactive, jForms.find("input[name='canSelectWhenInactive']") );
		i.onChange = editor.ge.emit.bind(LayerDefChanged(cur.uid, false));

		// UI tags
		var ted = new TagEditor(
			cur.uiFilterTags,
			()->editor.ge.emit(LayerDefChanged(cur.uid, false)),
			()->project.defs.getRecallTags(project.defs.layers, ld->ld.uiFilterTags),
			()->return project.defs.layers.map( ld->ld.uiFilterTags )
		);
		jForms.find("#uiFilterTags").empty().append(ted.jEditor);

		var i = Input.linkToHtmlInput( cur.renderInWorldView, jForms.find("input[name='renderInWorldView']") );
		i.onChange = ()->{
			editor.worldRender.invalidateAll();
			editor.ge.emit(LayerDefChanged(cur.uid, false));
		}

		var i = Input.linkToHtmlInput( cur.useAsyncRender, jForms.find("input[name='useAsyncRender']") );
		i.onChange = ()->{
			editor.worldRender.invalidateAll();
			editor.ge.emit(LayerDefChanged(cur.uid, false));
		}

		var i = Input.linkToHtmlInput( cur.hideFieldsWhenInactive, jForms.find("input[name='hideFieldsWhenInactive']") );
		i.onChange = editor.ge.emit.bind(LayerDefChanged(cur.uid, false));

		var i = Input.linkToHtmlInput( cur.pxOffsetX, jForms.find("input[name='offsetX']") );
		i.onChange = editor.ge.emit.bind(LayerDefChanged(cur.uid, true));

		var i = Input.linkToHtmlInput( cur.pxOffsetY, jForms.find("input[name='offsetY']") );
		i.onChange = editor.ge.emit.bind(LayerDefChanged(cur.uid, true));

		var equal = cur.parallaxFactorX==cur.parallaxFactorY;
		var i = Input.linkToHtmlInput( cur.parallaxFactorX, jForms.find("input[name='parallaxFactorX']") );
		i.setBounds(-1,1);
		i.enablePercentageMode(false);
		i.onChange = ()->{
			if( equal )
				cur.parallaxFactorY = cur.parallaxFactorX;
			editor.ge.emit(LayerDefChanged(cur.uid, false));
		}

		var i = Input.linkToHtmlInput( cur.parallaxFactorY, jForms.find("input[name='parallaxFactorY']") );
		i.setBounds(-1,1);
		i.enablePercentageMode(false);
		if( equal )
			i.jInput.addClass("grayed");
		else
			i.jInput.removeClass("grayed");
		i.setEnabled(!cur.parallaxScaling);
		i.allowNull = true;
		i.fixValue = v->{
			return v==null ? cur.parallaxFactorX*100 : v;
		}
		i.onChange = ()->{
			editor.ge.emit(LayerDefChanged(cur.uid, false));
		}

		var i = Input.linkToHtmlInput( cur.parallaxScaling, jForms.find("input#parallaxScaling") );
		i.onChange = ()->{
			if( cur.parallaxScaling )
				cur.parallaxFactorY = cur.parallaxFactorX;
			editor.ge.emit(LayerDefChanged(cur.uid, false));
		}

		var i = Input.linkToHtmlInput( cur.pxOffsetY, jForms.find("input[name='offsetY']") );
		i.onChange = editor.ge.emit.bind( LayerDefChanged(cur.uid, false) );


		// Edit rules
		var jButton = jForms.find("button.editAutoRules");
		if( cur.autoLayerRulesCanBeUsed() ) {
			jButton.show();

			jButton.click( (_)->{
				close();
				var li = editor.curLevel.getLayerInstance(cur);
				editor.selectLayerInstance(li);
				new ui.modal.panel.EditAllAutoLayerRules(li);
			});
		}
		else
			jButton.hide();


		// Baking
		if( cur.isAutoLayer() ) {
			var jButton = jForms.find("button.bake");
			jButton.click( (_)->{
				if( !cur.autoLayerRulesCanBeUsed() )
					new ui.modal.dialog.Message(L.t._("Errors in current layer settings prevent rules to be applied. It can't be baked now."));
				else
					bakeLayer(cur);
			});
		}


		// Layer-type specific inits
		function initAutoLayerSelects() {
			// Auto-layer tileset
			JsTools.createTilesetSelect(
				project,
				jForms.find("[name=autoTileset]"),
				cur.tilesetDefUid,
				true,
				(uid)->{
					if( cur.autoRuleGroups.length!=0 )
						new LastChance(Lang.t._("Changed auto-layer tileset"), project);

					cur.tilesetDefUid = uid;
					if( cur.tilesetDefUid!=null && editor.curLayerInstance.isEmpty() )
						cur.gridSize = project.defs.getTilesetDef(cur.tilesetDefUid).tileGridSize;

					// TODO cleanup rules with invalid tileIDs

					editor.ge.emit( LayerDefChanged(cur.uid, true) );
				}
			);

			// Biome field select
			var enumFieldUids = project.defs.levelFields.filter( f->f.isEnum() ).map( f->f.uid );
			JsTools.createValuesSelect(
				jForms.find("[name=biomeField]"),
				cur.biomeFieldUid,
				enumFieldUids,
				true,
				(uid)->{
					if( uid==null )
						return "No biome enum";
					var fd = project.defs.getFieldDef(uid);
					return fd.identifier+" ("+fd.getEnumDefinition().identifier+")";
				},
				(uid)->{
					if( cur.autoRuleGroups.length!=0 )
						new LastChance(Lang.t._("Changed auto-layer biome enum"), project);

					cur.biomeFieldUid = uid;
					editor.ge.emit( LayerDefChanged(cur.uid,true) );
					cur.tidy(project);
				}
			);

			// Auto-kill tiles
			var jSelect = jForms.find("select[name=autoKillLayer]");
			jSelect.empty();

			var opt = new J("<option/>");
			opt.appendTo(jSelect);
			opt.attr("value", -1);
			opt.text("-- Select a Tile layer --");

			var otherLayers = project.defs.layers.filter( function(ld) return ld.type==Tiles );
			for( ld in otherLayers ) {
				var opt = new J("<option/>");
				opt.appendTo(jSelect);
				opt.attr("value", ld.uid);
				opt.text(ld.identifier);
			}

			jSelect.val( cur.autoTilesKilledByOtherLayerUid==null ? -1 : cur.autoTilesKilledByOtherLayerUid );

			jSelect.change( function(ev) {
				var v = Std.parseInt( jSelect.val() );
				if( v<0 )
					cur.autoTilesKilledByOtherLayerUid = null;
				else {
					cur.autoTilesKilledByOtherLayerUid = v;
					// TODO kill immediately
				}
				editor.ge.emit(LayerDefChanged(cur.uid, true));
			});
		}

		switch cur.type {

			case IntGrid:
				// Guess icons tileset UID
				if( intGridValuesIconsTdUid==null )
					for(v in cur.getAllIntGridValues())
						if( v.tile!=null ) {
							intGridValuesIconsTdUid = v.tile.tilesetUid;
							break;
						}

				// Icons tileset
				var jSelect = jForms.find(".valuesIconsTileset");
				JsTools.createTilesetSelect(project, jSelect, intGridValuesIconsTdUid, true, "No icon", (tilesetDefUid)->{
					for(iv in cur.getAllIntGridValues())
						iv.tile = null;

					intGridValuesIconsTdUid = tilesetDefUid==null || tilesetDefUid<0 ? null : tilesetDefUid;
					updateForm();
				});


				var jIntGridValuesWrapper = jForms.find("dd.intGridValues");
				var jAllGroups = jIntGridValuesWrapper.find("ul.intGridValuesGroups");
				jAllGroups.empty();

				// Add intGrid value button
				jIntGridValuesWrapper.find(".addValue").off().click( _->{
					var col = Const.suggestNiceColor( cur.getAllIntGridValues().map(iv->iv.color) );
					var iv = cur.addIntGridValue(col);
					editor.ge.emit( LayerDefIntGridValueAdded(cur.uid,iv) );
				});

				// Add intGrid group button
				jIntGridValuesWrapper.find(".addGroup").off().click( _->{
					cur.addIntGridGroup();
					editor.ge.emit( LayerDefChanged(cur.uid,false) );
				});

				// Grouped intGrid values
				var groupedValues = cur.getGroupedIntGridValues();
				for(g in groupedValues) {
					var jGroupWrapper = jForms.find("xml#intGridValuesGroup").clone().children().wrapAll("<li/>").parent();
					jGroupWrapper.appendTo(jAllGroups);

					if( g.color!=null )
						jGroupWrapper.css('background-color', g.color.toCssRgba(0.7));

					if( g.groupUid!=0 )
						jGroupWrapper.addClass("draggable");

					var jAdd = jGroupWrapper.find(".addGroupValue");
					jAdd.click(_->{
						var col = Const.suggestNiceColor( cur.getAllIntGridValues().map(iv->iv.color) );
						var iv = cur.addIntGridValue(col);
						var v = cur.getIntGridValueDef(iv);
						v.groupUid = g.groupUid;
						editor.ge.emit( LayerDefIntGridValueAdded(cur.uid,iv) );
					});

					// Group header
					var jGroupHeader = jGroupWrapper.find(".header");
					if( groupedValues.length==1 )
						jGroupHeader.hide();
					var jIcon = jGroupHeader.find(".groupIcon");
					var jName = jGroupHeader.find(".name");
					switch g.groupUid {
						case 0 :
							jGroupWrapper.addClass("none");
							jName.text(g.displayName);

						case _ :
							// Editable group name
							jName.addClass("editable");
							jName.text(g.displayName);
							jName.click(_->{
								var jInput = new J('<input type="text"/>');
								jInput.insertAfter(jName);
								jName.hide();
								// jName.replaceWith(jInput);
								jInput.focus();
								if( g.groupInf.identifier==null )
									jInput.attr("placeholder", g.displayName);

								if( g.groupInf.identifier!=null )
									jInput.val(g.groupInf.identifier);

								var original = jInput.val();
								jInput.blur(_->{
									if( jInput.val()==original ) {
										jName.show();
										jInput.remove();
										return;
									}
									var identifier = data.Project.cleanupIdentifier(jInput.val(), Free);
									g.groupInf.identifier = identifier;
									editor.ge.emit( LayerDefChanged(cur.uid,false) );
								});

								jInput.keydown((ev:js.jquery.Event)->{
									switch ev.key {
										case "Enter": jInput.blur();
										case _:
									}
								});
							});

							var act : Array<ui.modal.ContextMenu.ContextAction> = [
								{ // Delete group
									label: L._Delete(L.t._("group")),
									enable: ()->g.groupUid>0,
									cb: ()->{
										if( g.all.length>0 ) {
											// Move all values back to "ungrouped"
											new ui.modal.dialog.Confirm(
												L.t._("Deleting this group will move all its values back to \"UNGROUPED\". Confirm?"),
												true,
												()->{
													for(iv in g.all)
														iv.groupUid = 0;
													cur.removeIntGridGroup(g.groupUid);
													editor.ge.emitAtTheEndOfFrame( LayerDefChanged(cur.uid, true) );
												}
											);
										}
										else {
											// Empty group
											cur.removeIntGridGroup(g.groupUid);
											editor.ge.emit( LayerDefChanged(cur.uid, false) );
										}
									}
								},
								{ // Custom color
									label: L.t._("Set group color"),
									cb: ()->{
										var cp = new ui.modal.dialog.ColorPicker( Const.getNicePalette(), g.color, true );
										cp.onValidate = (c)->{
											g.groupInf.color = c.toHex();
											editor.ge.emit( LayerDefChanged(cur.uid, false) );
										}
									},
								},
								{ // Remove custom color
									label: L.t._("Remove group color"),
									show: ()->g.color!=null,
									cb: ()->{
										g.groupInf.color = null;
										editor.ge.emit( LayerDefChanged(cur.uid, false) );
									},
								},
							];
							ContextMenu.attachTo(jGroupHeader, act);
					}

					var jGroup = jGroupWrapper.find(".intGridValuesGroup");
					jGroup.attr("groupUid", Std.string(g.groupUid));

					// IntGrid values
					for( intGridVal in g.all ) {
						var jValue = jForms.find("xml#intGridValue").clone().children().wrapAll("<li/>").parent();
						jValue.attr("valueId", Std.string(intGridVal.value));
						jValue.addClass("value");
						jValue.appendTo(jGroup);
						jValue.find(".id")
							.html( Std.string(intGridVal.value) )
							.css({
								color: C.intToHex( C.toWhite(intGridVal.color,0.5) ),
								borderColor: C.intToHex( C.toWhite(intGridVal.color,0.2) ),
								backgroundColor: C.intToHex( C.toBlack(intGridVal.color,0.5) ),
							});

						// Tile
						var jTile = jValue.find(".tile");
						if( intGridValuesIconsTdUid!=null )
							jTile.append( JsTools.createTileRectPicker(intGridValuesIconsTdUid, intGridVal.tile, true, (r)->{
								intGridVal.tile = r;
								editor.ge.emit( LayerDefChanged(cur.uid, false) );
							}));

						// Edit value identifier
						var i = new form.input.StringInput(
							jValue.find("input.name"),
							function() return intGridVal.identifier,
							function(v) {
								if( v!=null && StringTools.trim(v).length==0 )
									v = null;
								intGridVal.identifier = data.Project.cleanupIdentifier(v, Free);
							}
						);
						i.validityCheck = cur.isIntGridValueIdentifierValid;
						i.validityError = N.invalidIdentifier;
						i.onChange = editor.ge.emit.bind(LayerDefChanged(cur.uid, false));
						i.jInput.css({
							backgroundColor: C.intToHex( C.toBlack(intGridVal.color,0.7) ),
						});

						// Edit color
						var col = jValue.find("input[type=color]");
						col.val( C.intToHex(intGridVal.color) );
						col.change( function(ev) {
							cur.getIntGridValueDef(intGridVal.value).color = C.hexToInt( col.val() );
							editor.ge.emit(LayerDefChanged(cur.uid, false));
							updateForm();
						});

						// Remove
						jValue.find("button.remove").click( function(ev:js.jquery.Event) {
							var jThis = ev.getThis();
							var isUsed = project.isIntGridValueUsed(cur, intGridVal.value);
							function run() {
								if( isUsed )
									new LastChance(L.t._("IntGrid value removed"), project);
								cur.removeIntGridValue(intGridVal.value);
								project.tidy();
								editor.ge.emit( LayerDefIntGridValueRemoved(cur.uid, intGridVal.value, isUsed) );
							}
							if( isUsed ) {
								new ui.modal.dialog.Confirm(
									jThis,
									L.t._("This value is used in some levels: removing it will also remove the value from all these levels. Are you sure?"),
									true,
									run
								);
								return;
							}
							else
								run();
						});
					}

					// Make intGrid values sortable
					JsTools.makeSortable(jGroup, "allIntGroups", (ev:sortablejs.Sortable.SortableDragEvent)->{
						var fromGroupUid = Std.parseInt( ev.from.getAttribute("groupUid") );
						var toGroupUid = Std.parseInt( ev.to.getAttribute("groupUid") );
						var valueId = Std.parseInt( ev.item.getAttribute("valueId") );
						var iv = cur.getIntGridValueDef(valueId);

						if( iv.groupUid!=fromGroupUid )
							return; // Prevent double "onSort" call (one for From, one for To)

						var moved = cur.sortIntGridValueDef(valueId, fromGroupUid, toGroupUid, ev.oldIndex, ev.newIndex);
						editor.ge.emit( LayerDefIntGridValuesSorted(cur.uid, moved.groupUid!=fromGroupUid) );
					});
				}


				// Make intGrid groups sortable
				if( groupedValues.length>1 )
					JsTools.makeSortable(
						jAllGroups,
						(ev:sortablejs.Sortable.SortableDragEvent)->{
							var moved = cur.sortIntGridValueGroupDef(ev.oldIndex-1, ev.newIndex-1);
							editor.ge.emit( LayerDefIntGridValuesSorted(cur.uid, false) );
						},
						{ onlyDraggables: true }
					);

				initAutoLayerSelects();

			case AutoLayer:
				// Linked layer
				var jSelect = jForms.find("select[name=autoLayerSources]");
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
					editor.ge.emit(LayerDefChanged(cur.uid,true));
				});

				jForms.find("#gridSize").prop("readonly",true);

				// Tileset
				initAutoLayerSelects();
				var jSelect = jForms.find("[name=autoTileset]");
				if( cur.tilesetDefUid==null )
					jSelect.addClass("required");



			case Entities:
				// Tags
				var ted = new ui.TagEditor(
					cur.requiredTags,
					()->editor.ge.emit(LayerDefChanged(cur.uid,false)),
					()->project.defs.getRecallEntityTags([cur.requiredTags, cur.excludedTags]),
					false
				);
				jForms.find("#requiredTags").empty().append( ted.jEditor );

				var ted = new ui.TagEditor(
					cur.excludedTags,
					()->editor.ge.emit(LayerDefChanged(cur.uid,false)),
					()->project.defs.getRecallEntityTags([cur.requiredTags, cur.excludedTags]),
					false
				);
				jForms.find("#excludedTags").empty().append( ted.jEditor );

				// Move entities
				jForms.find(".moveEntities").click( _->{
					new ui.modal.dialog.MoveEntitiesBetweenLayers(cur);
				});

			case Tiles:
				var jSelect = JsTools.createTilesetSelect(
					project,
					jForms.find("select[name=tilesets]"),
					cur.tilesetDefUid,
					true,
					"Tileset required",
					(uid)->{
						if( uid==null )
							cur.tilesetDefUid = null;
						else {
							cur.tilesetDefUid = uid;
							cur.gridSize = project.defs.getTilesetDef(cur.tilesetDefUid).tileGridSize;
						}
						editor.ge.emit(LayerDefChanged(cur.uid,true));
					}
				);

				// Tileset grid size
				var jInfos = jSelect.siblings(".infos");
				if( cur.tilesetDefUid==null )
					jInfos.hide();
				else {
					jInfos.show();
					jInfos.text(project.defs.getTilesetDef(cur.tilesetDefUid).tileGridSize+"px tiles");
				}

				// Create tileset shortcut
				var jBt = jSelect.siblings("button.create");
				if( project.defs.tilesets.length==0 )
					jBt.show();
				else
					jBt.hide();
				jBt.click( _->new ui.modal.panel.EditTilesetDefs() );

				// Different grid size warning
				var td = project.defs.getTilesetDef(cur.tilesetDefUid);
				if( td!=null && cur.gridSize!=td.tileGridSize && ( td.tileGridSize<cur.gridSize || td.tileGridSize%cur.gridSize!=0 ) ) {
					var jWarn = new J('<div class="tmp warning"/>');
					jWarn.appendTo( jSelect.parent() );
					jWarn.text(Lang.t._("Warning: the TILESET grid (::tileset::px) differs from the LAYER grid (::layer::px), and the values aren't multiples, which can lead to unexpected behaviors when adding a group of tiles.", {
						tileset: td.tileGridSize,
						layer: cur.gridSize,
					}));
				}


				var jPivots = jForms.find(".pivot");
				jPivots.empty();
				var p = JsTools.createPivotEditor(cur.tilePivotX, cur.tilePivotY, 0x0, function(x,y) {
					cur.tilePivotX = x;
					cur.tilePivotY = y;
					editor.ge.emit(LayerDefChanged(cur.uid,true));
				});
				p.appendTo(jPivots);
		}

		JsTools.parseComponents(jForms);
		checkBackup();
	}


	function updateList() {
		Tip.clear();
		jList.empty();

		ContextMenu.attachTo(jList, false, [
			{
				label: L._Paste(),
				cb: ()->{
					var copy = project.defs.pasteLayerDef(App.ME.clipboard);
					if( copy!=null ) {
						editor.ge.emit(LayerDefAdded);
						select(copy);
					}
				},
				enable: ()->App.ME.clipboard.is(CLayerDef),
			},
		]);

		for(ld in project.defs.layers) {
			var jLi = new J("<li/>");
			jLi.appendTo(jList);

			if( ld.hideInList )
				jLi.addClass("hidden");
			jLi.addClass( Std.string(ld.type) );

			jLi.append( JsTools.createLayerTypeIcon2(ld.type) );
			JsTools.applyListCustomColor(jLi, ld.uiColor, cur==ld);

			jLi.append('<span class="name">'+ld.identifier+'</span>');
			if( cur==ld )
				jLi.addClass("active");

			ContextMenu.attachTo_new(jLi, (ctx:ContextMenu)->{
				ctx.addElement( Ctx_CopyPaster({
					elementName: "layer",
					clipType: CLayerDef,
					copy: ()->App.ME.clipboard.copyData(CLayerDef, ld.toJson()),
					cut: ()->{
						App.ME.clipboard.copyData(CLayerDef, ld.toJson());
						deleteLayer(ld);
					},
					paste: ()->{
						var copy = project.defs.pasteLayerDef(App.ME.clipboard, ld);
						if( copy!=null ) {
							editor.ge.emit(LayerDefAdded);
							select(copy);
						}
					},
					duplicate: ()->{
						var copy = project.defs.duplicateLayerDef(ld);
						editor.ge.emit(LayerDefAdded);
						select(copy);
					},
					delete: ()->deleteLayer(ld),
				}) );
			});

			jLi.click( _->select(ld) );
		}

		// Make layer list sortable
		JsTools.makeSortable(jList, (ev)->{
			var moved = project.defs.sortLayerDef(ev.oldIndex, ev.newIndex);
			select(moved);
			editor.ge.emit(LayerDefSorted);
		});
		checkBackup();
		search.run();
	}
}
