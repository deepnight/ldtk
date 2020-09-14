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
				close();

			case LayerInstanceRestoredFromHistory(li):
				updatePanel();

			case BeforeProjectSaving:
				updateAllLevels();

			case LayerRuleChanged(r), LayerRuleRemoved(r), LayerRuleAdded(r):
				updatePanel();
				invalidatedRules.set(r.uid, r.uid);

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
					li.applyAutoLayerRule(r);
					N.success("updated level "+l.identifier);
				}
				else if( r==null && li.autoTiles.exists(ruleUid) ) {
					li.autoTiles.remove(ruleUid);
					N.success("Discarded rule AutoTiles in "+l.identifier);
				}
			}
		}

		invalidatedRules = new Map();
	}

	function updatePanel() {
		jContent.find("*").off();
		ui.Tip.clear();

		var jRuleList = jContent.find("ul.rules").empty();

		function createRuleAtIndex(idx:Int) {
			ld.rules.insert(idx, new led.def.AutoLayerRuleDef(project.makeUniqId(), 3));
			lastRule = ld.rules[idx];
			editor.ge.emit( LayerRuleAdded(lastRule) );

			var jNewRule = jContent.find("ul.rules [idx="+idx+"]");
			if( idx==0 )
				jRuleList.scrollTop(0);

			new ui.modal.dialog.AutoPatternEditor(jNewRule, ld, lastRule );
		}

		// Add rule
		jContent.find("button.create").click( function(ev) {
			createRuleAtIndex(0);
		});

		// Render
		var chk = jContent.find("[name=renderRules]");
		chk.prop("checked", editor.levelRender.autoLayerRenderingEnabled(li) );
		chk.change( function(ev) {
			editor.levelRender.setAutoLayerRendering( li, chk.prop("checked") );
		});

		// Rules
		var idx = 0;
		for( r in ld.rules) {
			var jRule = jContent.find("xml#rule").clone().children().wrapAll('<li/>').parent();
			jRule.appendTo(jRuleList);
			jRule.attr("idx", idx);

			// Insert rule before
			var i = idx;
			jRule.find(".insert.before").click( function(_) {
				createRuleAtIndex(i);
			});

			// Insert rule after
			jRule.find(".insert.after").click( function(_) {
				createRuleAtIndex(i+1);
			});

			// Last edited highlight
			jRule.mousedown( function(ev) {
				jRuleList.find("li").removeClass("last");
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
						// Perlin settings
						var m = new Dialog(jFlag, "perlinSettings");
						m.addClose();
						m.loadTemplate("perlinSettings");
						m.setTransparentMask();

						var i = Input.linkToHtmlInput(r.perlinSeed, m.jContent.find("#perlinSeed"));
						i.linkEvent( LayerRuleChanged(r) );
						i.jInput.siblings("button").click( function(_) {
							r.perlinSeed = Std.random(99999999);
							i.jInput.val(r.perlinSeed);
							editor.ge.emit( LayerRuleChanged(r) );
						});

						var i = Input.linkToHtmlInput(r.perlinScale, m.jContent.find("#perlinScale"));
						i.displayAsPct = true;
						i.setBounds(0.01, 1);
						i.linkEvent( LayerRuleChanged(r) );

						var i = Input.linkToHtmlInput(r.perlinOctaves, m.jContent.find("#perlinOctaves"));
						i.setBounds(1, 4);
						i.linkEvent( LayerRuleChanged(r) );
					}
				}
				else {
					r.setPerlin( !r.hasPerlin() );
					editor.ge.emit( LayerRuleChanged(r) );
				}
			});

			// Active
			var jActive = jRule.find("a.active");
			jActive.addClass( r.active ? "on" : "off" );
			jActive.click( function(ev:js.jquery.Event) {
				ev.preventDefault();
				r.active = !r.active;
				editor.ge.emit( LayerRuleChanged(r) );
			});

			// Delete
			jRule.find("button.delete").click( function(ev) {
				new ui.modal.dialog.Confirm( jRule, Lang.t._("Warning, this cannot be undone!"), true, function() {
					ld.rules.remove(r);
					editor.ge.emit( LayerRuleRemoved(r) );
				});
			});

			idx++;
		}

		JsTools.parseComponents(jContent);

		JsTools.makeSortable("ul.rules", false, function(from,to) {
			project.defs.sortLayerAutoRules(ld, from, to);
			editor.ge.emit(LayerRuleSorted);
		});
	}
}
