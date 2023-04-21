package ui.modal.dialog;

class RuleRandomOffsets extends ui.modal.Dialog {
	var rule : data.def.AutoLayerRuleDef;

	public function new(?target:js.jquery.JQuery, r:data.def.AutoLayerRuleDef) {
		super();

		rule = r;

		loadTemplate("ruleRandomOffsets");
		setTransparentMask();

		updateForm();
		positionNear(target);
	}

	function updateForm() {
		jContent.find("*").off();

		// X
		var i = Input.linkToHtmlInput(rule.tileRandomXMin, jContent.find("#xMin"));
		i.fixValue = (v)->return M.imin(v, rule.tileRandomXMax);
		i.setBounds(-256, 256);
		i.enableSlider(0.66);
		i.setEmptyValue(0);
		i.setPlaceholder(0);
		i.onChange = onChange;

		var i = Input.linkToHtmlInput(rule.tileRandomXMax, jContent.find("#xMax"));
		i.fixValue = (v)->return M.imax(v, rule.tileRandomXMin);
		i.setBounds(-256, 256);
		i.enableSlider(0.66);
		i.setEmptyValue(0);
		i.setPlaceholder(0);
		i.onChange = onChange;

		i.jInput.siblings(".reset").click(_->{
			rule.tileRandomXMin = 0;
			rule.tileRandomXMax = 0;
			onChange();
		});

		// Y
		var i = Input.linkToHtmlInput(rule.tileRandomYMin, jContent.find("#yMin"));
		i.fixValue = (v)->return M.imin(v, rule.tileRandomYMax);
		i.setBounds(-256, 256);
		i.enableSlider(0.66);
		i.setEmptyValue(0);
		i.setPlaceholder(0);
		i.onChange = onChange;

		var i = Input.linkToHtmlInput(rule.tileRandomYMax, jContent.find("#yMax"));
		i.fixValue = (v)->return M.imax(v, rule.tileRandomYMin);
		i.setBounds(-256, 256);
		i.enableSlider(0.66);
		i.setEmptyValue(0);
		i.setPlaceholder(0);
		i.onChange = onChange;

		i.jInput.siblings(".reset").click(_->{
			rule.tileRandomYMin = 0;
			rule.tileRandomYMax = 0;
			onChange();
		});
	}

	function onChange() {
		editor.ge.emit( LayerRuleChanged(rule) );
		onSettingsChange(rule);
		updateForm();
	}

	public dynamic function onSettingsChange(r:data.def.AutoLayerRuleDef) {}
}