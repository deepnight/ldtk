package ui;

class TilesetPicker {
	public function new(target:js.jquery.JQuery, td:TilesetDef, onSelect:TileSelection->Void) {
		var zoom = 2.;

		target.css("zoom",zoom);

		var cursor = new J('<div class="tileCursor"/>');
		cursor.prependTo(target);

		var img = new J( td.createAtlasHtmlImage() );
		img.appendTo(target);


		function onMouseDown(ev:js.jquery.Event) {
			var cx = Std.int( ev.offsetX / td.tileGridSize / zoom );
			var cy = Std.int( ev.offsetY / td.tileGridSize / zoom );
			if( ev.button==0 )
				onSelect( Single(td.coordId(cx,cy)) );
		}

		function onMouseUp(ev:js.jquery.Event) {
		}

		function onMouseMove(ev:js.jquery.Event) {
			var cx = Std.int( ev.offsetX / td.tileGridSize / zoom );
			var cy = Std.int( ev.offsetY / td.tileGridSize / zoom );

			cursor.css("margin-left", (cx*td.tileGridSize)+"px");
			cursor.css("margin-top", (cy*td.tileGridSize)+"px");
			cursor.css("width", td.tileGridSize+"px");
			cursor.css("height", td.tileGridSize+"px");
		}

		img.mousedown( function(ev) {
			ev.preventDefault();
			onMouseDown(ev);
		});

		img.mouseup( function(ev) {
			onMouseUp(ev);
		});

		img.mousemove( function(ev) {
			onMouseMove(ev);
		});

		var doc = new J(js.Browser.document);
		doc.on("mouseup", function(ev) {
			onMouseUp(ev);
		});
	}
}