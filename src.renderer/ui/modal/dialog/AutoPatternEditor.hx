package ui.modal.dialog;

import led.LedTypes;

class AutoPatternEditor extends ui.modal.Dialog {
	var curValIdx = 0;
	var layerDef : led.def.LayerDef;
	var rule : AutoLayerRule;

	public function new(target:js.jquery.JQuery, layerDef:led.def.LayerDef, rule:AutoLayerRule) {
		super(target, "autoPatternEditor");

		this.layerDef = layerDef;
		this.rule = rule;

		loadTemplate("autoPatternEditor");
		render();
	}

	function render() {
		// Tile(s)
		var jTile = JsTools.createTilePicker(layerDef.autoTilesetDefUid, rule.tileIds, function(tids) {
			rule.tileIds = tids.copy();
			editor.ge.emit(LayerDefChanged);
			render();
		});
		jContent.find(">.tiles .wrapper").empty().append(jTile);

		// Pattern grid editor
		var jGrid = JsTools.createAutoPatternGrid(rule, layerDef, function(coordId,button) {
			var v = rule.pattern[coordId];
			if( button==0 ) {
				if( v==null || v>0 )
					rule.pattern[coordId] = curValIdx+1; // avoid zero value
				else if( v<0 )
					rule.pattern[coordId] = null;
			}
			else {
				if( v==null )
					rule.pattern[coordId] = -curValIdx-1;
				else
					rule.pattern[coordId] = null;
			}
			editor.ge.emit(LayerDefChanged);
			render();
		});
		jContent.find(">.grid .wrapper").empty().append(jGrid);

		// Value picker
		var jValues = jContent.find(">.values ul").empty();

		var jVal = new J('<li/>');
		jVal.appendTo(jValues);
		jVal.text("Anything");
		if( curValIdx==Const.AUTO_LAYER_ANYTHING )
			jVal.addClass("active");
		jVal.click( function(ev) {
			curValIdx = Const.AUTO_LAYER_ANYTHING;
			render();
		});

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
	}

	override function close() {
		super.close();

		if( layerDef.isRuleEmpty(rule) ) {
			layerDef.rules.remove(rule);
			editor.ge.emit(LayerDefChanged);
		}
	}
}