package ui.modal.panel;

class EditAutoLayerRules extends ui.modal.Panel {
	public var li(get,never) : led.inst.LayerInstance;
		inline function get_li() return Editor.ME.curLayerInstance;

	public var ld(get,never) : led.def.LayerDef;
		inline function get_ld() return Editor.ME.curLayerDef;

	var lastRule : Null<led.LedTypes.AutoLayerRule>;

	public function new() {
		super();

		loadTemplate("editAutoLayerRules");
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

		// Add rule
		jContent.find("button.createRule").click( function(ev) {
			ld.rules.insert(0, {
				tileIds: [],
				pattern: [],
				chance: 1,
			});
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

			jRule.find("button.delete").click( function(ev) {
				new ui.modal.dialog.Confirm( jRule, Lang.t._("Warning, this cannot be undone!"), true, function() {
					ld.rules.remove(r);
					editor.ge.emit(LayerDefChanged);
				});
			});

			idx++;
		}

		JsTools.parseComponents(jRuleList);

		JsTools.makeSortable("ul.rules", function(from,to) {
			project.defs.sortLayerAutoRules(ld, from, to);
			editor.ge.emit(LayerDefChanged);
		});
	}
}
