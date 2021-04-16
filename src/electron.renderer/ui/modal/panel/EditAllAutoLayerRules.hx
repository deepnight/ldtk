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
		updateFullPanel();
	}

	override function onGlobalEvent(e:GlobalEvent) {
		super.onGlobalEvent(e);

		if( project.defs.getLayerDef(li.layerDefUid)==null ) {
			close();
			return;
		}

		switch e {
			case ProjectSettingsChanged, ProjectSelected, LevelSettingsChanged(_):
				updateFullPanel();

			case LevelSelected(l):
				close();

			case LayerInstanceRestoredFromHistory(li):
				if( li.layerDefUid==this.li.layerDefUid )
					this.li = li;
				updateFullPanel();

			case BeforeProjectSaving:
				applyInvalidatedRulesInAllLevels();

			case LayerRuleChanged(r):
				invalidateRuleAndOnesBelow(r);
				updateRule(r);

			case LayerRuleAdded(r):
				invalidateRuleAndOnesBelow(r);
				updateRuleGroup(r);

			case LayerRuleRemoved(r): // invalidation is done before removal
				updateAllRuleGroups();

			case LayerRuleGroupRemoved(rg): // invalidation is done before removal
				updateAllRuleGroups();

			case LayerRuleGroupSorted:
				// WARNING: enable invalidation if breakOnMatch finally exists

				for(rg in ld.autoRuleGroups)
				for(r in rg.rules)
					invalidateRule(r);

				updateAllRuleGroups();

			case LayerRuleGroupCollapseChanged(rg):
				updateRuleGroup(rg);

			case LayerRuleGroupChangedActiveState(rg):
				for(r in rg.rules)
					invalidateRuleAndOnesBelow(r);
				updateRuleGroup(rg);

			case LayerRuleGroupAdded:
				updateAllRuleGroups();

			case LayerRuleGroupChanged(rg):
				updateRuleGroup(rg);

			case LayerRuleSorted:
				updateAllRuleGroups();

			case LayerInstanceTilesetChanged(_):
				updateAllRuleGroups();

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

	function invalidateRuleGroup(rg:AutoLayerRuleGroup) {
		if( rg.rules.length>0 )
			invalidateRuleAndOnesBelow(rg.rules[0]);
	}

	function invalidateRuleAndOnesBelow(r:data.def.AutoLayerRuleDef) {
		invalidateRule(r);

		var isAfter = false;
		li.def.iterateActiveRulesInEvalOrder( li, (or)->{
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
		if( App.ME.isCtrlDown() )
			return;

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


	function onRenameGroup(jGroupHeader:js.jquery.JQuery, rg:AutoLayerRuleGroup) {
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
	}

	// Create new rule
	function onCreateRule(rg:data.DataTypes.AutoLayerRuleGroup, insertIdx:Int) {
		App.LOG.general("Added rule");
		var r = new data.def.AutoLayerRuleDef( project.makeUniqueIdInt() );
		rg.rules.insert(insertIdx, r);

		if( rg.collapsed )
			rg.collapsed = false;

		lastRule = rg.rules[insertIdx];
		editor.ge.emit( LayerRuleAdded(lastRule) );


		var jNewRule = jContent.find("[ruleUid="+r.uid+"]"); // BUG fix scrollbar position
		new ui.modal.dialog.RuleEditor(ld, lastRule );
	}


	function updateFullPanel() {
		// Cleanup
		jContent.find(">header, >header *").off();
		ui.Tip.clear();
		editor.levelRender.clearTemp();

		// Add group
		jContent.find("button.createGroup").click( function(ev) {
			if( ld.isAutoLayer() && ld.autoTilesetDefUid==null ) {
				N.error( Lang.t._("This auto-layer doesn't have a tileset. Please pick one in the LAYERS panel.") );
				return;
			}
			App.LOG.general("Added rule group");

			var insertIdx = 0;
			var rg = ld.createRuleGroup(project.makeUniqueIdInt(), "New group", insertIdx);
			editor.ge.emit(LayerRuleGroupAdded);

			var jNewGroup = jContent.find("ul[groupUid="+rg.uid+"]");
			jNewGroup.siblings("header").find(".edit").click();
		});


		// Randomize
		jContent.find("button.seed").click( function(ev) {
			li.seed = Std.random(9999999);
			editor.ge.emit(LayerRuleSeedChanged);
			ld.iterateActiveRulesInEvalOrder( li, r->{
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

		// Tileset selection per instance
		var curTd = li.getTilesetDef();
		var jSelect = jContent.find("#autoLayerTileset");
		jSelect.empty().off();
		if( !ld.autoLayerRulesCanBeUsed() )
			jSelect.prop("disabled",true);
		else {
			jSelect.prop("disabled",false);
			function _tilesetCompatible(td:data.def.TilesetDef) {
				return td.cWid==curTd.cWid && td.cHei==curTd.cHei && td.tileGridSize==curTd.tileGridSize;
			}
			var all = project.defs.tilesets.copy();
			all.sort( (a,b)->{
				var compA = _tilesetCompatible(a);
				var compB = _tilesetCompatible(b);
				if( compA==compB )
					return Reflect.compare(a.uid,b.uid);
				else if( compA )
					return -1;
				else
					return 1;
			});
			for(td in all) {
				var jOpt = new J('<option value="${td.uid}">${td.identifier}</option>');
				jOpt.appendTo(jSelect);
				if( !_tilesetCompatible(td) ) {
					jOpt.prop("disabled",true);
					jOpt.append(' (INCOMPATIBLE SIZE)');
				}
				if( td.uid==ld.autoTilesetDefUid )
					jOpt.append(' (DEFAULT)');
			}
			jSelect.val( curTd.uid );
			jSelect.change( (_)->{
				li.setOverrideTileset( Std.parseInt(jSelect.val()) );
				editor.levelRender.invalidateAll();
				editor.ge.emit( LayerInstanceTilesetChanged(li) );
			});
		}

		updateAllRuleGroups();

		JsTools.parseComponents(jContent);
	}



	function updateAllRuleGroups() {
		var jRuleGroupList = jContent.find("ul.ruleGroups");

		// Cleanup
		jContent.find(">ul, >ul *").off();
		jRuleGroupList.off().empty();

		// Error in layer settings
		if( !ld.autoLayerRulesCanBeUsed() ) {
			var jError = new J('<li> <div class="warning"/> </li>');
			jError.appendTo(jRuleGroupList);
			jError.find("div").append( L.t._("The current layer settings prevent its rules to work.") );
			var jButton = new J('<button>Open layer settings</button>');
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


		// Rule groups
		var groupIdx = 0;
		for( rg in ld.autoRuleGroups) {
			var jGroup = createRuleGroupBlock(rg, groupIdx);
			jRuleGroupList.append(jGroup);
			groupIdx++;
		}

		// Make groups sortable
		JsTools.makeSortable(jRuleGroupList, "allGroups", false, function(ev) {
			project.defs.sortLayerAutoGroup(ld, ev.oldIndex, ev.newIndex);
			editor.ge.emit(LayerRuleGroupSorted);
		});
	}


	function updateRuleGroup(?rg:AutoLayerRuleGroup, ?r:data.def.AutoLayerRuleDef) {
		if( rg==null && r==null )
			throw "Need 1 parameter";

		if( rg==null )
			rg = ld.getParentRuleGroup(r);

		editor.levelRender.clearTemp();

		var jPrevList = jContent.find('ul[groupUid=${rg.uid}]');
		var jPrevWrapper = jPrevList.parent();
		if( jPrevWrapper.length==0 ) {
			N.error("ERROR: ruleGroup not found in DOM");
			updateAllRuleGroups();
			return;
		}

		var jGroup = createRuleGroupBlock(rg, Std.parseInt(jPrevList.attr("groupIdx")) );
		jPrevWrapper.replaceWith(jGroup);
	}


	function createRuleGroupBlock(rg:AutoLayerRuleGroup, groupIdx:Int) {
		var jGroup = jContent.find("xml#ruleGroup").clone().children().wrapAll('<li/>').parent();
		jGroup.addClass(li.isRuleGroupActiveHere(rg) ? "active" : "inactive");


		var jGroupList = jGroup.find(">ul");
		jGroupList.attr("groupUid", rg.uid);
		jGroupList.attr("groupIdx", groupIdx); // TODO move to parent

		var jGroupHeader = jGroup.find("header");

		// Collapsing
		jGroupHeader.find("div.name")
			.click( function(_) {
				rg.collapsed = !rg.collapsed;
				editor.ge.emit( LayerRuleGroupCollapseChanged(rg) );
			})
			.find(".text").text(rg.name).parent()
			.find(".icon").removeClass().addClass("icon").addClass(rg.collapsed ? "folderClose" : "folderOpen");

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
			if( li.isRuleGroupActiveHere(rg) )
				for(r in rg.rules)
					showAffectedCells(r);
		});
		jGroupHeader.mouseleave( (_)->editor.levelRender.clearTemp() );


		jGroupHeader.find(".optional").hide();
		if( rg.isOptional )
			jGroupHeader.find(".optional").show();

		// Enable/disable group
		jGroupHeader.find(".active").click( function(ev:js.jquery.Event) {
			if( rg.rules.length>0 )
				invalidateRuleGroup(rg);
			if( rg.isOptional )
				li.toggleRuleGroupHere(rg);
			else
				rg.active = !rg.active;
			editor.ge.emit( LayerRuleGroupChangedActiveState(rg) );
		});

		// Add rule
		jGroupHeader.find(".addRule").click( function(ev:js.jquery.Event) {
			onCreateRule(rg, 0);
		});

		// Group context menu
		ContextMenu.addTo(jGroup, jGroupHeader, [
			{
				label: L.t._("Rename"),
				cb: ()->onRenameGroup(jGroupHeader, rg),
			},
			{
				label: L.t._("Turn into an OPTIONAL group"),
				cb: ()->{
					invalidateRuleGroup(rg);
					rg.isOptional = true;
					rg.active = true; // just some cleanup
					editor.ge.emit( LayerRuleGroupChanged(rg) );
				},
				sub: L.t._("An optional group is disabled everywhere by default, and can be enabled manually only in some specific levels."),
				cond: ()->!rg.isOptional,
			},
			{
				label: L.t._("Disable OPTIONAL state"),
				cb: ()->{
					new ui.modal.dialog.Confirm(
						L.t._("Warning: by removing the OPTIONAL status of this group, you will lose the on/off state of this group in all levels. The group of rules will become a 'global' one, applied to every levels."),
						true,
						()->{
							rg.isOptional = false;
							invalidateRuleGroup(rg);
							project.tidy();
							editor.ge.emit( LayerRuleGroupChanged(rg) );
						}
					);
				},
				cond: ()->rg.isOptional,
			},
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
				label: L.t._("Delete group"),
				cb: deleteRuleGroup.bind(rg),
			},
		]);

		// Rules
		var ruleIdx = 0;
		var allActive = true;
		for( r in rg.rules) {
			// Create rule in DOM
			var jRule = createRuleBlock(rg, r, ruleIdx++);
			jGroupList.append(jRule);

			// Last edited highlight
			jRule.mousedown( function(ev) {
				jContent.find("li.last").removeClass("last");
				jRule.addClass("last");
				lastRule = r;
			});
			if( r==lastRule )
				jRule.addClass("last");

			if( !r.active )
				allActive = false;
		}

		jGroupHeader.find(".active .icon")
			.addClass( rg.isOptional
				? li.isRuleGroupActiveHere(rg) ? "visible" : "hidden"
				: li.isRuleGroupActiveHere(rg) ? ( allActive ? "active" : "partial" ) : "inactive"
			);


		// Make individual rules sortable
		JsTools.makeSortable(jGroupList, jContent.find("ul.ruleGroups"), "allRules", false, function(ev) {
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

		return jGroup;
	}


	function updateRule(r:data.def.AutoLayerRuleDef) {
		editor.levelRender.clearTemp();

		var jPrev = jContent.find('li[ruleUid=${r.uid}]');
		if( jPrev.length==0 ) {
			N.error("ERROR: rule not found in DOM");
			updateAllRuleGroups();
			return;
		}

		var rg = ld.getParentRuleGroup(r);
		var jRule = createRuleBlock( rg, r, Std.parseInt(jPrev.attr("ruleIdx")) );
		jPrev.replaceWith(jRule);

		if( lastRule==r )
			jRule.addClass("last");
	}


	function createRuleBlock(rg:AutoLayerRuleGroup, r:data.def.AutoLayerRuleDef, ruleIdx:Int) : js.jquery.JQuery {
		var jRule = jContent.find("xml#rule").clone().children().wrapAll('<li/>').parent();
		jRule.attr("ruleUid", r.uid);
		jRule.attr("ruleIdx", ruleIdx);
		jRule.addClass(r.active ? "active" : "inactive");

		// Show affect level cells
		jRule.mouseenter( (ev)->{
			editor.levelRender.clearTemp();
			showAffectedCells(r);
		} );
		jRule.mouseleave( (ev)->editor.levelRender.clearTemp() );

		// Insert rule before
		jRule.find(".insert.before").click( function(_) {
			onCreateRule(rg, ruleIdx);
		});

		// Insert rule after
		jRule.find(".insert.after").click( function(_) {
			onCreateRule(rg, ruleIdx+1);
		});

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
		i.enablePercentageMode();
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


		JsTools.parseComponents(jRule);
		return jRule;
	}



	function deleteRuleGroup(rg:AutoLayerRuleGroup) {
		new ui.modal.dialog.Confirm(Lang.t._("Confirm this action?"), true, function() {
			new LastChance(Lang.t._("Rule group removed"), project);
			App.LOG.general("Deleted rule group "+rg.name);
			for(r in rg.rules)
				invalidateRuleAndOnesBelow(r);
			ld.removeRuleGroup(rg);
			project.tidy();
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
		jContent.find("li.highlight").removeClass("highlight");

		if( m.cx<0 || m.cx>=li.cWid || m.cy<0 || m.cy>=li.cHei )
			return;


		// List corresponding rules when overing a layer cell
		var coordId = li.coordId(m.cx, m.cy);
		var activeRules = new Map();
		li.def.iterateActiveRulesInEvalOrder( li, (r)->{
			if( li.autoTilesCache.exists(r.uid) && li.autoTilesCache.get(r.uid).exists(coordId) )
				activeRules.set(r.uid, true);
		});

		// Highlight rules in panel
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

