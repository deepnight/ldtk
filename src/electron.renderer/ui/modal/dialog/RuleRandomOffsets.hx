package ui.modal.dialog;

class RuleRandomOffsets extends ui.modal.Dialog {
	var rule : data.def.AutoLayerRuleDef;
	var xLinked : Bool;
	var yLinked : Bool;

	public function new(?jTarget:js.jquery.JQuery, r:data.def.AutoLayerRuleDef) {
		super();

		rule = r;
		xLinked = r.tileRandomXMin == -r.tileRandomXMax;
		yLinked = r.tileRandomYMin == -r.tileRandomYMax;

		loadTemplate("ruleRandomOffsets");
		setTransparentMask();

		updateForm();
		setAnchor( MA_JQuery(jTarget) );
	}

	function updateForm() {
		var limit = 1024;
		jContent.find("*").off();

		// Link icons
		jContent.find("#xMin").siblings("button.link").find(".icon").removeClass("link, unlink").addClass(xLinked ? "link" : "unlink");
		jContent.find("#yMin").siblings("button.link").find(".icon").removeClass("link, unlink").addClass(yLinked ? "link" : "unlink");

		jContent.find(".resetAll").click(_->{
			rule.tileXOffset = 0;
			rule.tileYOffset = 0;
			rule.tileRandomXMin = rule.tileRandomXMax = 0;
			rule.tileRandomYMin = rule.tileRandomYMax = 0;
			onChange();
		});



		// X
		var i = Input.linkToHtmlInput(rule.tileXOffset, jContent.find("#xOffset"));
		i.setBounds(-limit, limit);
		i.enableSlider(0.66);
		i.setEmptyValue(0);
		i.setPlaceholder(0);
		i.onChange = onChange;

		i.jInput.siblings(".reset").click(_->{
			rule.tileXOffset = 0;
			onChange();
		});

		// X random min
		var i = Input.linkToHtmlInput(rule.tileRandomXMin, jContent.find("#xMin"));
		i.fixValue = (v)->return M.imin(v, rule.tileRandomXMax);
		i.setBounds(-limit, limit);
		i.enableSlider(0.66);
		i.setEmptyValue(0);
		i.setPlaceholder(0);
		i.onChange = ()->onChange();
		if( xLinked )
			i.disable();
		else
			i.enable();

		// X random max
		var i = Input.linkToHtmlInput(rule.tileRandomXMax, jContent.find("#xMax"));
		i.fixValue = (v)->return M.imax(v, rule.tileRandomXMin);
		i.setBounds(xLinked?0:-limit, limit);
		i.enableSlider(0.66);
		i.setEmptyValue(0);
		i.setPlaceholder(0);
		i.onChange = ()->{
			if( xLinked )
				rule.tileRandomXMin = -rule.tileRandomXMax;
			onChange();
		};

		// X random link
		i.jInput.siblings("button.link").click(_->{
			xLinked = !xLinked;
			if( xLinked ) {
				rule.tileRandomXMax = M.imax(rule.tileRandomXMin, rule.tileRandomXMax);
				rule.tileRandomXMin = -rule.tileRandomXMax;
			}
			onChange();
		});

		// X random reset
		i.jInput.siblings(".reset").click(_->{
			rule.tileRandomXMin = 0;
			rule.tileRandomXMax = 0;
			onChange();
		});


		// Y
		var i = Input.linkToHtmlInput(rule.tileYOffset, jContent.find("#yOffset"));
		i.setBounds(-limit, limit);
		i.enableSlider(0.66);
		i.setEmptyValue(0);
		i.setPlaceholder(0);
		i.onChange = onChange;

		i.jInput.siblings(".reset").click(_->{
			rule.tileYOffset = 0;
			onChange();
		});

		// Y random min
		var i = Input.linkToHtmlInput(rule.tileRandomYMin, jContent.find("#yMin"));
		i.fixValue = (v)->return M.imin(v, rule.tileRandomYMax);
		i.setBounds(-limit, limit);
		i.enableSlider(0.66);
		i.setEmptyValue(0);
		i.setPlaceholder(0);
		i.onChange = ()->onChange();
		if( yLinked )
			i.disable();
		else
			i.enable();

		// Y random max
		var i = Input.linkToHtmlInput(rule.tileRandomYMax, jContent.find("#yMax"));
		i.fixValue = (v)->return M.imax(v, rule.tileRandomYMin);
		i.setBounds(yLinked?0:-limit, limit);
		i.enableSlider(0.66);
		i.setEmptyValue(0);
		i.setPlaceholder(0);
		i.onChange = ()->{
			if( yLinked )
				rule.tileRandomYMin = -rule.tileRandomYMax;
			onChange();
		};

		// Y random link
		i.jInput.siblings("button.link").click(_->{
			yLinked = !yLinked;
			if( yLinked ) {
				rule.tileRandomYMax = M.imax(rule.tileRandomYMin, rule.tileRandomYMax);
				rule.tileRandomYMin = -rule.tileRandomYMax;
			}
			onChange();
		});

		// Y random reset
		i.jInput.siblings(".reset").click(_->{
			rule.tileRandomYMin = 0;
			rule.tileRandomYMax = 0;
			onChange();
		});
	}



	function onChange() {
		// if( rule.hasAnyPositionOffset() )
		// 	rule.breakOnMatch = false;
		editor.ge.emit( LayerRuleChanged(rule) );
		onSettingsChange(rule);
		updateForm();
	}

	public dynamic function onSettingsChange(r:data.def.AutoLayerRuleDef) {}
}