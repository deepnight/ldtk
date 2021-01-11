package ui.palette;

class IntGridPalette extends ui.ToolPalette {
	public function new(t) {
		super(t);
	}

	override function doRender() {
		super.doRender();

		jList = new J('<ul class="niceList"/>');
		jList.appendTo(jContent);

		var idx = 0;
		for( intGridVal in tool.curLayerInstance.def.getAllIntGridValues() ) {
			var e = new J("<li/>");
			e.attr("data-id", idx);
			e.appendTo(jList);
			e.addClass("color");
			if( idx==tool.getSelectedValue() )
				e.addClass("active");

			if( intGridVal.identifier==null )
				e.text("#"+idx);
			else
				e.text("#"+idx+" - "+intGridVal.identifier);

			e.css("color", C.intToHex( C.autoContrast(C.toBlack(intGridVal.color,0.3)) ));
			e.css("background-color", C.intToHex(intGridVal.color));
			var curIdx = idx;
			e.click( function(_) {
				tool.selectValue(curIdx);
				jList.find(".active").removeClass("active");
				e.addClass("active");
			});
			idx++;
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
