package ui.modal.dialog;

class SelectPicker extends ui.modal.Dialog {
	static var MAX_COLUMNS = 10;

	var jSelect : js.jquery.JQuery;
	var jSearch : js.jquery.JQuery;
	var jFocus : js.jquery.JQuery;
	var jValues : js.jquery.JQuery;
	var jAllValues : js.jquery.JQuery;
	var gridColumns = 1;
	var uiStateId : Null<Settings.UiState>;


	public function new(jSelect:js.jquery.JQuery, uiStateId:Null<Settings.UiState>, onPick:Dynamic->Void) {
		super();

		this.uiStateId = uiStateId;

		this.jSelect = jSelect;
		addClass("selectPicker");
		setTransparentMask();

		jValues = new J('<div class="values"/>');
		jValues.appendTo(jContent);
		var hasImages = false;
		if( jSelect.find("img, .placeholder").length>0 ) {
			hasImages = true;
			jValues.addClass("hasImg");
		}

		var selectedValue = jSelect.find(".option.selected").attr("value");

		for(e in jSelect.find(".option")) {
			var jOpt = new J(e);
			var jValue = new J('<div class="value"/>');
			jValue.appendTo(jValues);
			jValue.text(jOpt.text());
			jValue.attr("search", jOpt.text().toLowerCase());
			if( jOpt.hasClass("selected") ) {
				jValue.addClass("selected");
				jFocus = jValue;
			}

			if( jOpt.hasClass("disabled") )
				jValue.addClass("disabled");

			if( hasImages )
				jValue.addClass("hasImg");


			if( jOpt.is("[style]") )
				jValue.css("background-color", jOpt.css("background-color"));

			if( !jOpt.is("[value") || jOpt.attr("value").length==0 )
				jValue.addClass("null");

			if( jOpt.hasClass("default") )
				jValue.addClass("default");

			jValue.click( _->{
				onPick( jOpt.attr("value") );
				close();
			});

			var jImg = jOpt.find("img:first, .placeholder");
			jValue.prepend( jImg.clone(false,false) );
		}

		jAllValues = jValues.find(".value");
		if( jFocus==null )
			jFocus = jAllValues.first();

		jAllValues.mouseover( (ev:js.jquery.Event)->{
			jFocus = new J(ev.target);
			onFocusChange(false);
		});

		// Header
		var jHeader = new J('<div class="header"/>');
		jHeader.prependTo(jContent);

		// Search
		jSearch = new J('<input type="text" placeholder="Search" class="search"/>');
		jSearch.appendTo(jHeader);
		jSearch.focus();
		jSearch.blur( _->{
			if( isLast() )
				jSearch.focus();
		});

		// Search shortcut keys
		jSearch.keydown( (ev:js.jquery.Event)->{
			if( !isLast() )
				return;

			var jOld = jFocus;
			switch ev.key {
				case "ArrowLeft":
					if( gridColumns>1 ) {
						moveFocus(-1, false);
						ev.preventDefault();
					}

				case "ArrowRight":
					if( gridColumns>1 ) {
						moveFocus(1, false);
						ev.preventDefault();
					}

				case "ArrowUp":
					moveFocus(-gridColumns);
					ev.preventDefault();

				case "ArrowDown":
					moveFocus(gridColumns);
					ev.preventDefault();

				case "PageUp":
					moveFocus(-gridColumns*3);
					ev.preventDefault();

				case "PageDown":
					moveFocus(gridColumns*3);
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
			var rawSearch = JsTools.cleanUpSearchString(jSearch.val());
			jAllValues.each( (i,e)->{
				var jValue = new J(e);
				if( rawSearch.length==0 || JsTools.searchStringMatches(rawSearch, jValue.attr("search")) )
					jValue.show();
				else
					jValue.hide();
			});
			if( !jFocus.is(":visible") )
				jFocus = jAllValues.filter(":visible").first();
			onFocusChange();
			emitResizeAtEndOfFrame();
		});

		// Grid view button
		if( hasImages && uiStateId!=null ) {
			var jGrid = new J('<button class="transparent"> <span class="icon"></span> </button>');
			jGrid.appendTo(jHeader);
			function _updateGridButton() {
				var jIcon = jGrid.find(".icon");
				jIcon.removeClass().addClass("icon");
				switch gridColumns {
					case 1: jIcon.addClass("listView");
					case _: jIcon.addClass("gridView");
				}
			}
			jGrid.click(_->{
				function _setGridAndSave(g) {
					setGrid(g);
					_updateGridButton();
					onFocusChange();
					emitResizeAtEndOfFrame();
					if( gridColumns<=1 )
						settings.deleteUiState(uiStateId, project);
					else
						settings.setUiStateInt(uiStateId, gridColumns, project);
				}
				var ctx = new ContextMenu(jGrid);
				ctx.disableTextWrapping();
				ctx.addAction({
					label: L.untranslated('<span class="icon listView"></span> List view'),
					cb: _setGridAndSave.bind(1),
				});
				ctx.addTitle(L.t._("Grid view"));
				for(c in 2...MAX_COLUMNS+1)
					ctx.addAction({
						label: L.untranslated('<span class="icon gridView"></span> $c columns'),
						cb: _setGridAndSave.bind(c),
					});
			});
			if( uiStateId!=null && settings.hasUiState(uiStateId, project) )
				setGrid( settings.getUiStateInt(uiStateId, project) );
			_updateGridButton();
		}

		onFocusChange();
		emitResizeNow();
	}

	override function onAnotherModalOpen() {
		super.onAnotherModalOpen();
		jSearch.blur();
	}

	override function onAnotherModalClose() {
		super.onAnotherModalClose();
		if( isLast() )
			jSearch.focus();
	}

	override function openAnim() {
		// nope
	}

	function setGrid(cols:Int) {
		jValues.removeClass("grid");
		for(i in 2...MAX_COLUMNS+1)
			jValues.removeClass("grid-"+i);

		gridColumns = M.iclamp(cols,1,MAX_COLUMNS);
		if( gridColumns>1 ) {
			jValues.addClass("grid");
			jValues.addClass("grid-"+gridColumns);
		}
	}

	function moveFocus(delta:Int, allowRowChange=true) {
		if( delta==0 )
			return;

		var jOld = jFocus;

		var jAll : js.jquery.JQuery = delta<0 ? jFocus.prevAll(":visible") : jFocus.nextAll(":visible");
		if( jAll.length>=delta )
			jFocus = new J( jAll.get(M.iabs(delta)-1) );
		else
			jFocus = delta<0 ? jAll.first() : jAll.last();

		if( jFocus.length==0 || !allowRowChange && jOld.offset().top!=jFocus.offset().top )
			jFocus = jOld;
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
		y = M.fclamp(y, 8, winHei-jWrapper.outerHeight()-8);
		jWrapper.offset({ left: x, top: y });
		jWrapper.css("min-width", jSelect.outerWidth());
	}
}