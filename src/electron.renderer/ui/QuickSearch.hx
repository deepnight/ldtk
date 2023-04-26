package ui;

class QuickSearch {
	public var jWrapper : js.jquery.JQuery;
	var jSearch : js.jquery.JQuery;
	var jList : js.jquery.JQuery;
	var jClear : js.jquery.JQuery;
	var softMatching : Bool;


	public function new(softMatching=true, jList:js.jquery.JQuery, ?jTarget:js.jquery.JQuery) {
		this.softMatching = softMatching;
		
		jWrapper = new J('<div class="quickSearch"></div>');
		if( jTarget!=null )
			jWrapper.appendTo(jTarget);
		this.jList = jList;

		jClear = new J('<span class="icon clear"></span>');
		jClear.appendTo(jWrapper);
		jClear.hide();

		jSearch = new J('<input type="text" class="quickSearch"/>');
		jSearch.appendTo(jWrapper);
		jSearch.attr("placeholder", "Search...");

		jSearch.keydown( (ev:js.jquery.Event)->{
			switch ev.key {
				case "Escape": clear();
				case _:
			}
		});

		jSearch.on("input", _->run());
		jClear.click( _->clear());
	}

	public inline function clear() {
		run("");
	}

	public dynamic function onSearch(rawQuery:String) {}

	public function run(?searchOverride:String) {
		if( searchOverride!=null )
			jSearch.val(searchOverride);

		jList.find(".searchMatched, .searchDiscarded").removeClass("searchMatched searchDiscarded");

		// Show/hide matches
		var rawSearch = Std.string(jSearch.val());
		jList.find("li:not(.subList)").each( (i,e)->{
			var jLi = new J(e);
			var jSubListParent = jLi.closest(".subList");

			// Reset
			if( rawSearch.length<=0 ) {
				jClear.hide();
				return;
			}
			jClear.show();

			// Always hide collapsers
			if( jLi.hasClass("collapser") ) {
				jLi.addClass("searchDiscarded");
				return;
			}

			// Show/hide elements
			if( JsTools.searchStringMatches(jSearch.val(), jLi.text(), softMatching) ) {
				jLi.addClass("searchMatched");
				jSubListParent.addClass("searchMatched");
			}
			else
				jLi.addClass("searchDiscarded");

			// Check for empty sub lists
			if( jSubListParent.length>0 && jSubListParent.has("li:visible").length==0 )
				jSubListParent.addClass("searchDiscarded");
		});
		onSearch(rawSearch);
	}

}