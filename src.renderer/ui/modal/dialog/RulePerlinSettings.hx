package ui.modal.dialog;

class RulePerlinSettings extends ui.modal.Dialog {
	var perlin: hxd.Perlin;
	var preview : h2d.Graphics;
	var rule : data.def.AutoLayerRuleDef;

	public function new(?target:js.jquery.JQuery, r:data.def.AutoLayerRuleDef) {
		super();

		rule = r;

		perlin = new hxd.Perlin();
		perlin.normalize = true;
		perlin.adjustScale(50, 1);

		preview = new h2d.Graphics();
		editor.levelRender.root.add(preview, Const.DP_UI);

		addClose();
		loadTemplate("perlinSettings");
		setTransparentMask();

		var i = Input.linkToHtmlInput(r.perlinSeed, jContent.find("#perlinSeed"));
		i.linkEvent( LayerRuleChanged(r) );
		i.jInput.siblings("button").click( function(_) {
			r.perlinSeed = Std.random(99999999);
			i.jInput.val(r.perlinSeed);
			editor.ge.emit( LayerRuleChanged(r) );
		});

		var i = Input.linkToHtmlInput(r.perlinScale, jContent.find("#perlinScale"));
		i.displayAsPct = true;
		i.setBounds(0.01, 0.99);
		i.linkEvent( LayerRuleChanged(r) );

		var i = Input.linkToHtmlInput(r.perlinOctaves, jContent.find("#perlinOctaves"));
		i.setBounds(1, 4);
		i.linkEvent( LayerRuleChanged(r) );

		positionNear(target);
		updatePreview();
	}

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
			if( perlin.perlin(rule.perlinSeed, cx*rule.perlinScale, cy*rule.perlinScale, rule.perlinOctaves) < 0 )
				preview.beginFill(0xff0000, 0.5);
			else
				preview.beginFill(0xb3f700, 0.3);
			preview.drawRect(cx*li.def.gridSize, cy*li.def.gridSize, li.def.gridSize, li.def.gridSize);
		}
	}
}