package ui.modal.dialog;

import data.DataTypes;

class RuleEditor extends ui.modal.Dialog {
	var curValIdx = 0;
	var layerDef : data.def.LayerDef;
	var rule : data.def.AutoLayerRuleDef;
	var guidedMode = false;

	public function new(layerDef:data.def.LayerDef, rule:data.def.AutoLayerRuleDef) {
		super("ruleEditor");

		this.layerDef = layerDef;
		this.rule = rule;

		render();
	}

	override function onGlobalEvent(e:GlobalEvent) {
		super.onGlobalEvent(e);
		switch(e) {
			case LayerRuleChanged(rule):
				render();

			case _:
		}
	}

	function enableGuidedMode() {
		guidedMode = true;
		jContent.addClass("guided");
		jContent.find(".disableTip").removeClass("disableTip");
		jContent.find(".explain").show();
	}

	function render() {
		var sourceDef = layerDef.type==IntGrid ? layerDef : project.defs.getLayerDef(layerDef.autoSourceLayerDefUid);

		loadTemplate("ruleEditor");
		jContent.find("[data-title],[title]").addClass("disableTip"); // removed on guided mode

		// Mini explanation tip
		var jExplain = jContent.find(".explain").hide();
		function _setExplain(?str:String) {
			if( str==null )
				jExplain.empty();
			else {
				if( str.indexOf("\\n")>=0 )
					str = "<p>" + str.split("\\n").join("</p><p>") + "</p>";
				jExplain.html(str);
			}
		}

		// Guided mode button
		jContent.find("button.guide").click( (_)->{
			enableGuidedMode();
		} );

		jContent.find(".debugInfos").text('#${rule.uid}');

		// Tile mode
		var i = new form.input.EnumSelect(
			jContent.find("select[name=tileMode]"),
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
		}

		var jTilesSettings = jContent.find(".tileSettings");

		// Tile(s)
		var jTilePicker = JsTools.createTilePicker(
			layerDef.autoTilesetDefUid,
			rule.tileMode==Single?MultiTiles:RectOnly,
			rule.tileIds,
			function(tids) {
				rule.tileIds = tids.copy();
				editor.ge.emit( LayerRuleChanged(rule) );
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
				});
				jTileOptions.append(jPivot);
		}

		// Pattern grid editor
		var jGrid = JsTools.createAutoPatternGrid(rule, sourceDef, layerDef, _setExplain, function(cx,cy,button) {
			var v = rule.get(cx,cy);
			if( button==0 ) {
				if( v==0 || v>0 )
					rule.set(cx,cy, curValIdx+1); // avoid zero value
				else if( v<0 )
					rule.set(cx,cy, 0);
			}
			else {
				if( v==0 )
					rule.set(cx,cy, -curValIdx-1);
				else
					rule.set(cx,cy, 0);
			}
			editor.ge.emit( LayerRuleChanged(rule) );
		});
		jContent.find(">.pattern .editor .grid").empty().append(jGrid);


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
		});
		jSizes.val(rule.size);


		// Value picker
		var jValues = jContent.find(">.pattern .values ul").empty();

		var idx = 0;
		for(v in sourceDef.getAllIntGridValues()) {
			var jVal = new J('<li/>');
			jVal.appendTo(jValues);

			jVal.css("background-color", C.intToHex(v.color));
			jVal.text( v.identifier!=null ? v.identifier : '#$idx' );

			if( idx==curValIdx )
				jVal.addClass("active");

			var i = idx;
			jVal.click( function(ev) {
				curValIdx = i;
				editor.ge.emit( LayerRuleChanged(rule) );
			});
			idx++;
		}

		// "Anything" value
		var jVal = new J('<li/>');
		jVal.appendTo(jValues);
		jVal.addClass("any");
		jVal.text("Anything");
		if( curValIdx==Const.AUTO_LAYER_ANYTHING )
			jVal.addClass("active");
		jVal.click( function(ev) {
			curValIdx = Const.AUTO_LAYER_ANYTHING;
			editor.ge.emit( LayerRuleChanged(rule) );
		});

		if( guidedMode )
			enableGuidedMode();
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
}