package ui.modal.panel;

import data.LedTypes;

class EditAllAutoLayerRules extends ui.modal.Panel {
	var invalidatedRules : Map<Int,Int> = new Map();

	public var li(get,never) : data.inst.LayerInstance;
		inline function get_li() return Editor.ME.curLayerInstance;

	public var ld(get,never) : data.def.LayerDef;
		inline function get_ld() return Editor.ME.curLayerDef;

	var lastRule : Null<data.def.AutoLayerRuleDef>;

	public function new() {
		super();

		loadTemplate("editAllAutoLayerRules");
		setTransparentMask();
		updatePanel();
	}

	override function onGlobalEvent(e:GlobalEvent) {
		super.onGlobalEvent(e);
		switch e {
			case ProjectSettingsChanged, ProjectSelected, LevelSettingsChanged, LevelSelected:
				updatePanel();

			case LayerInstanceRestoredFromHistory(li):
				updatePanel();

			case BeforeProjectSaving:
				updateAllLevels();

			case LayerRuleChanged(r), LayerRuleRemoved(r), LayerRuleAdded(r):
				invalidatedRules.set(r.uid, r.uid);
				updatePanel();

			case LayerRuleGroupRemoved(rg):
				for(r in rg.rules)
					invalidatedRules.set(r.uid, r.uid);
				updatePanel();

			case LayerRuleGroupSorted:
				// WARNING: enable invalidation if breakOnMatch finally exists

				// for(rg in ld.autoRuleGroups)
				// for(r in rg.rules)
				// 	invalidatedRules.set(r.uid, r.uid);

				updatePanel();

			case LayerRuleGroupCollapseChanged:
				updatePanel();

			case LayerRuleGroupChangedActiveState(rg):
				for(r in rg.rules)
					invalidatedRules.set(r.uid, r.uid);
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
		updateAllLevels();
	}

	function updateAllLevels() {
		var ops = [];

		// Apply edited rules to all other levels
		for(ruleUid in invalidatedRules)
		for( l in project.levels )
		for( li in l.layerInstances ) {
			if( !li.def.isAutoLayer() )
				continue;

			if( li.autoTilesCache==null ) {
				ops.push({
					label: 'Initializing autoTiles cache in ${l.identifier}.${li.def.identifier}',
					cb: li.applyAllAutoLayerRules
				});
			}
			else {
				var r = li.def.getRule(ruleUid);
				if( r!=null ) {
					ops.push({
						label: 'Updating rule #${r.uid} in ${l.identifier}.${li.def.identifier}',
						cb: li.applyAutoLayerRule.bind(r),
					});
				}
				else if( r==null && li.autoTilesCache.exists(ruleUid) ) {
					// WARNING: re-apply all rules here if breakOnMatch exists
					ops.push({
						label: 'Removing rule #$ruleUid from ${l.identifier}',
						cb: li.autoTilesCache.remove.bind(ruleUid),
					});
				}
			}
		}

		if( ops.length>0 )
			new Progress(L.t._("Updating auto layers..."), ops);

		invalidatedRules = new Map();
	}

	function updatePanel() {
		jContent.find("*").off();
		ui.Tip.clear();

		var jRuleGroupList = jContent.find("ul.ruleGroups").empty();

		if( !ld.autoLayerRulesCanBeUsed() ) {
			var jError = new J('<li> <div class="warning"/> </li>');
			jError.appendTo(jRuleGroupList);
			jError.find("div").append( L.t._("This layer settings prevent its rules to work. Please check the layer settings.") );
			var jButton = new J('<button>Edit settings</button>');
			jButton.click( ev->new EditLayerDefs() );
			jError.find("div").append(jButton);
			return;
		}


		// Create new rule
		function createRule(rg:data.LedTypes.AutoLayerRuleGroup, insertIdx:Int) {
			App.LOG.general("Added rule");
			var r = new data.def.AutoLayerRuleDef( project.makeUniqId() );
			rg.rules.insert(insertIdx, r);

			if( rg.collapsed )
				rg.collapsed = false;

			lastRule = rg.rules[insertIdx];
			editor.ge.emit( LayerRuleAdded(lastRule) );


			var jNewRule = jContent.find("[ruleUid="+r.uid+"]"); // BUG fix scrollbar position
			new ui.modal.dialog.RuleEditor(jNewRule, ld, lastRule );
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
		});

		// Render
		var chk = jContent.find("[name=renderRules]");
		chk.prop("checked", editor.levelRender.autoLayerRenderingEnabled(li) );
		chk.change( function(ev) {
			editor.levelRender.setAutoLayerRendering( li, chk.prop("checked") );
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

			// Delete group
			// jGroupHeader.find(".delete").click( function(ev:js.jquery.Event) {
			// 	deleteRuleGroup(rg);
			// });

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
							invalidatedRules.set(r.uid, r.uid);
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
				JsTools.createAutoPatternGrid(r, sourceDef, ld, true).appendTo(jPreview);
				jPreview.click( function(ev) {
					new ui.modal.dialog.RuleEditor(jPreview, ld, r);
				});

				// Random
				var i = Input.linkToHtmlInput( r.chance, jRule.find("[name=random]"));
				i.linkEvent( LayerRuleChanged(r) );
				i.displayAsPct = true;
				i.setBounds(0,1);
				if( r.chance>=1 )
					i.jInput.addClass("max");
				else if( r.chance<=0 )
					i.jInput.addClass("off");

				// X modulo
				var i = Input.linkToHtmlInput( r.xModulo, jRule.find("[name=xModulo]"));
				i.onChange = function() r.tidy();
				i.linkEvent( LayerRuleChanged(r) );
				i.setBounds(1,10);
				if( r.xModulo==1 )
					i.jInput.addClass("default");

				// Y modulo
				var i = Input.linkToHtmlInput( r.yModulo, jRule.find("[name=yModulo]"));
				i.onChange = function() r.tidy();
				i.linkEvent( LayerRuleChanged(r) );
				i.setBounds(1,10);
				if( r.yModulo==1 )
					i.jInput.addClass("default");

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
						new ui.modal.dialog.RulePerlinSettings(jFlag, r);
						if( !r.hasPerlin() ) {
							r.setPerlin(true);
							editor.ge.emit( LayerRuleChanged(r) );
						}
					}
					else {
						r.setPerlin( !r.hasPerlin() );
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
						var m = new Dialog(jFlag);
						for(k in [AutoLayerRuleCheckerMode.Horizontal, AutoLayerRuleCheckerMode.Vertical]) {
							var name = k.getName();
							var jRadio = new J('<input name="mode" type="radio" value="$name" id="$name"/>');
							jRadio.change( function(ev:js.jquery.Event) {
								r.checker = k;
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
						r.checker = r.checker==None ? ( r.xModulo==1 ? Vertical : Horizontal ) : None;
						editor.ge.emit( LayerRuleChanged(r) );
					}
				});

				// Active
				var jActive = jRule.find("a.active");
				jActive.find(".icon").addClass( r.active ? "active" : "inactive" );
				jActive.click( function(ev:js.jquery.Event) {
					ev.preventDefault();
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
							invalidatedRules.set(copy.uid, copy.uid);
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

				project.defs.sortLayerAutoRules(ld, fromGroupIdx, toGroupIdx, ev.oldIndex, ev.newIndex);
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
		new ui.modal.dialog.Confirm(true, function() {
			new LastChance(Lang.t._("Rule group removed"), project);
			App.LOG.general("Deleted rule group "+rg.name);
			ld.removeRuleGroup(rg);
			editor.ge.emit( LayerRuleGroupRemoved(rg) );
		});
	}

	function deleteRule(rg:AutoLayerRuleGroup, r:data.def.AutoLayerRuleDef) {
		new ui.modal.dialog.Confirm( Lang.t._("Warning, this cannot be undone!"), true, function() {
			App.LOG.general("Deleted rule "+r);
			rg.rules.remove(r);
			editor.ge.emit( LayerRuleRemoved(r) );
		});
	}

}
