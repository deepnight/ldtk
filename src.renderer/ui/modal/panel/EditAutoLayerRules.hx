package ui.modal.panel;

class EditAutoLayerRules extends ui.modal.Panel {
	var invalidatedRules : Map<Int,Int> = new Map();

	public var li(get,never) : led.inst.LayerInstance;
		inline function get_li() return Editor.ME.curLayerInstance;

	public var ld(get,never) : led.def.LayerDef;
		inline function get_ld() return Editor.ME.curLayerDef;

	var lastRule : Null<led.def.AutoLayerRuleDef>;

	public function new() {
		super();

		loadTemplate("editAutoLayerRules");
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

			case LayerRuleGroupAdded, LayerRuleGroupChanged:
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
		// Apply edited rules to all other levels
		for(ruleUid in invalidatedRules) {
			for( l in project.levels )
			for( li in l.layerInstances ) {
				var r = li.def.getRule(ruleUid);
				if( r!=null ) {
					App.LOG.render('Rule ${ruleUid} in level "${l.identifier}"": applying');
					li.applyAutoLayerRule(r);
				}
				else if( r==null && li.autoTiles.exists(ruleUid) ) {
					App.LOG.render('Rule ${ruleUid} in level "${l.identifier}"": removing autoTiles');
					// WARNING: re-apply all rules here if breakOnMatch exists
					li.autoTiles.remove(ruleUid);
				}
			}
		}

		invalidatedRules = new Map();
	}

	function updatePanel() {
		jContent.find("*").off();
		ui.Tip.clear();

		var jRuleGroupList = jContent.find("ul.ruleGroups").empty();


		// Create new rule
		function createRule(rg:led.LedTypes.AutoLayerRuleGroup, insertIdx:Int) {
			App.LOG.general("Added rule");
			var r = new led.def.AutoLayerRuleDef( project.makeUniqId() );
			rg.rules.insert(insertIdx, r);

			if( rg.collapsed )
				rg.collapsed = false;

			lastRule = rg.rules[insertIdx];
			editor.ge.emit( LayerRuleAdded(lastRule) );


			var jNewRule = jContent.find("[ruleUid="+r.uid+"]"); // BUG fix scrollbar position
			new ui.modal.dialog.AutoPatternEditor(jNewRule, ld, lastRule );
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

			var jGroupList = jGroup.find(">ul");
			jGroupList.attr("groupUid", rg.uid);
			jGroupList.attr("groupIdx", groupIdx);

			var jHeader = jGroup.find("header");

			// Collapsing
			jHeader.find("div.name")
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
			jHeader.find(".delete").click( function(ev:js.jquery.Event) {
				new ui.modal.dialog.Confirm(ev.getThis(), true, function() {
					new LastChance(Lang.t._("Rule group removed"), project);
					App.LOG.general("Deleted rule group");
					ld.removeRuleGroup(rg);
					editor.ge.emit( LayerRuleGroupRemoved(rg) );
				});
			});

			// Edit group
			jHeader.find(".edit").click( function(ev:js.jquery.Event) {
				jHeader.find("div.name").hide();
				var jInput = jHeader.find("input.name");
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
							editor.ge.emit(LayerRuleGroupChanged);
						}
						else {
							jHeader.find("div.name").show();
							jInput.hide();
						}
					});
			});

			// Edit group
			jHeader.find(".active").click( function(ev:js.jquery.Event) {
				rg.active = !rg.active;
				editor.ge.emit(LayerRuleGroupChanged);
			});
			jHeader.find(".active .icon").addClass( rg.active ? "visible" : "hidden" );

			// Add rule
			jHeader.find(".addRule").click( function(ev:js.jquery.Event) {
				createRule(rg, 0);
			});


			// Rules
			var ruleIdx = 0;
			for( r in rg.rules) {
				var ruleIdx = ruleIdx++; // prevent memory pointer issues

				var jRule = jContent.find("xml#rule").clone().children().wrapAll('<li/>').parent();
				jRule.appendTo( jGroupList );
				jRule.attr("ruleUid", r.uid);

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
				JsTools.createAutoPatternGrid(r, ld, true).appendTo(jPreview);
				jPreview.click( function(ev) {
					new ui.modal.dialog.AutoPatternEditor(jPreview, ld, r);
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
						if( !r.hasPerlin() ) {
							N.error("Perlin isn't enabled");
						}
						else {
							new ui.modal.dialog.RulePerlinSettings(jFlag, r);
						}
					}
					else {
						r.setPerlin( !r.hasPerlin() );
						editor.ge.emit( LayerRuleChanged(r) );
					}
				});

				// Active
				var jActive = jRule.find("a.active");
				jActive.find(".icon").addClass( r.active ? "visible" : "hidden" );
				jActive.click( function(ev:js.jquery.Event) {
					ev.preventDefault();
					r.active = !r.active;
					editor.ge.emit( LayerRuleChanged(r) );
				});

				// Delete
				jRule.find("button.delete").click( function(ev) {
					new ui.modal.dialog.Confirm( jRule, Lang.t._("Warning, this cannot be undone!"), true, function() {
						App.LOG.general("Deleted rule");
						rg.rules.remove(r);
						editor.ge.emit( LayerRuleRemoved(r) );
					});
				});
			}

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
}
