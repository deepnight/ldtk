package ui.ts;

class TileTagger extends ui.Tileset {
	var ed : data.def.EnumDef;
	var jTools : js.jquery.JQuery;
	var jCustomBt : js.jquery.JQuery;
	var jValues : js.jquery.JQuery;

	var curEnumValue : Null<String>;
	var pendingCustom = false;


	public function new(target, td) {
		super(target, td, None);
		this.ed = td.getTagsEnumDef();

		jWrapper.addClass("tileTagger");

		jTools = new J('<div class="tools"/>');
		jTools.appendTo(jWrapper);

		jCustomBt = new J('<button></button>');
		jCustomBt.appendTo(jTools);
		jCustomBt.click(_->setPendingCustom(!pendingCustom) );

		jValues = new J('<ul class="values niceList"/>');
		jValues.appendTo(jTools);

		// Add Enum values
		jValues.off().empty();
		var ed = tilesetDef.getTagsEnumDef();
		if( ed!=null ) {
			var jVal = new J('<li value="none" class="none">-- Show all --</li>');
			jVal.appendTo(jValues);
			jVal.click( ev->{
				selectEnumValue(null);
				setPendingCustom(false);
			});

			for(ev in ed.values) {
				var jVal = new J('<li value="${ev.id}">${ev.id}</li>');
				if( ev.tileId!=null ) {
					var iconTd = Editor.ME.project.defs.getTilesetDef(ed.iconTilesetUid);
					if( iconTd!=null )
						jVal.prepend( JsTools.createTile(iconTd, ev.tileId, 16) );
				}
				jVal.appendTo(jValues);
				jVal.css({
					borderColor: C.intToHex(ev.color),
					backgroundColor: C.intToHex( C.toBlack(ev.color,0.4) ),
				});
				jVal.click( _->{
					selectEnumValue(ev.id);
					setPendingCustom(false);
				});
			}
			jValues.find('[value=${curEnumValue==null ? "none" : curEnumValue}]').addClass("active");
		}


		selectEnumValue();
		setPendingCustom(false);
	}


	function selectEnumValue(?id:String) {
		jValues.find(".active").removeClass("active");
		curEnumValue = id;

		if( id!=null ) {
			setPendingCustom(false);
			setSelectionMode(RectOnly);
			jValues.find('[value=$id]').addClass("active");
		}
		else {
			setSelectionMode(None);
			jValues.find('[value=none]').addClass("active");
		}

		refresh();
	}


	function refresh() {
		var ctx = canvas.getContext2d();

		// Clear
		renderAtlas();

		// No tags
		if( tilesetDef.tagsSourceEnumUid==null ) {
			renderGrid();
			return;
		}

		var isSmallGrid = tilesetDef.tileGridSize<16;
		var thickness = M.imax(1, Std.int( tilesetDef.tileGridSize / 16 ) );
		var offX = isSmallGrid ? -1 : -thickness*2;
		var offY = isSmallGrid ? -1 : -thickness*2;
		var iconTd = ed.iconTilesetUid==null ? null : Editor.ME.project.defs.getTilesetDef(ed.iconTilesetUid);

		for(tileId in 0...tilesetDef.cWid*tilesetDef.cHei) {
			var x = tilesetDef.getTileSourceX(tileId);
			var y = tilesetDef.getTileSourceY(tileId);
			var n = 0;

			for(ev in ed.values)
				if( tilesetDef.hasTag(ev.id, tileId) && ( curEnumValue==null || curEnumValue==ev.id ) ) {
					if( ev.tileId!=null && iconTd!=null ) {
						// Render icon tile
						iconTd.drawTileTo2dContext(ctx, ev.tileId, x-n*offX, y-n*offY);
					}
					else {
						// Contrast outline
						if( !isSmallGrid ) {
							ctx.beginPath();
							ctx.rect(
								x+thickness*0.5 + n*offX,
								y+thickness*0.5 + n*offY,
								tilesetDef.tileGridSize-thickness-1,
								tilesetDef.tileGridSize-thickness-1
							);
							ctx.strokeStyle = C.intToHex( C.getLuminosity(ev.color)>=0.2 ? 0x0 : C.setLuminosityInt(ev.color,0.3) );
							ctx.lineWidth = thickness+2;
							ctx.stroke();
						}

						// Color rect
						ctx.beginPath();
						ctx.rect(
							x+thickness*0.5 + n*offX,
							y+thickness*0.5 + n*offY,
							tilesetDef.tileGridSize-thickness - (isSmallGrid?0:1),
							tilesetDef.tileGridSize-thickness - (isSmallGrid?0:1)
						);
						ctx.strokeStyle = C.intToHex( ev.color );
						ctx.lineWidth = thickness;
						ctx.stroke();
					}

					n++;

				}

			if( n==0 && curEnumValue!=null ) {
				// Darken tile if there's no tag
				ctx.beginPath();
				ctx.rect(x, y, tilesetDef.tileGridSize, tilesetDef.tileGridSize );
				ctx.fillStyle = C.intToHexRGBA( C.addAlphaF(0x0, 0.3) );
				ctx.fill();
			}

		}
	}


	function setPendingCustom(v:Bool) {
		pendingCustom = v;

		if( pendingCustom ) {
			selectEnumValue(null);
			jCustomBt.html("&lt; Pick tile");
			jCustomBt.addClass("pending");
			jValues.addClass("faded");
			setSelectionMode(None);
		}
		else {
			jCustomBt.text("Custom data");
			jCustomBt.removeClass("pending");
			jValues.removeClass("faded");
		}
	}


	override function onPickerMouseLeave(ev:js.jquery.Event) {
		super.onPickerMouseLeave(ev);
		ui.Tip.clear();
	}

	override function onPickerMouseMove(ev:js.jquery.Event) {
		super.onPickerMouseMove(ev);

		if( tilesetDef.tagsSourceEnumUid==null || pendingCustom )
			return;

		var tid = tilesetDef.getTileId( pageToCx(ev.pageX), pageToCx(ev.pageY) );
		if( tilesetDef.hasAnyTag(tid) )
			ui.Tip.simpleTip(ev.pageX, ev.pageY, tilesetDef.getAllTagsAt(tid).join(", "));
		else
			ui.Tip.clear();
	}

	override function updateCursor(pageX:Float, pageY:Float, force:Bool = false) {
		super.updateCursor(pageX, pageY, force);

		if( pendingCustom )
			setCursorCss("pick");
		else if( curEnumValue!=null )
			setCursorCss("paint");
	}

	override function onSelect(tileIds:Array<Int>, added:Bool) {
		super.onSelect(tileIds, added);
		if( curEnumValue!=null ) {
			for(tid in tileIds)
				tilesetDef.setTag(tid, curEnumValue, added);
			setSelectedTileIds([]);
			refresh();
		}
	}
}