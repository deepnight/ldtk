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

		render();
	}

	function render() {
		jContent.empty();


		// TODO preview
		// if( rule.tileId!=null && td!=null )
		// 	jContent.append( JsTools.createTile(td, rule.tileId, 32) );


		// Pattern grid
		var jGrid = new J('<div class="autoPattern"/>');
		jGrid.appendTo(jContent);
		jGrid.css("grid-template-columns", 'repeat( ${Const.AUTO_LAYER_PATTERN_SIZE}, auto )');
		var idx = 0;
		for(cy in 0...Const.AUTO_LAYER_PATTERN_SIZE)
		for(cx in 0...Const.AUTO_LAYER_PATTERN_SIZE) {
			var coordId = cx+cy*Const.AUTO_LAYER_PATTERN_SIZE;
			var jCell = new J('<div class="cell"/>');
			jCell.appendTo(jGrid);

			// Center
			if( cx==Std.int(Const.AUTO_LAYER_PATTERN_SIZE/2) && cy==Std.int(Const.AUTO_LAYER_PATTERN_SIZE/2) ) {
				var td = project.defs.getTilesetDef( layerDef.autoTilesetDefUid );
				jCell.addClass("center");
			}

			// Cell color
			var v = rule.pattern[coordId];
			if( v!=null ) {
				if( v>0 ) {
					if( M.iabs(v)-1 == Const.AUTO_LAYER_ANYTHING )
						jCell.addClass("anything");
					else
						jCell.css("background-color", C.intToHex( layerDef.getIntGridValueDef(M.iabs(v)-1).color ) );
				}
				else {
					jCell.addClass("not").append('<span class="cross">x</span>');
					if( M.iabs(v)-1 == Const.AUTO_LAYER_ANYTHING )
						jCell.addClass("anything");
					else
						jCell.css("background-color", C.intToHex( layerDef.getIntGridValueDef(M.iabs(v)-1).color ) );
				}
			}
			else
				jCell.addClass("empty");

			// Set grid value
			jCell.mousedown( function(ev) {
				if( ev.button==0 ) {
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
				N.debug(rule.pattern);
				render();
			});
			idx++;
		}

		// Value picker
		var jValues = new J('<ul class="values"/>');
		jValues.appendTo(jContent);

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
}