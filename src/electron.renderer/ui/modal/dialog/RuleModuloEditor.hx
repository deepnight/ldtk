package ui.modal.dialog;

import data.DataTypes;

class RuleModuloEditor extends ui.modal.Dialog {
	static var MIN_PREVIEW_SIZE = 8;

	var layerDef : data.def.LayerDef;
	var rule : data.def.AutoLayerRuleDef;

	public function new(jFrom:js.jquery.JQuery, layerDef:data.def.LayerDef, rule:data.def.AutoLayerRuleDef) {
		super("ruleModuloEditor");

		setAnchor( MA_JQuery(jFrom) );
		setTransparentMask();

		this.layerDef = layerDef;
		this.rule = rule;

		renderForm();
	}

	function renderForm() {
		jContent.find("*").off();
		jContent.find(".advancedSelect").remove();
		loadTemplate("ruleModuloEditor");

		// Reset
		jContent.find(".reset").click( (ev:js.jquery.Event)->{
			ev.preventDefault();
			rule.xModulo = rule.yModulo = 1;
			rule.xOffset = rule.yOffset = 0;
			rule.checker = None;
			editor.ge.emit(LayerRuleChanged(rule));
			renderForm();
		});

		var sliderSpeed = 0.33;

		// X modulo
		var i = Input.linkToHtmlInput( rule.xModulo, jContent.find("#xModulo"));
		i.onValueChange = (v)->rule.tidy(layerDef);
		i.linkEvent( LayerRuleChanged(rule) );
		i.enableSlider(sliderSpeed);
		i.setBounds(1,40);
		if( rule.xModulo==1 )
			i.jInput.addClass("default");
		i.addAutoClass("default", (v)->v==1);
		i.jInput.focus();

		// Y modulo
		var i = Input.linkToHtmlInput( rule.yModulo, jContent.find("#yModulo"));
		i.onValueChange = (v)->rule.tidy(layerDef);
		i.linkEvent( LayerRuleChanged(rule) );
		i.setBounds(1,40);
		i.enableSlider(sliderSpeed);
		i.addAutoClass("default", (v)->v==1);

		// X offset
		final bounds = 4096;
		var i = Input.linkToHtmlInput( rule.xOffset, jContent.find("#xOffset"));
		i.setBounds(-bounds, bounds);
		i.enableSlider(sliderSpeed);
		i.linkEvent( LayerRuleChanged(rule) );
		i.fixValue = (v)->v = v % rule.xModulo;
		i.addAutoClass("default", (v)->v==1);

		// Y offset
		var i = Input.linkToHtmlInput( rule.yOffset, jContent.find("#yOffset"));
		i.linkEvent( LayerRuleChanged(rule) );
		i.setBounds(-bounds, bounds);
		i.enableSlider(sliderSpeed);
		i.addAutoClass("default", (v)->v==1);

		var i = new form.input.EnumSelect(
			jContent.find("select.checker"),
			ldtk.Json.AutoLayerRuleCheckerMode,
			false,
			()->rule.checker,
			(v)->{
				rule.checker = v;
				editor.ge.emit(LayerRuleChanged(rule));
				renderForm();
			},
			(v)->switch v {
				case None: L.t._("Off");
				case Horizontal: L.t._("Horizontally");
				case Vertical: L.t._("Vertically");
			},
			(v)->switch v {
				case None: true;
				case Horizontal: rule.xModulo>1;
				case Vertical: rule.yModulo>1;
			},
			true
		);

		JsTools.parseComponents(jContent);
		renderPreview();
	}

	override function onGlobalEvent(e:GlobalEvent) {
		super.onGlobalEvent(e);
		switch e {
			case LayerRuleChanged(r):
				if( r==rule )
					// renderPreview();
					renderForm();

			case _:
		}
	}


	function renderPreview() {
		// Preview
		var jPreview = jContent.find(".preview");
		jPreview.empty();
		var xMax = M.imax(rule.xModulo+3, MIN_PREVIEW_SIZE);
		var yMax = M.imax(rule.yModulo+3, MIN_PREVIEW_SIZE);
		jPreview.css("grid-template-columns", 'repeat($xMax, 1fr)');
		jPreview.css("grid-template-rows", 'repeat($yMax, 1fr)');
		for(cy in 0...yMax)
		for(cx in 0...xMax) {
			var jCell = new J('<div class="cell"/>');
			jCell.appendTo(jPreview);
			if( (cx-rule.xOffset) % rule.xModulo==0 && (cy-rule.yOffset) % rule.yModulo==0 )
				jCell.addClass("active");
		}
	}

}
