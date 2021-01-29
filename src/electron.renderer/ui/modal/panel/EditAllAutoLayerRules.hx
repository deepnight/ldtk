package ui.modal.panel;

import data.DataTypes;

class EditAllAutoLayerRules extends ui.modal.Panel {
	var li : data.inst.LayerInstance;
	var invalidatedRules : Map<Int,Int> = new Map();
	var lastRule : Null<data.def.AutoLayerRuleDef>;

	public var ld(get,never) : data.def.LayerDef;
		inline function get_ld() return li.def;


	public function new(li:data.inst.LayerInstance) {
		super();
		this.li = li;
		jMask.hide();

		loadTemplate("editAllAutoLayerRules");
		updatePanel();
		enableCloseButton();
	}

	override function onGlobalEvent(e:GlobalEvent) {
		super.onGlobalEvent(e);

		if( project.defs.getLayerDef(li.layerDefUid)==null ) {
			close();
			return;
		}

		switch e {
			case ProjectSettingsChanged, ProjectSelected, LevelSettingsChanged(_):
				updatePanel();

			case LevelSelected(l):
				close();

			case LayerInstanceRestoredFromHistory(li):
				if( li.layerDefUid==this.li.layerDefUid )
					this.li = li;
				updatePanel();

			case BeforeProjectSaving:
				applyInvalidatedRulesInAllLevels();

			case LayerRuleChanged(r), LayerRuleAdded(r):
				invalidateRuleAndOnesBelow(r);
				updatePanel();

			case LayerRuleRemoved(r): // invalidation is done before removal
				updatePanel();

			case LayerRuleGroupRemoved(rg): // invalidation is done before removal
				updatePanel();

			case LayerRuleGroupSorted:
				// WARNING: enable invalidation if breakOnMatch finally exists

				for(rg in ld.autoRuleGroups)
				for(r in rg.rules)
					invalidateRule(r);

				updatePanel();

			case LayerRuleGroupCollapseChanged:
				updatePanel();

			case LayerRuleGroupChangedActiveState(rg):
				for(r in rg.rules)
					invalidateRuleAndOnesBelow(r);
				updatePanel();

			case LayerRuleGroupAdded, LayerRuleGroupChanged(_):
				updatePanel();

			case LayerRuleSorted:
				updatePanel();

			case _:
		}
	}

	override function onClose() {
		super.onClose();
		applyInvalidatedRulesInAllLevels();
		editor.levelRender.clearTemp();
	}

	inline function invalidateRule(r:data.def.AutoLayerRuleDef) {
		invalidatedRules.set(r.uid, r.uid);
	}

	function invalidateRuleAndOnesBelow(r:data.def.AutoLayerRuleDef) {
		invalidateRule(r);

		var isAfter = false;
		li.def.iterateActiveRulesInEvalOrder( (or)->{
			if( or.uid==r.uid )
				isAfter = true;
			else if( isAfter )
				invalidateRule(or);
		} );
	}


	function applyInvalidatedRulesInAllLevels() {
		var ops = [];
		var affectedLayers : Map<data.inst.LayerInstance,data.Level> = new Map();

		// Apply edited rules to all other levels
		for(ruleUid in invalidatedRules)
		for( l in project.levels )
		for( li in l.layerInstances ) {
			if( !li.def.isAutoLayer() )
				continue;

			if( li.autoTilesCache==null ) {
				// Run all rules
				ops.push({
					label: 'Initializing autoTiles cache in ${l.identifier}.${li.def.identifier}',
					cb: ()->{
						li.applyAllAutoLayerRules();
					}
				});
				affectedLayers.set(li,l);
			}
			else {
				var r = li.def.getRule(ruleUid);
				if( r!=null && !r.isEmpty() ) { // Could be null for garbaged empty rules
					if( r!=null ) {
						// Apply rule
						ops.push({
							label: 'Applying rule #${r.uid} in ${l.identifier}.${li.def.identifier}',
							cb: ()->{
								li.applyAutoLayerRuleToAllLayer(r, false);
							},
						});
						affectedLayers.set(li,l);
					}
					else if( r==null && li.autoTilesCache.exists(ruleUid) ) {
						// Removed rule
						ops.push({
							label: 'Removing rule tiles #$ruleUid from ${l.identifier}',
							cb: ()->{
								li.autoTilesCache.remove(ruleUid);
							}
						});
						affectedLayers.set(li,l);
					}
				}
			}
		}

		// Apply "break on match" cascading effect in changed layers
		var affectedLevels : Map<data.Level, Bool> = new Map();
		for(li in affectedLayers.keys()) {
			affectedLevels.set( affectedLayers.get(li), true );
			ops.push({
				label: 'Applying break on matches on ${affectedLayers.get(li).identifier}.${li.def.identifier}',
				cb: li.applyBreakOnMatches.bind(),
			});
		}

		// Refresh world renders
		for(l in affectedLevels.keys())
			ops.push({
				label: 'Refreshing world render for ${l.identifier}...',
				cb: ()->editor.worldRender.invalidateLevel(l),
			});

		if( ops.length>0 ) {
			App.LOG.general("Applying invalidated rules...");
			new Progress(L.t._("Updating auto layers..."), 5, ops, editor.levelRender.renderAll);
		}

		invalidatedRules = new Map();
	}


	function showAffectedCells(r:data.def.AutoLayerRuleDef) {
		if( li.autoTilesCache!=null && li.autoTilesCache.exists(r.uid) ) {
			editor.levelRender.temp.lineStyle(1, 0xff00ff, 1);
			editor.levelRender.temp.beginFill(0x5a36a7, 0.6);
			for( coordId in li.autoTilesCache.get(r.uid).keys() ) {
				var cx = ( coordId % li.cWid );
				var cy = Std.int( coordId / li.cWid );
				editor.levelRender.temp.drawRect(
					cx*li.def.gridSize,
					cy*li.def.gridSize,
					li.def.gridSize,
					li.def.gridSize
				);
			}
		}
	}

	function updatePanel() {
		jContent.find("*").off();
		ui.Tip.clear();
		editor.levelRender.clearTemp();

		var jRuleGroupList = jContent.find("ul.ruleGroups").empty();

		if( !ld.autoLayerRulesCanBeUsed() ) {
			var jError = new J('<li> <div class="warning"/> </li>');
			jError.appendTo(jRuleGroupList);
			jError.find("div").append( L.t._("This layer settings prevent its rules to work. Please check the layer settings.") );
			var jButton = new J('<button>Edit settings</button>');
			jButton.click( ev->new EditLayerDefs() );
			jError.find("div").append(jButton);

			for(rg in ld.autoRuleGroups) {
				var jLi = new J('<li class="placeholder"/>');
				jLi.appendTo(jRuleGroupList);
				jLi.append('<strong>"${rg.name}"</strong>');
				jLi.append('<em>${rg.rules.length} rule(s)</em>');
			}
			return;
		}


		// Create new rule
		function createRule(rg:data.DataTypes.AutoLayerRuleGroup, insertIdx:Int) {
			App.LOG.general("Added rule");
			var r = new data.def.AutoLayerRuleDef( project.makeUniqId() );
			rg.rules.insert(insertIdx, r);

			if( rg.collapsed )
				rg.collapsed = false;

			lastRule = rg.rules[insertIdx];
			editor.ge.emit( LayerRuleAdded(lastRule) );


			var jNewRule = jContent.find("[ruleUid="+r.uid+"]"); // BUG fix scrollbar position
			new ui.modal.dialog.RuleEditor(ld, lastRule );
		}


		// Add group
		jContent.find("button.createGroup").click( function(ev) {
			if( ld.isAutoLayer() && ld.autoTilesetDefUid==null ) {
				N.error( Lang.t._("This auto-layer doesn't have a tileset. Please pick one in the LAYERS panel.") );
				return;
			}
			App.LOG.general("Added rule group");

			var insertIdx = 0;
			var rg = ld.createRuleGroup(project.makeUniqId(), "New group", insertIdx);
			editor.ge.emit(LayerRuleGroupAdded);

			var jNewGroup = jContent.find("[groupUid="+rg.uid+"]");
			jNewGroup.siblings("header").find(".edit").click();
		});


		// Randomize
		jContent.find("button.seed").click( function(ev) {
			li.seed = Std.random(9999999);
			editor.ge.emit(LayerRuleSeedChanged);
			ld.iterateActiveRulesInEvalOrder( r->{
				if( r.chance<1 || r.hasPerlin() )
					invalidateRuleAndOnesBelow(r);
			});
		});

		// Render
		var chk = jContent.find("[name=renderRules]");
		chk.prop("checked", editor.levelRender.isAutoLayerRenderingEnabled() );
		chk.change( function(ev) {
			editor.levelRender.setAutoLayerRendering( chk.prop("checked") );
		});


		// Rule groups
		var groupIdx = 0;
		for( rg in ld.autoRuleGroups) {
			var groupIdx = groupIdx++; // prevent memory pointer issues

			var jGroup = jContent.find("xml#ruleGroup").clone().children().wrapAll('<li/>').parent();
			jGroup.appendTo( jRuleGroupList );
			jGroup.addClass(rg.active ? "active" : "inactive");

			var jGroupList = jGroup.find(">ul");
			jGroupList.attr("groupUid", rg.uid);
			jGroupList.attr("groupIdx", groupIdx);

			var jGroupHeader = jGroup.find("header");

			// Collapsing
			jGroupHeader.find("div.name")
				.click( function(_) {
					rg.collapsed = !rg.collapsed;
					editor.ge.emit(LayerRuleGroupCollapseChanged);
				})
				.text(rg.name);

			if( rg.collapsed ) {
				jGroup.addClass("collapsed");
				var jDropTarget = new J('<ul class="collapsedSortTarget"/>');
				jDropTarget.attr("groupIdx",groupIdx);
				jDropTarget.attr("groupUid",rg.uid);
				jGroup.append(jDropTarget);
			}

			// Show cells affected by this whole group
			jGroupHeader.mouseenter( (ev)->{
				editor.levelRender.clearTemp();
				for(r in rg.rules)
					showAffectedCells(r);
			});
			jGroupHeader.mouseleave( (_)->editor.levelRender.clearTemp() );


			// Edit group
			jGroupHeader.find(".edit").click( function(ev:js.jquery.Event) {
				jGroupHeader.find("div.name").hide();
				var jInput = jGroupHeader.find("input.name");
				var old = rg.name;
				jInput
					.val( rg.name )
					.off()
					.show()
					.focus()
					.select()
					.on("keydown", function(ev:js.jquery.Event) {
						switch ev.key {
							case "Escape":
								ev.preventDefault();
								ev.stopPropagation();
								jInput.val(rg.name).blur();

							case "Enter":
								jInput.blur();

							case _:
						}
					})
					.on("blur", function(ev:js.jquery.Event) {
						if( jInput.val()!=old ) {
							rg.name = jInput.val();
							editor.ge.emit( LayerRuleGroupChanged(rg) );
						}
						else {
							jGroupHeader.find("div.name").show();
							jInput.hide();
						}
					});
			});

			// Enable/disable group
			jGroupHeader.find(".active").click( function(ev:js.jquery.Event) {
				if( rg.rules.length>0 )
					invalidateRuleAndOnesBelow( rg.rules[0] );
				rg.active = !rg.active;
				editor.ge.emit( LayerRuleGroupChangedActiveState(rg) );
			});

			// Add rule
			jGroupHeader.find(".addRule").click( function(ev:js.jquery.Event) {
				createRule(rg, 0);
			});

			// Group context menu
			ContextMenu.addTo(jGroup, jGroupHeader, [
				{
					label: L.t._("Duplicate group"),
					cb: ()->{
						var copy = ld.duplicateRuleGroup(project, rg);
						lastRule = copy.rules.length>0 ? copy.rules[0] : lastRule;
						editor.ge.emit( LayerRuleGroupAdded );
						for(r in copy.rules)
							invalidateRuleAndOnesBelow(r);
					},
				},
				{
					label: L._Delete(),
					cb: deleteRuleGroup.bind(rg),
				},
			]);

			// Rules
			var ruleIdx = 0;
			var allActive = true;
			for( r in rg.rules) {
				var ruleIdx = ruleIdx++; // prevent memory pointer issues

				if( !r.active )
					allActive = false;

				var jRule = jContent.find("xml#rule").clone().children().wrapAll('<li/>').parent();
				jRule.appendTo( jGroupList );
				jRule.attr("ruleUid", r.uid);
				jRule.addClass(r.active ? "active" : "inactive");

				// Show affect level cells
				jRule.mouseenter( (ev)->{
					editor.levelRender.clearTemp();
					showAffectedCells(r);
				} );
				jRule.mouseleave( (ev)->editor.levelRender.clearTemp() );

				// Insert rule before
				jRule.find(".insert.before").click( function(_) {
					createRule(rg, ruleIdx);
				});

				// Insert rule after
				jRule.find(".insert.after").click( function(_) {
					createRule(rg, ruleIdx+1);
				});

				// Last edited highlight
				jRule.mousedown( function(ev) {
					jRuleGroupList.find("li").removeClass("last");
					jRule.addClass("last");
					lastRule = r;
				});
				if( r==lastRule )
					jRule.addClass("last");

				// Preview
				var jPreview = jRule.find(".preview");
				var sourceDef = ld.type==AutoLayer ? project.defs.getLayerDef(ld.autoSourceLayerDefUid) : ld;
				if( r.isUsingUnknownIntGridValues(sourceDef) )
					jPreview.append('<div class="error">Error</div>');
				else {
					var pe = new RulePatternEditor(r, sourceDef, ld, true);
					jPreview.append(pe.jRoot);
				}
				jPreview.click( function(ev) {
					new ui.modal.dialog.RuleEditor(ld, r);
				});

				// Random chance
				var old = r.chance;
				var i = Input.linkToHtmlInput( r.chance, jRule.find("[name=random]"));
				i.linkEvent( LayerRuleChanged(r) );
				i.displayAsPct = true;
				i.setBounds(0,1);
				i.onValueChange = (v)->{
					if( v/100<old )
						invalidateRuleAndOnesBelow(r);
				}
				if( r.chance>=1 )
					i.jInput.addClass("max");
				else if( r.chance<=0 )
					i.jInput.addClass("off");

				// X modulo
				var i = Input.linkToHtmlInput( r.xModulo, jRule.find("[name=xModulo]"));
				i.onValueChange = (v)->{
					if( v>1 )
						invalidateRuleAndOnesBelow(r);
					r.tidy();
				}
				i.linkEvent( LayerRuleChanged(r) );
				i.setBounds(1,10);
				if( r.xModulo==1 )
					i.jInput.addClass("default");

				// Y modulo
				var i = Input.linkToHtmlInput( r.yModulo, jRule.find("[name=yModulo]"));
				i.onValueChange = (v)->{
					if( v>1 )
						invalidateRuleAndOnesBelow(r);
					r.tidy();
				}
				i.linkEvent( LayerRuleChanged(r) );
				i.setBounds(1,10);
				if( r.yModulo==1 )
					i.jInput.addClass("default");

				// Break on match
				var jFlag = jRule.find("a.break");
				jFlag.addClass( r.breakOnMatch ? "on" : "off" );
				jFlag.click( function(ev:js.jquery.Event) {
					ev.preventDefault();
					invalidateRuleAndOnesBelow(r);
					r.breakOnMatch = !r.breakOnMatch;
					editor.ge.emit( LayerRuleChanged(r) );
				});

				// Flip-X
				var jFlag = jRule.find("a.flipX");
				jFlag.addClass( r.flipX ? "on" : "off" );
				jFlag.click( function(ev:js.jquery.Event) {
					ev.preventDefault();
					if( r.isSymetricX() )
						N.error("This option will have no effect on a symetric rule.");
					else {
						r.flipX = !r.flipX;
						editor.ge.emit( LayerRuleChanged(r) );
					}
				});

				// Flip-Y
				var jFlag = jRule.find("a.flipY");
				jFlag.addClass( r.flipY ? "on" : "off" );
				jFlag.click( function(ev:js.jquery.Event) {
					ev.preventDefault();
					if( r.isSymetricY() )
						N.error("This option will have no effect on a symetric rule.");
					else {
						r.flipY = !r.flipY;
						editor.ge.emit( LayerRuleChanged(r) );
					}
				});
				
				// Rotate
				var jFlag = jRule.find("a.rotate");
				jFlag.addClass( r.rotate ? "on" : "off" );
				jFlag.click( function(ev:js.jquery.Event) {
					ev.preventDefault();

					r.rotate=!r.rotate;

					editor.ge.emit( LayerRuleChanged(r) );
				});

				// Perlin
				var jFlag = jRule.find("a.perlin");
				jFlag.addClass( r.hasPerlin() ? "on" : "off" );
				jFlag.mousedown( function(ev:js.jquery.Event) {
					ev.preventDefault();
					if( ev.button==2 ) {
						// Open perlin settings
						var w = new ui.modal.dialog.RulePerlinSettings(jFlag, r);
						w.onSettingsChange = (r)->invalidateRuleAndOnesBelow(r);
						if( !r.hasPerlin() ) {
							r.setPerlin(true);
							editor.ge.emit( LayerRuleChanged(r) );
						}
					}
					else {
						// Toggle it
						r.setPerlin( !r.hasPerlin() );
						if( r.hasPerlin() )
							invalidateRuleAndOnesBelow(r);
						editor.ge.emit( LayerRuleChanged(r) );
					}
				});

				// Checker
				var jFlag = jRule.find("a.checker");
				jFlag.addClass( r.checker!=None ? "on" : "off" );
				jFlag.mousedown( function(ev:js.jquery.Event) {
					if( r.xModulo==1 && r.yModulo==1 ) {
						N.error("Checker mode needs X or Y modulo greater than 1.");
						return;
					}
					ev.preventDefault();
					if( ev.button==2 ) {
						// Pick vertical/horizontal checker
						var m = new Dialog(jFlag);
						for(k in [ldtk.Json.AutoLayerRuleCheckerMode.Horizontal, ldtk.Json.AutoLayerRuleCheckerMode.Vertical]) {
							var name = k.getName();
							var jRadio = new J('<input name="mode" type="radio" value="$name" id="$name"/>');
							jRadio.change( function(ev:js.jquery.Event) {
								r.checker = k;
								invalidateRuleAndOnesBelow(r);
								editor.ge.emit( LayerRuleChanged(r) );
							});
							m.jContent.append(jRadio);
							m.jContent.append('<label for="$name">$name</label>');
						}

						if( r.checker==None )
							r.checker = r.xModulo==1 ? Vertical : Horizontal;
						m.jContent.find("[name=mode][value="+r.checker.getName()+"]").click();
					}
					else {
						// Just toggle it
						r.checker = r.checker==None ? ( r.xModulo==1 ? Vertical : Horizontal ) : None;
						invalidateRuleAndOnesBelow(r);
						editor.ge.emit( LayerRuleChanged(r) );
					}
				});

				// Enable/disable rule
				var jActive = jRule.find("a.active");
				jActive.find(".icon").addClass( r.active ? "active" : "inactive" );
				jActive.click( function(ev:js.jquery.Event) {
					ev.preventDefault();
					invalidateRuleAndOnesBelow(r);
					r.active = !r.active;
					editor.ge.emit( LayerRuleChanged(r) );
				});

				// Delete
				// jRule.find("button.delete").click( function(ev) {
				// 	deleteRule(rg, r);
				// });

				// Rule context menu
				ContextMenu.addTo(jRule, [
					{
						label: L.t._("Duplicate rule"),
						cb: ()->{
							var copy = ld.duplicateRule(project, rg, r);
							lastRule = copy;
							editor.ge.emit( LayerRuleAdded(copy) );
							invalidateRuleAndOnesBelow(copy);
						},
					},
					{
						label: L._Delete(),
						cb: deleteRule.bind(rg, r),
					},
				]);
			}

			jGroupHeader.find(".active .icon").addClass( rg.active ? ( allActive ? "active" : "partial" ) : "inactive" );


			// Make rules sortable
			JsTools.makeSortable(jGroupList, jRuleGroupList, "allRules", false, function(ev) {
				var fromUid = Std.parseInt( ev.from.getAttribute("groupUid") );
				if( fromUid!=rg.uid )
					return; // Prevent double "onSort" call (one for From, one for To)

				var fromGroupIdx = Std.parseInt( ev.from.getAttribute("groupIdx") );
				var toGroupIdx = Std.parseInt( ev.to.getAttribute("groupIdx") );

				var ruleUid = Std.parseInt( ev.item.getAttribute("ruleUid") );

				if( ev.newIndex>ev.oldIndex || toGroupIdx>fromGroupIdx)
					invalidateRuleAndOnesBelow( ld.getRule(ruleUid) );

				project.defs.sortLayerAutoRules(ld, fromGroupIdx, toGroupIdx, ev.oldIndex, ev.newIndex);

				if( ev.newIndex<ev.oldIndex || toGroupIdx<fromGroupIdx )
					invalidateRuleAndOnesBelow( ld.getRule(ruleUid) );

				editor.ge.emit(LayerRuleSorted);
			});

			// Turn the fake UL in collapsed groups into a sorting drop-target
			if( rg.collapsed )
				JsTools.makeSortable( jGroup.find(".collapsedSortTarget"), "allRules", false, function(_) {} );
		}

		// Make groups sortable
		JsTools.makeSortable(jRuleGroupList, "allGroups", false, function(ev) {
			project.defs.sortLayerAutoGroup(ld, ev.oldIndex, ev.newIndex);
			editor.ge.emit(LayerRuleGroupSorted);
		});

		JsTools.parseComponents(jContent);

	}

	function deleteRuleGroup(rg:AutoLayerRuleGroup) {
		new ui.modal.dialog.Confirm(Lang.t._("Confirm this action?"), true, function() {
			new LastChance(Lang.t._("Rule group removed"), project);
			App.LOG.general("Deleted rule group "+rg.name);
			for(r in rg.rules)
				invalidateRuleAndOnesBelow(r);
			ld.removeRuleGroup(rg);
			editor.ge.emit( LayerRuleGroupRemoved(rg) );
		});
	}

	function deleteRule(rg:AutoLayerRuleGroup, r:data.def.AutoLayerRuleDef) {
		new ui.modal.dialog.Confirm( Lang.t._("Warning, this cannot be undone!"), true, function() {
			App.LOG.general("Deleted rule "+r);
			invalidateRuleAndOnesBelow(r);
			rg.rules.remove(r);
			editor.ge.emit( LayerRuleRemoved(r) );
		});
	}


	public function onEditorMouseMove(m:Coords) {
		if( m.cx<0 || m.cx>=li.cWid || m.cy<0 || m.cy>=li.cHei )
			return;


		// List corresponding rules when overing a layer cell
		var coordId = li.coordId(m.cx, m.cy);
		var activeRules = new Map();
		li.def.iterateActiveRulesInEvalOrder((r)->{
			if( li.autoTilesCache.exists(r.uid) && li.autoTilesCache.get(r.uid).exists(coordId) )
				activeRules.set(r.uid, true);
		});

		// Highlight rules in panel
		jContent.find("li.highlight").removeClass("highlight");
		var jRules = jContent.find(".ruleGroup>li");
		for( uid in activeRules.keys() )
			jRules.filter('li[ruleuid=$uid]').addClass("highlight").parent().closest("li").addClass("highlight");
	}

	#if debug
	override function update() {
		super.update();
		var all = [];
		for(ruid in invalidatedRules.keys())
			all.push(ruid);
		App.ME.debug( "invalidatedRules="+all, true);
	}
	#end
}

