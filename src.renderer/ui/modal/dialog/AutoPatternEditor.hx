package ui.modal.dialog;

import led.LedTypes;

class AutoPatternEditor extends ui.modal.Dialog {
	var curValIdx = 0;
	var layerDef : led.def.LayerDef;
	var rule : led.def.AutoLayerRuleDef;

	public function new(target:js.jquery.JQuery, layerDef:led.def.LayerDef, rule:led.def.AutoLayerRuleDef) {
		super(target, "autoPatternEditor");

		this.layerDef = layerDef;
		this.rule = rule;

		render();
	}

	function render() {
		loadTemplate("autoPatternEditor");

		// Mini explanation tip
		var jExplain = jContent.find(".explain");
		function setExplain(?str:String) {
			if( str==null )
				jExplain.empty();
			else
				jExplain.html(str);
		}

		// Tile(s)
		var jTile = JsTools.createTilePicker(layerDef.autoTilesetDefUid, rule.tileIds, function(tids) {
			rule.tileIds = tids.copy();
			editor.ge.emit( LayerRuleChanged(rule) );
			render();
		});
		jContent.find(">.tiles .wrapper").empty().append(jTile);

		// Pattern grid editor
		var jGrid = JsTools.createAutoPatternGrid(rule, layerDef, setExplain, function(cx,cy,button) {
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
			render();
		});
		jContent.find(">.grid .wrapper").empty().append(jGrid);


		// Grid size selection
		var jSizes = jContent.find(">.grid select").empty();
		var s = -1;
		var sizes = [ while( s<Const.MAX_AUTO_PATTERN_SIZE ) s+=2 ];
		for(size in sizes) {
			var jOpt = new J('<option value="$size">${size}x$size</option>');
			if( size>=7 )
				jOpt.append(" (WARNING: might slow-down app)");
			jOpt.appendTo(jSizes);
		}
		jSizes.change( function(_) {
			var size = Std.parseInt( jSizes.val() );
			rule.resize(size);
			editor.ge.emit( LayerRuleChanged(rule) );
			render();
		});
		jSizes.val(rule.size);


		// Value picker
		var jValues = jContent.find(">.values ul").empty();

		var idx = 0;
		for(v in layerDef.getAllIntGridValues()) {
			var jVal = new J('<li/>');
			jVal.appendTo(jValues);

			jVal.css("background-color", C.intToHex(v.color));
			jVal.text( v.identifier!=null ? v.identifier : '#$idx' );

			if( idx==curValIdx )
				jVal.addClass("active");

			var i = idx;
			jVal.click( function(ev) {
				curValIdx = i;
				render();
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
			render();
		});
	}

	override function close() {
		super.close();

		if( rule.isEmpty() ) {
			layerDef.rules.remove(rule);
			editor.ge.emit( LayerRuleRemoved(rule) );
		}
		else if( rule.trim() )
			editor.ge.emit( LayerRuleChanged(rule) );
	}
}