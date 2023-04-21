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
		var i = Input.linkToHtmlInput(rule.tileRandomXOffset, jContent.find("#xOffset"));
		i.setBounds(0, 256);
		i.enableSlider(0.66);
		i.onChange = onChange;

		i.jInput.siblings(".reset").click(_->{
			rule.tileRandomXOffset = 0;
			onChange();
		});

		// Y
		var i = Input.linkToHtmlInput(rule.tileRandomYOffset, jContent.find("#yOffset"));
		i.setBounds(0, 256);
		i.onChange = onChange;
		i.enableSlider(0.66);

		i.jInput.siblings(".reset").click(_->{
			rule.tileRandomYOffset = 0;
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