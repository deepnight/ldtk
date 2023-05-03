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

		loadTemplate("editAllAutoLayerRules", { layer : li.def.identifier });
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
				for(li in editor.curLevel.layerInstances)
					if( li.layerDefUid==this.li.layerDefUid )
						this.li = li;
				updateFullPanel();

			case LevelSelected(l):
				close();

			case LayerInstancesRestoredFromHistory(lis):
				for(li in lis)
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
				if( !rg.isOptional )
					for(r in rg.rules)
						invalidateRuleAndOnesBelow(r);
				updateRuleGroup(rg);

			case LayerRuleGroupAdded(rg):
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
		for( w in project.worlds )
		for( l in w.levels )
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
				cb: li.applyBreakOnMatchesEverywhere.bind(),
			});
		}

		// Refresh world renders & break caches
		for(l in affectedLevels.keys())
			ops.push({
				label: 'Refreshing world render for ${l.identifier}...',
				cb: ()->{
					editor.worldRender.invalidateLevelRender(l);
					editor.invalidateLevelCache(l);
				},
			});

		if( ops.length>0 ) {
			App.LOG.general("Applying invalidated rules...");
			new Progress(L.t._("Updating auto layers..."), ops, editor.levelRender.renderAll);
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
					cx*li.def.gridSize + li.pxTotalOffsetX,
					cy*li.def.gridSize + li.pxTotalOffsetY,
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
		var r = new data.def.AutoLayerRuleDef( project.generateUniqueId_int() );
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
		jContent.find("button.createGroup").click( function(ev:js.jquery.Event) {
			var m = new ContextMenu( new J(ev.target) );

			m.add({
				label: L.t._("Use assistant (recommended)"),
				cb: ()->{
					if( ld.isAutoLayer() && ld.tilesetDefUid==null ) {
						N.error( Lang.t._("This auto-layer doesn't have a tileset. Please pick one in the LAYERS panel.") );
						return;
					}
					doUseWizard();
				},
			});

			m.add({
				label: L.t._("Create an empty group"),
				cb: ()->{
					if( ld.isAutoLayer() && ld.tilesetDefUid==null ) {
						N.error( Lang.t._("This auto-layer doesn't have a tileset. Please pick one in the LAYERS panel.") );
						return;
					}
					App.LOG.general("Added rule group");

					var insertIdx = 0;
					var rg = ld.createRuleGroup(project.generateUniqueId_int(), "New group", insertIdx);
					editor.ge.emit(LayerRuleGroupAdded(rg));

					var jGroupHeader = jContent.find("ul[groupUid="+rg.uid+"]").siblings("header");
					onRenameGroup( jGroupHeader, rg );
				},
			});
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
				return td!=null && curTd!=null && td.cWid==curTd.cWid && td.cHei==curTd.cHei && td.tileGridSize==curTd.tileGridSize;
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
				if( td.uid==ld.tilesetDefUid )
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
			jContent.find("button:not(.close), input").prop("disabled","true");
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

		jContent.find("button:not(.close), input").removeProp("disabled");


		// List context menu
		ContextMenu.addTo(jRuleGroupList, false, [
			{
				label: L._Paste("group"),
				cb: ()->{
					var copy = ld.pasteRuleGroup(project, App.ME.clipboard);
					editor.ge.emit(LayerRuleGroupAdded(copy));
					for(r in copy.rules)
						invalidateRuleAndOnesBelow(r);
				},
				enable: ()->return App.ME.clipboard.is(CRuleGroup),
			}
		]);

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

		checkBackup();
	}


	function updateRuleGroup(?rg:AutoLayerRuleGroup, ?r:data.def.AutoLayerRuleDef) {
		if( rg==null && r==null )
			throw "Need 1 parameter";

		if( rg==null )
			rg = ld.getParentRuleGroup(r);

		ui.Tip.clear();
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



	function doUseWizard(?original:AutoLayerRuleGroup) {
		new ui.modal.dialog.RulesWizard(original, ld, (rg)->{
			invalidateRuleGroup(rg);
			if( original==null )
				editor.ge.emit( LayerRuleGroupAdded(rg) );
			else
				editor.ge.emit( LayerRuleGroupChanged(rg) );
		});
	}


	function createRuleGroupBlock(rg:AutoLayerRuleGroup, groupIdx:Int) {
		var jGroup = jContent.find("xml#ruleGroup").clone().children().wrapAll('<li/>').parent();
		jGroup.addClass(li.isRuleGroupActiveHere(rg) ? "active" : "inactive");


		var jGroupList = jGroup.find(">ul");
		jGroupList.attr("groupUid", rg.uid);
		jGroupList.attr("groupIdx", groupIdx); // TODO move to parent

		var jGroupHeader = jGroup.find("header");

		// Collapsing
		var jName = jGroupHeader.find("div.name");
		jName.click( function(_) {
				rg.collapsed = !rg.collapsed;
				editor.ge.emit( LayerRuleGroupCollapseChanged(rg) );
			})
			.find(".text").text(rg.name).parent()
			.find(".icon").removeClass().addClass("icon").addClass(rg.collapsed ? "collapsed" : "expanded");

		if( rg.collapsed ) {
			jGroup.addClass("collapsed");
			var jDropTarget = new J('<ul class="collapsedSortTarget"/>');
			jDropTarget.attr("groupIdx",groupIdx);
			jDropTarget.attr("groupUid",rg.uid);
			jGroup.append(jDropTarget);
		}

		// Show cells affected by this whole group
		jName.mouseenter( (ev)->{
			if( !editor.levelRender.isAutoLayerRenderingEnabled() )
				return;
			editor.levelRender.clearTemp();
			if( li.isRuleGroupActiveHere(rg) )
				for(r in rg.rules)
					showAffectedCells(r);
		});
		jName.mouseleave( (_)->editor.levelRender.clearTemp() );

		// Optional state
		if( rg.isOptional )
			jGroup.addClass("optional");

		// Enable/disable group
		var jToggle = jGroupHeader.find(".active");
		jToggle.click( function(ev:js.jquery.Event) {
			if( rg.rules.length>0 && !rg.isOptional )
				invalidateRuleGroup(rg);

			if( rg.isOptional )
				li.toggleRuleGroupHere(rg);
			else
				rg.active = !rg.active;

			editor.ge.emit( LayerRuleGroupChangedActiveState(rg) );
		});
		if( rg.isOptional )
			jToggle.attr("title", (li.isRuleGroupActiveHere(rg)?"Disable":"Enable")+" this group of rules in this level");
		// else
		// 	jToggle.attr("title", (rg.active?"Disable":"Enable")+" this group of rules everywhere");

		// Add rule
		var jAdd = jGroupHeader.find(".addRule");
		if( rg.usesWizard )
			jAdd.hide();
		else
			jAdd.click( function(ev:js.jquery.Event) {
				onCreateRule(rg, 0);
			});

		// Edit using wizard
		var jWizEdit= jGroupHeader.find(".useWizard");
		if( !rg.usesWizard )
			jWizEdit.hide();
		else
			jWizEdit.click( _->doUseWizard(rg) );

		// Group context menu
		var actions : ui.modal.ContextMenu.ContextActions = [
			{
				label: L.t._("Rename"),
				cb: ()->onRenameGroup(jGroupHeader, rg),
			},

			{
				label: L.t._("Edit rules using the Assistant"),
				cb: ()->{
					doUseWizard(rg);
				},
				show: ()->rg.usesWizard,
			},

			{
				label: L.t._("Turn into an OPTIONAL group"),
				sub: L.t._("An optional group is disabled everywhere by default, and can be enabled manually only in some specific levels."),
				cb: ()->{
					invalidateRuleGroup(rg);
					rg.isOptional = true;
					rg.active = true; // just some cleanup
					editor.ge.emit( LayerRuleGroupChanged(rg) );
				},
				show: ()->!rg.isOptional,
			},

			{
				label: L.t._('Edit "out-of-bounds" policy for all rules'),
				// sub: L.t._("An optional group is disabled everywhere by default, and can be enabled manually only in some specific levels."),
				cb: ()->{
					var m = new ui.modal.Dialog();
					m.loadTemplate("outOfBoundsPolicyGlobal.html");
					var outOfBounds : Null<Int> = -1;
					JsTools.createOutOfBoundsRulePolicy(m.jContent.find("#outOfBoundsValue"), ld, outOfBounds, (v)->outOfBounds=v);
					m.addButton(L.t._("Apply to all rules"), ()->{
						if( outOfBounds<0 )
							return;

						for(r in rg.rules)
							r.outOfBoundsValue = outOfBounds;
						invalidateRuleGroup(rg);
						editor.ge.emit( LayerRuleGroupChanged(rg) );
						m.close();
					});
					m.addCancel();
				},
				show: ()->!rg.isOptional,
				separatorAfter: true,
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
				show: ()->rg.isOptional,
				separatorAfter: true,
			},
			{
				label: L._PasteAfter("rule"),
				cb: ()->{
					var copy = ld.pasteRule(project, rg, App.ME.clipboard);
					lastRule = copy;
					editor.ge.emit( LayerRuleAdded(copy) );
					invalidateRuleAndOnesBelow(copy);
				},
				show: ()->!rg.usesWizard,
				enable: ()->return App.ME.clipboard.is(CRule),
			},

			{
				label: L._Copy("Group"),
				cb: ()->{
					App.ME.clipboard.copyData(CRuleGroup, li.def.toJsonRuleGroup(rg));
				}
			},
			{
				label: L._Cut("Group"),
				cb: ()->{
					App.ME.clipboard.copyData(CRuleGroup, li.def.toJsonRuleGroup(rg));
					deleteRuleGroup(rg, false);
				}
			},
			{
				label: L._PasteAfter("group"),
				cb: ()->{
					var copy = ld.pasteRuleGroup(project, App.ME.clipboard, rg);
					editor.ge.emit(LayerRuleGroupAdded(copy));
					for(r in copy.rules)
						invalidateRuleAndOnesBelow(r);
				},
				enable: ()->App.ME.clipboard.is(CRuleGroup),
			},
			{
				label: L._Duplicate(),
				cb: ()->{
					var copy = ld.duplicateRuleGroup(project, rg);
					editor.ge.emit( LayerRuleGroupAdded(copy) );
					invalidateRuleGroup(copy);
				},
			},
			{
				label: L.t._("Duplicate and remap"),
				sub: L.t._("Duplicate the group, and optionally remap IntGrid IDs and tiles"),
				cb: ()->{
					new ui.modal.dialog.RuleGroupRemap(ld,rg, (copy)->{
						editor.ge.emit( LayerRuleGroupAdded(copy) );
						for(r in copy.rules)
							invalidateRuleAndOnesBelow(r);
					});
				},
			},
			{
				label: L._Delete(L.t._("Group")),
				cb: deleteRuleGroup.bind(rg, true),
			},
		];
		ContextMenu.addTo(jGroup, jGroupHeader, actions);

		// Wizard mode explanation
		if( rg.usesWizard ) {
			var jLi = new J('<li class="wizardHelp"/>');
			jLi.appendTo(jGroupList);

			var jEdit = new J('<button>Edit rules</button>');
			jEdit.click( _->{
				doUseWizard(rg);
			});
			jLi.append(jEdit);

			var jAdv = new J('<a href="#" class="advanced">Switch to advanced mode</a>');
			jAdv.click( _->{
				new ui.modal.dialog.Confirm(jAdv, L.t._("In advanced mode, you will be able to edit manually all the rules or add new ones, for more advanced results.\nWARNING: enabling advanced mode will prevent you from using the Rule Assistant anymore on this particular group."), ()->{
					new LastChance(L.t._("Enabled advanced mode on rule group ::name::", {name:rg.name}), project);
					rg.usesWizard = false;
					editor.ge.emit( LayerRuleGroupChanged(rg) );
				});
			});
			jLi.append(jAdv);

			jLi.append('<div class="help">The rules in this group are managed by the Assistant editor.</div>');
		}

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

		JsTools.parseComponents(jGroup);
		return jGroup;
	}


	function updateRule(r:data.def.AutoLayerRuleDef) {
		if( isClosing() )
			return;
		ui.Tip.clear();
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
		jRule.addClass("rule");
		if( rg.usesWizard )
			jRule.addClass("wizard");

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

		// Show affect level cells
		jPreview.mouseenter( (ev)->{
			if( !editor.levelRender.isAutoLayerRenderingEnabled() )
				return;
			editor.levelRender.clearTemp();
			showAffectedCells(r);
		} );
		jPreview.mouseleave( (ev)->editor.levelRender.clearTemp() );

		// Random chance
		var old = r.chance;
		var i = Input.linkToHtmlInput( r.chance, jRule.find("[name=random]"));
		i.linkEvent( LayerRuleChanged(r) );
		i.enablePercentageMode();
		i.setBounds(0.01, 1);
		i.onValueChange = (v)->{
			if( v/100<old )
				invalidateRuleAndOnesBelow(r);
		}
		if( r.chance>=1 )
			i.jInput.addClass("max");
		else if( r.chance<=0 )
			i.jInput.addClass("off");

		// Alpha
		var old = r.alpha;
		var i = Input.linkToHtmlInput( r.alpha, jRule.find("[name=alpha]"));
		i.linkEvent( LayerRuleChanged(r) );
		// i.enablePercentageMode();
		i.setBounds(0.01,1);
		i.enableSlider(0.5);
		i.setValueStep(0.01);
		i.setPrecision(2);
		i.onValueChange = (v)->{
			if( v<1 )
				r.breakOnMatch = false;
			if( v/100!=old )
				invalidateRuleAndOnesBelow(r);
		}
		if( r.alpha>=1 )
			i.jInput.addClass("max");

		// Random offsets
		var jFlag = jRule.find("a.randomOffset");
		jFlag.addClass( r.hasAnyPositionOffset() ? "on" : "off" );
		jFlag.mousedown( function(ev:js.jquery.Event) {
			ev.preventDefault();
			var w = new ui.modal.dialog.RuleRandomOffsets(jFlag, r);
			w.onSettingsChange = (r)->invalidateRuleAndOnesBelow(r);
		});

		// Modulos
		var jModulo = jRule.find(".modulo");
		jModulo.text('${r.xModulo}-${r.yModulo}');
		if( r.xModulo==1 && r.yModulo==1 )
			jModulo.addClass("default");
		jModulo.click( _->new ui.modal.dialog.RuleModuloEditor(jModulo, ld, r) );

		// Break on match
		var jFlag = jRule.find("a.break");
		jFlag.addClass( r.breakOnMatch ? "on" : "off" );
		jFlag.click( function(ev:js.jquery.Event) {
			if( r.hasAnyPositionOffset() ) {
				N.error("This rule has X or Y offsets: they are incompatible with the activation of the Break-on-Match option.");
				return;
			}
			if( r.alpha<1 ) {
				N.error("This rule has a custom opacity: this is incompatible with the activation of the Break-on-Match option.");
				return;
			}
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

		// Enable/disable rule
		var jActive = jRule.find("a.active");
		jActive.find(".icon").addClass( r.active ? "active" : "inactive" );
		jActive.click( function(ev:js.jquery.Event) {
			ev.preventDefault();
			invalidateRuleAndOnesBelow(r);
			r.active = !r.active;
			editor.ge.emit( LayerRuleChanged(r) );
		});

		// Rule context menu
		ContextMenu.addTo(jRule, [
			{
				label: L._Copy("Rule"),
				cb: ()->{
					App.ME.clipboard.copyData(CRule, r.toJson());
				},
			},
			{
				label: L._Cut("Rule"),
				cb: ()->{
					App.ME.clipboard.copyData(CRule, r.toJson());
					deleteRule(rg,r);
				},
			},
			{
				label: L._PasteAfter("rule"),
				cb: ()->{
					var copy = ld.pasteRule(project, rg, App.ME.clipboard, r);
					lastRule = copy;
					editor.ge.emit( LayerRuleAdded(copy) );
					invalidateRuleAndOnesBelow(copy);
				},
				enable: ()->return App.ME.clipboard.is(CRule),
			},
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

		if( rg.usesWizard )
			jRule.off().find("*").off();
		else
			JsTools.parseComponents(jRule);

		return jRule;
	}



	function deleteRuleGroup(rg:AutoLayerRuleGroup, confirm:Bool) {
		function _del() {
			new LastChance(Lang.t._("Rule group removed"), project);
			App.LOG.general("Deleted rule group "+rg.name);
			for(r in rg.rules)
				invalidateRuleAndOnesBelow(r);
			ld.removeRuleGroup(rg);
			project.tidy();
			editor.ge.emit( LayerRuleGroupRemoved(rg) );
		}
		if( confirm )
			new ui.modal.dialog.Confirm(Lang.t._("Confirm this action?"), true, _del);
		else
			_del();
	}

	function deleteRule(rg:AutoLayerRuleGroup, r:data.def.AutoLayerRuleDef) {
		App.LOG.general("Deleted rule "+r);
		invalidateRuleAndOnesBelow(r);
		rg.rules.remove(r);
		editor.ge.emit( LayerRuleRemoved(r) );
	}


	public function onEditorMouseMove(m:Coords) {
		jContent.find("li.highlight").removeClass("highlight");

		if( !editor.levelRender.isAutoLayerRenderingEnabled() )
			return;

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
		// App.ME.debug( "invalidatedRules="+all, true);
	}
	#end
}

