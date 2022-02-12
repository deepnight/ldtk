package ui.modal.dialog;

import data.DataTypes;

class RuleEditor extends ui.modal.Dialog {
	var curValue = -1;
	var layerDef : data.def.LayerDef;
	var sourceDef : data.def.LayerDef;
	var rule : data.def.AutoLayerRuleDef;
	var guidedMode = false;

	public function new(layerDef:data.def.LayerDef, rule:data.def.AutoLayerRuleDef) {
		super("ruleEditor");

		setTransparentMask();
		this.layerDef = layerDef;
		this.rule = rule;
		sourceDef = layerDef.type==IntGrid ? layerDef : project.defs.getLayerDef( layerDef.autoSourceLayerDefUid );

		curValue = -1;
		for(iv in layerDef.getAllIntGridValues()) {
			curValue = iv.value;
			break;
		}

		renderAll();
	}

	override function onGlobalEvent(e:GlobalEvent) {
		super.onGlobalEvent(e);
		switch(e) {
			case LayerRuleChanged(rule):

			case _:
		}
	}

	function enableGuidedMode() {
		guidedMode = true;
		jContent.addClass("guided");
		jContent.find(".disableTip").removeClass("disableTip");
		jContent.find(".explain").show();
	}


	override function close() {
		super.close();

		if( rule.isEmpty() ) {
			for(rg in layerDef.autoRuleGroups)
				rg.rules.remove(rule);
			editor.ge.emit( LayerRuleRemoved(rule) );
		}
		else if( rule.tidy() )
			editor.ge.emit( LayerRuleChanged(rule) );
	}


	function updateTileSettings() {
		var jTilesSettings = jContent.find(".tileSettings");
		jTilesSettings.off();

		// Tile mode
		var jModeSelect = jContent.find("select[name=tileMode]");
		jModeSelect.empty();
		var i = new form.input.EnumSelect(
			jModeSelect,
			ldtk.Json.AutoLayerRuleTileMode,
			()->rule.tileMode,
			(v)->rule.tileMode = v,
			(v)->switch v {
				case Single: Lang.t._("Random tiles");
				case Stamp: Lang.t._("Rectangle of tiles");
			}
		);
		i.linkEvent( LayerRuleChanged(rule) );
		i.onChange = function() {
			rule.tileIds = [];
			updateTileSettings();
		}

		// Tile(s)
		var jTilePicker = JsTools.createTilePicker(
			Editor.ME.curLayerInstance.getTilesetUid(),
			rule.tileMode==Single?Free:RectOnly,
			rule.tileIds,
			function(tids) {
				rule.tileIds = tids.copy();
				editor.ge.emit( LayerRuleChanged(rule) );
				updateTileSettings();
			}
		);
		jTilesSettings.find(">.picker").empty().append( jTilePicker );

		// Pivot (optional)
		var jTileOptions = jTilesSettings.find(">.options").empty();
		switch rule.tileMode {
			case Single:
			case Stamp:
				var jPivot = JsTools.createPivotEditor(rule.pivotX, rule.pivotY, (xr,yr)->{
					rule.pivotX = xr;
					rule.pivotY = yr;
					editor.ge.emit( LayerRuleChanged(rule) );
					renderAll();
				});
				jTileOptions.append(jPivot);
		}
	}



	function updateValuePicker() {
		var jValues = jContent.find(">.pattern .values ul").empty();

		var allValues = sourceDef.getAllIntGridValues();
		if( allValues.length>8 )
			jContent.addClass("manyValues");
		else
			jContent.removeClass("manyValues");

		// Values picker
		for(v in allValues) {
			var jVal = new J('<li/>');
			jVal.appendTo(jValues);

			jVal.css("background-color", C.intToHex(v.color));
			jVal.append('<span class="value">${v.value}</span>');
			jVal.append('<span class="name">${v.identifier!=null ? v.identifier : ""}</span>');
			jVal.find(".name").css("color", C.intToHex( C.autoContrast(v.color) ) );

			if( v.value==curValue )
				jVal.addClass("active");

			var id = v.value;
			jVal.click( function(ev) {
				curValue = id;
				editor.ge.emit( LayerRuleChanged(rule) );
				updateValuePicker();
			});
		}

		// "Anything" value
		var jVal = new J('<li/>');
		jVal.appendTo(jValues);
		jVal.addClass("any");
		jVal.append('<span class="value"></span>');
		jVal.append('<span class="name">Anything/Nothing</span>');
		if( curValue==Const.AUTO_LAYER_ANYTHING )
			jVal.addClass("active");
		jVal.click( function(ev) {
			curValue = Const.AUTO_LAYER_ANYTHING;
			editor.ge.emit( LayerRuleChanged(rule) );
			updateValuePicker();
		});

	}

	function renderAll() {

		loadTemplate("ruleEditor");
		jContent.find("[data-title],[title]").addClass("disableTip"); // removed on guided mode

		// Mini explanation tip
		var jExplain = jContent.find(".explain").hide();

		// Guided mode button
		jContent.find("button.guide").click( (_)->{
			enableGuidedMode();
		} );
		jContent.find(".debugInfos").text('#${rule.uid}');

		updateTileSettings();

		// Pattern grid editor
		var patternEditor = new RulePatternEditor(
			rule, sourceDef, layerDef,
			(str:String)->{
				if( str==null )
					jExplain.empty();
				else {
					if( str.indexOf("\\n")>=0 )
						str = "<p>" + str.split("\\n").join("</p><p>") + "</p>";
					jExplain.html(str);
				}
			},
			()->curValue,
			()->editor.ge.emit( LayerRuleChanged(rule) )
		);
		jContent.find(">.pattern .editor .grid").empty().append( patternEditor.jRoot );


		// Grid size selection
		var jSizes = jContent.find(">.pattern .editor select").empty();
		var s = -1;
		var sizes = [ while( s<Const.MAX_AUTO_PATTERN_SIZE ) s+=2 ];
		for(size in sizes) {
			var jOpt = new J('<option value="$size">${size}x$size</option>');
			// if( size>=7 )
			// 	jOpt.append(" (WARNING: might slow-down app)");
			jOpt.appendTo(jSizes);
		}
		jSizes.change( function(_) {
			var size = Std.parseInt( jSizes.val() );
			rule.resize(size);
			editor.ge.emit( LayerRuleChanged(rule) );
			renderAll();
		});
		jSizes.val(rule.size);

		// Out-of-bounds policy
		var jOutOfBounds = jContent.find("#outOfBoundsValue");
		jOutOfBounds.empty();
		var values = [null, 0].concat( sourceDef.getAllIntGridValues().map( iv->iv.value ) );
		for(v in values) {
			var jOpt = new J('<option value="$v"/>');
			jOpt.appendTo(jOutOfBounds);
			switch v {
				case null: jOpt.text("This rule should not apply when reading cells outside of layer bounds (default)");
				case 0: jOpt.text("Empty cells");
				case _:
					var iv = sourceDef.getIntGridValueDef(v);
					jOpt.text( Std.string(v) + (iv.identifier!=null ? ' - ${iv.identifier}' : "") );
					jOpt.css({
						backgroundColor: C.intToHex( C.toBlack(iv.color, 0.4) ),
						borderColor: C.intToHex( iv.color ),
					});
			}
		}
		jOutOfBounds.click(_->Tip.clear());
		jOutOfBounds.change( _->{
			var v = jOutOfBounds.val()=="null" ? null : Std.parseInt(jOutOfBounds.val());
			rule.outOfBoundsValue = v;
			editor.ge.emit( LayerRuleChanged(rule) );
			renderAll();
		});
		jOutOfBounds.val( rule.outOfBoundsValue==null ? "null" : Std.string(rule.outOfBoundsValue) );
		if( rule.outOfBoundsValue!=null && rule.outOfBoundsValue>0 ) {
			var iv = sourceDef.getIntGridValueDef(rule.outOfBoundsValue);
			jOutOfBounds.addClass("hasValue").css({
				backgroundColor: C.intToHex( C.toBlack(iv.color, 0.4) ),
				borderColor: C.intToHex( iv.color ),
			});
		}
		jOutOfBounds.removeClass("disableTip");

		// Finalize
		updateValuePicker();
		if( guidedMode )
			enableGuidedMode();

		JsTools.parseComponents(jContent);
	}

}