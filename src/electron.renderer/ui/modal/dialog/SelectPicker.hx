package ui.modal.dialog;

class SelectPicker extends ui.modal.Dialog {
	var jSelect : js.jquery.JQuery;
	var jFocus : js.jquery.JQuery;
	var jValues : js.jquery.JQuery;
	var jAllValues : js.jquery.JQuery;

	public function new(jSelect:js.jquery.JQuery, onPick:Dynamic->Void) {
		super();

		cd.setS("ignoreMouse", 0.1);

		this.jSelect = jSelect;
		addClass("selectPicker");
		setTransparentMask();

		jValues = new J('<div class="values"/>');
		jValues.appendTo(jContent);
		if( jSelect.find("img, .placeholder").length>0 )
			jValues.addClass("hasImg");

		var selectedValue = jSelect.find(".option.selected").attr("value");

		for(e in jSelect.find(".option")) {
			var jOpt = new J(e);
			var jValue = new J('<div class="value"/>');
			jValue.appendTo(jValues);
			jValue.text(jOpt.text());
			jValue.attr("search", jOpt.text().toLowerCase());
			if( jOpt.is("[style]") )
				jValue.css("background-color", jOpt.css("background-color"));

			if( !jOpt.is("[value") || jOpt.attr("value").length==0 )
				jValue.addClass("null");

			jValue.click( _->{
				onPick( jOpt.attr("value") );
				close();
			});

			if( jOpt.attr("value")==selectedValue )
				jFocus = jValue;

			var jImg = jOpt.find("img:first, .placeholder");
			jValue.prepend( jImg.clone(false,false) );
		}

		jAllValues = jValues.find(".value");
		if( jFocus==null )
			jFocus = jAllValues.first();

		jAllValues.mouseover( (ev:js.jquery.Event)->{
			if( cd.has("ignoreMouse") )
				return;
			jFocus = new J(ev.target);
			onFocusChange(false);
		});

		// Search
		var jSearch = new J('<input type="text" placeholder="Search" class="search"/>');
		jSearch.prependTo(jContent);
		jSearch.focus();
		jSearch.blur( _->jSearch.focus() );

		// Search shortcut keys
		jSearch.keydown( (ev:js.jquery.Event)->{
			var jOld = jFocus;
			final page = 10;
			switch ev.key {
				case "ArrowUp":
					jFocus = jFocus.prevAll(":visible").first();
					ev.preventDefault();

				case "ArrowDown":
					jFocus = jFocus.nextAll(":visible").first();
					ev.preventDefault();

				case "PageUp":
					var jAll = jFocus.prevAll(":visible");
					if( jAll.length>=page )
						jFocus = new J( jAll.get(page-1) );
					else
						jFocus = jAll.first();
					ev.preventDefault();

				case "PageDown":
					var jAll = jFocus.nextAll(":visible");
					if( jAll.length>=page )
						jFocus = new J( jAll.get(page-1) );
					else
						jFocus = jAll.last();
					ev.preventDefault();

				case "Enter": jFocus.click();

				case "Escape": close();

				case _:
			}

			if( !jFocus.is(":visible") || jFocus.length==0 )
				jFocus = jOld;
			onFocusChange();
		});

		// Search entered
		jSearch.on( "input", _->{
			var s = StringTools.trim( Std.string( jSearch.val() ).toLowerCase() );
			jAllValues.each( (i,e)->{
				var jValue = new J(e);
				if( s.length==0 || jValue.attr("search").indexOf(s)>=0 )
					jValue.show();
				else
					jValue.hide();
			});
			if( !jFocus.is(":visible") )
				jFocus = jAllValues.filter(":visible").first();
			onFocusChange();
		});

		onFocusChange();
		onResize();
	}


	function onFocusChange(autoScroll=true) {
		jAllValues.removeClass("focus");
		jFocus.addClass("focus");
		if( autoScroll && jFocus.is(":visible") && jFocus.length>0 ) {
			var y = jFocus.offset().top + jValues.scrollTop() - jValues.offset().top;
			jValues.scrollTop(y - jValues.outerHeight()*0.5);
		}
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