package ui.modal.dialog;

class RulePerlinSettings extends ui.modal.Dialog {
	var perlin: hxd.Perlin;
	var preview : h2d.Graphics;
	var rule : data.def.AutoLayerRuleDef;

	public function new(?jTarget:js.jquery.JQuery, r:data.def.AutoLayerRuleDef) {
		super();

		rule = r;

		perlin = new hxd.Perlin();
		perlin.normalize = true;
		perlin.adjustScale(50, 1);

		preview = new h2d.Graphics();
		editor.levelRender.root.add(preview, Const.DP_UI);

		loadTemplate("rulePerlinSettings");
		setTransparentMask();

		var i = Input.linkToHtmlInput(r.perlinSeed, jContent.find("#perlinSeed"));
		i.onChange = onChange.bind(r);
		i.jInput.siblings("button").click( function(_) {
			r.perlinSeed = Std.random(99999999);
			i.jInput.val(r.perlinSeed);
			onChange(r);
		});

		var i = Input.linkToHtmlInput(r.perlinScale, jContent.find("#perlinScale"));
		i.enablePercentageMode();
		i.enableSlider(50);
		i.setBounds(0.01, 0.99);
		i.onChange = onChange.bind(r);

		var i = Input.linkToHtmlInput(r.perlinOctaves, jContent.find("#perlinOctaves"));
		i.setBounds(1, 4);
		i.enableSlider(0.2);
		i.onChange = onChange.bind(r);

		setAnchor( MA_JQuery(jTarget) );
		updatePreview();
	}

	function onChange(r:data.def.AutoLayerRuleDef) {
		editor.ge.emit( LayerRuleChanged(r) );
		onSettingsChange(r);
	}

	public dynamic function onSettingsChange(r:data.def.AutoLayerRuleDef) {}

	override function onGlobalEvent(e:GlobalEvent) {
		super.onGlobalEvent(e);
		switch e {
			case LayerRuleChanged(rule): updatePreview();
			case _:
		}
	}

	override function onDispose() {
		super.onDispose();

		preview.remove();
		perlin = null;
	}

	function updatePreview() {
		preview.clear();

		var li = editor.curLayerInstance;
		for( cy in 0...li.cHei )
		for( cx in 0...li.cWid ) {
			if( perlin.perlin(li.seed+rule.perlinSeed, cx*rule.perlinScale, cy*rule.perlinScale, rule.perlinOctaves) < 0 )
				preview.beginFill(0xff0000, 0.5);
			else
				preview.beginFill(0xb3f700, 0.3);
			preview.drawRect(cx*li.def.gridSize, cy*li.def.gridSize, li.def.gridSize, li.def.gridSize);
		}
	}
}