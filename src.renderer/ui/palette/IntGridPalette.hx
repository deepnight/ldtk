package ui.palette;

class IntGridPalette extends ui.ToolPalette {
	var scrollY = 0.;

	public function new(t) {
		super(t);
	}

	override function render() {
		super.render();

		var list = new J('<ul class="niceList"/>');
		list.appendTo(jContent);

		var idx = 0;
		for( intGridVal in tool.curLayerInstance.def.getAllIntGridValues() ) {
			var e = new J("<li/>");
			e.appendTo(list);
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
				list.find(".active").removeClass("active");
				e.addClass("active");
			});
			idx++;
		}

		// Scrolling memory
		list.scroll(function(ev) {
			scrollY = list.scrollTop();
		});
		list.scrollTop(scrollY);
	}
}