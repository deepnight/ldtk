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
		var i = Input.linkToHtmlInput(rule.randomXOffset, jContent.find("#xOffset"));
		i.setBounds(0, 256);
		i.onChange = onChange;

		i.jInput.siblings(".reset").click(_->{
			rule.randomXOffset = 0;
			onChange();
		});

		// Y
		var i = Input.linkToHtmlInput(rule.randomYOffset, jContent.find("#yOffset"));
		i.setBounds(0, 256);
		i.onChange = onChange;

		i.jInput.siblings(".reset").click(_->{
			rule.randomYOffset = 0;
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