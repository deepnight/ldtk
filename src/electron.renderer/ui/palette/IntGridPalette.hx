package ui.palette;

class IntGridPalette extends ui.ToolPalette {
	public function new(t) {
		super(t);
	}

	override function doRender() {
		super.doRender();

		jList = new J('<ul class="niceList"/>');
		jList.appendTo(jContent);

		var valueIdx = 1;
		for( intGridVal in tool.curLayerInstance.def.getAllIntGridValues() ) {
			var e = new J("<li/>");
			e.attr("data-id", valueIdx);
			e.appendTo(jList);
			e.addClass("color");

			e.css( "border-color", C.intToHex(intGridVal.color) );

			// State
			if( valueIdx==tool.getSelectedValue() ) {
				e.addClass("active");
				e.css( "background-color", makeBgActiveColor(intGridVal.color) );
			}
			else {
				e.css( "background-color", makeBgInactiveColor(intGridVal.color) );
				e.css( "color", makeTextInactiveColor(intGridVal.color) );
			}

			// Label
			if( intGridVal.identifier==null )
				e.text(valueIdx);
			else
				e.text(valueIdx+" - "+intGridVal.identifier);

			var curIdx = valueIdx;
			e.click( function(_) {
				tool.selectValue(curIdx);
				render();
			});
			valueIdx++;
		}
	}

	override function focusOnSelection() {
		super.focusOnSelection();

		// Focus scroll animation
		var e = jList.find('[data-id=${tool.getSelectedValue()}]');
		if( e.length>0 )
			animateListScrolling(e.position().top + e.outerHeight()*0.5 );
	}
}
