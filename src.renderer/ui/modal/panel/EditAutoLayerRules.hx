package ui.modal.panel;

class EditAutoLayerRules extends ui.modal.Panel {
	public var li(get,never) : led.inst.LayerInstance;
		inline function get_li() return Editor.ME.curLayerInstance;

	public var ld(get,never) : led.def.LayerDef;
		inline function get_ld() return Editor.ME.curLayerDef;

	var lastRule : Null<led.def.AutoLayerRule>;

	public function new() {
		super();

		loadTemplate("editAutoLayerRules");
		setTransparentMask();
		updateForm();
	}

	override function onGlobalEvent(e:GlobalEvent) {
		super.onGlobalEvent(e);
		switch e {
			case ProjectSettingsChanged, ProjectSelected, LevelSettingsChanged, LevelSelected:
				close();

			case LayerInstanceRestoredFromHistory:
				updateForm();

			case LayerDefChanged:
				updateForm();

			case _:
		}
	}

	function updateForm() {
		var jRuleList = jContent.find("ul.rules").off().empty();
		jContent.find("*").off();
		ui.Tip.clear();

		// Add rule
		jContent.find("button.createRule").click( function(ev) {
			ld.rules.insert(0, new led.def.AutoLayerRule(project.makeUniqId(), 3));
			lastRule = ld.rules[0];
			editor.ge.emit(LayerDefChanged);
			new ui.modal.dialog.AutoPatternEditor( jContent.find("ul.rules [idx=0]"), ld, lastRule );
		});

		// Render
		var chk = jContent.find("[name=renderRules]");
		chk.prop("checked", editor.levelRender.isLayerAutoRendered(li) );
		chk.change( function(ev) {
			editor.levelRender.setLayerAutoRender( li, chk.prop("checked") );
		});

		// Rules
		var idx = 0;
		for( r in ld.rules) {
			var jRule = jContent.find("xml#rule").clone().children().wrapAll('<li/>').parent();
			jRule.appendTo(jRuleList);
			jRule.attr("idx", idx);

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
			i.linkEvent(LayerDefChanged);
			i.displayAsPct = true;
			i.setBounds(0,1);
			if( r.chance>=1 )
				i.jInput.addClass("max");
			else if( r.chance<=0 )
				i.jInput.addClass("off");

			// Break
			// var jFlag = jRule.find("a.break");
			// jFlag.addClass( r.breakOnMatch ? "on" : "off" );
			// jFlag.click( function(ev:js.jquery.Event) {
			// 	ev.preventDefault();
			// 	r.breakOnMatch = !r.breakOnMatch;
			// 	editor.ge.emit(LayerDefChanged);
			// });

			// Flip-X
			var jFlag = jRule.find("a.flipX");
			jFlag.addClass( r.flipX ? "on" : "off" );
			jFlag.click( function(ev:js.jquery.Event) {
				ev.preventDefault();
				if( r.isSymetricX() )
					N.error("This option will have no effect on a symetric rule.");
				else {
					r.flipX = !r.flipX;
					editor.ge.emit(LayerDefChanged);
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
					editor.ge.emit(LayerDefChanged);
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
						i.linkEvent(LayerDefChanged);
						i.jInput.siblings("button").click( function(_) {
							r.perlinSeed = Std.random(99999999);
							i.jInput.val(r.perlinSeed);
							editor.ge.emit(LayerDefChanged);
						});

						var i = Input.linkToHtmlInput(r.perlinScale, m.jContent.find("#perlinScale"));
						i.displayAsPct = true;
						i.setBounds(0.01, 1);
						i.linkEvent(LayerDefChanged);

						var i = Input.linkToHtmlInput(r.perlinOctaves, m.jContent.find("#perlinOctaves"));
						i.setBounds(1, 4);
						i.linkEvent(LayerDefChanged);
					}
				}
				else {
					r.setPerlin( !r.hasPerlin() );
					editor.ge.emit(LayerDefChanged);
				}
			});

			jRule.find("button.delete").click( function(ev) {
				new ui.modal.dialog.Confirm( jRule, Lang.t._("Warning, this cannot be undone!"), true, function() {
					ld.rules.remove(r);
					editor.ge.emit(LayerDefChanged);
				});
			});

			idx++;
		}

		JsTools.parseComponents(jContent);

		JsTools.makeSortable("ul.rules", function(from,to) {
			project.defs.sortLayerAutoRules(ld, from, to);
			editor.ge.emit(LayerDefChanged);
		});
	}
}
