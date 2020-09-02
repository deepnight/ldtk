package ui.palette;

class IntGridPalette extends ui.ToolPalette {
	var scrollY = 0.;

	public function new(t) {
		super(t);
	}

	override function render() {
		super.render();

		var jList = new J('<ul class="niceList"/>');
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

		// Scrolling memory
		jList.scroll(function(ev) {
			scrollY = jList.scrollTop();
		});
		jList.scrollTop(scrollY);
	}

	override function focusOnSelection() {
		super.focusOnSelection();

		var jList = jContent.find(">ul");
		var e = jList.find('[data-id=${tool.getSelectedValue()}]');
		if( e.length>0 ) {
			jList.scrollTop(0);
			jList.scrollTop( e.position().top - jList.outerHeight()*0.5 + e.outerHeight()*0.5 );
		}
	}
}