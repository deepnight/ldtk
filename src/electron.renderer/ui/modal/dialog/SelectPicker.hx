package ui.modal.dialog;

class SelectPicker extends ui.modal.Dialog {
	var jSelect : js.jquery.JQuery;
	var jFocus : js.jquery.JQuery;
	var jAllValues : js.jquery.JQuery;

	public function new(jSelect:js.jquery.JQuery, onPick:Dynamic->Void) {
		super();

		this.jSelect = jSelect;
		addClass("selectPicker");

		var jValues = new J('<div class="values"/>');
		jValues.appendTo(jContent);

		for(e in jSelect.find(".option")) {
			var jOpt = new J(e);
			var jValue = new J('<div class="value"/>');
			jValue.appendTo(jValues);
			jValue.text(jOpt.text());
			jValue.attr("search", jOpt.text().toLowerCase());
			jValue.css("background-color", jOpt.css("background-color"));
			jValue.click( _->{
				onPick( jOpt.attr("value") );
				close();
			});

			var jImg = jOpt.find("img:first");
			jValue.prepend( jImg.clone(false,false) );
		}

		jAllValues = jValues.find(".value");
		jFocus = jAllValues.first();
		onFocusChange();

		// Search
		var jSearch = new J('<input type="text" placeholder="Search" class="search"/>');
		jSearch.prependTo(jContent);
		jSearch.focus();
		jSearch.keydown( (ev:js.jquery.Event)->{
			switch ev.key {
				case "ArrowUp": jFocus = jFocus.prev();
				case "ArrowDown": jFocus = jFocus.next();
				case _:
			}
			onFocusChange();
		});
		jSearch.on( "input", _->{
			var s = StringTools.trim( Std.string( jSearch.val() ).toLowerCase() );
			jAllValues.each( (i,e)->{
				var jValue = new J(e);
				if( s.length==0 || jValue.attr("search").indexOf(s)>=0 )
					jValue.show();
				else
					jValue.hide();
			});
			jFocus = jAllValues.filter(":visible").first();
			onFocusChange();
		});
		jSearch.blur( _->{
			jSearch.focus();
		} );

		onResize();
	}

	function onFocusChange() {
		jAllValues.removeClass("focus");
		jFocus.addClass("focus");
	}

	override function onResize() {
		super.onResize();

		// Position
		var off = jSelect.offset();
		var winWid = js.Browser.window.innerWidth;
		var winHei = js.Browser.window.innerHeight;
		var x = off.left;
		var y = off.top;
		x = M.fmin(x, winWid-jWrapper.outerWidth()-8);
		y = M.fmin(y, winHei-jWrapper.outerHeight()-8);
		jWrapper.offset({ left: x, top: y });
		jWrapper.css("min-width", jSelect.outerWidth());
	}
}