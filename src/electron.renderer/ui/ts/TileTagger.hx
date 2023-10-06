package ui.ts;

class TileTagger extends ui.Tileset {
	var ed : Null<data.def.EnumDef>;
	var jTools : js.jquery.JQuery;
	var jValues : js.jquery.JQuery;

	var dataImg : js.html.Image;
	var dataTinyImg : js.html.Image;

	var curEnumValue : Null<String>;

	public function new(target, td) {
		super(target, td, None);
		this.ed = td.getTagsEnumDef();
		useSavedSelections = false;

		jWrapper.addClass("tileTagger");

		jTools = new J('<div class="tools"/>');
		jTools.appendTo(jWrapper);

		jValues = new J('<ul class="values niceList"/>');
		jValues.appendTo(jTools);

		// Add Enum values
		jValues.off().empty();
		ed = tilesetDef.getTagsEnumDef();
		if( ed!=null ) {
			var jVal = new J('<li value="none" class="none">Custom data</li>');
			jVal.appendTo(jValues);
			jVal.click( ev->{
				selectEnumValue(null);
			});

			for(ev in ed.values) {
				var jVal = new J('<li value="${ev.id}">${ev.id}</li>');
				if( ev.tileRect!=null ) {
					var iconTd = Editor.ME.project.defs.getTilesetDef(ed.iconTilesetUid);
					if( iconTd!=null )
						jVal.prepend( iconTd.createCanvasFromTileRect(ev.tileRect, 16) );
				}
				jVal.appendTo(jValues);
				jVal.css({
					borderColor: C.intToHex(ev.color),
					backgroundColor: C.intToHex( C.toBlack(ev.color,0.4) ),
				});
				jVal.click( _->{
					selectEnumValue(ev.id);
				});
			}
			jValues.find('[value=${curEnumValue==null ? "none" : curEnumValue}]').addClass("active");
		}

		// Init "data" icons
		var t = Assets.elements.getTile("dataIcon");
		var pixels = Assets.elementsPixels.sub( Std.int(t.x), Std.int(t.y), Std.int(t.width), Std.int(t.height));
		var b64 = haxe.crypto.Base64.encode( pixels.toPNG() );
		dataImg = new js.html.Image(pixels.width, pixels.height);
		dataImg.src = 'data:image/png;base64,$b64';

		var t = Assets.elements.getTile("dataIconTiny");
		var pixels = Assets.elementsPixels.sub( Std.int(t.x), Std.int(t.y), Std.int(t.width), Std.int(t.height));
		var b64 = haxe.crypto.Base64.encode( pixels.toPNG() );
		dataTinyImg = new js.html.Image(pixels.width, pixels.height);
		dataTinyImg.src = 'data:image/png;base64,$b64';

		selectEnumValue();
	}


	function selectEnumValue(?id:String) {
		jValues.find(".active").removeClass("active");
		curEnumValue = id;

		if( id!=null ) {
			setSelectionMode(TileRect);
			jValues.find('[value=$id]').addClass("active");
		}
		else {
			setSelectionMode(OneTile);
			jValues.find('[value=none]').addClass("active");
		}

		refresh();
	}


	function refresh() {
		var ctx = canvas.getContext2d();

		// Clear
		renderAtlas();

		if( tilesetDef.tagsSourceEnumUid!=null )
			jTools.show();
		else
			jTools.hide();

		// No tags
		if( tilesetDef.tagsSourceEnumUid==null && !tilesetDef.hasAnyTileCustomData() ) {
			renderGrid();
			return;
		}

		var isSmallGrid = tilesetDef.tileGridSize<16;
		var thickness = M.imax(1, Std.int( tilesetDef.tileGridSize / 16 ) );
		var offX = isSmallGrid ? -1 : -thickness*2;
		var offY = isSmallGrid ? -1 : -thickness*2;
		var iconTd = tilesetDef.tagsSourceEnumUid==null || ed.iconTilesetUid==null ? null : Editor.ME.project.defs.getTilesetDef(ed.iconTilesetUid);

		for(tileId in 0...tilesetDef.cWid*tilesetDef.cHei) {
			var x = tilesetDef.getTileSourceX(tileId);
			var y = tilesetDef.getTileSourceY(tileId);
			var n = 0;

			// Enum tags
			if( tilesetDef.tagsSourceEnumUid!=null ) {
				for(ev in ed.values)
					if( tilesetDef.hasTag(ev.id, tileId) && ( curEnumValue==null || curEnumValue==ev.id ) ) {
						if( ev.tileRect!=null && iconTd!=null ) {
							// Render icon tile
							var s = tilesetDef.tileGridSize / iconTd.tileGridSize;
							iconTd.drawTileRectTo2dContext(ctx, ev.tileRect, x-n*offX, y-n*offY, s,s);
						}
						// else {
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
						// }

						n++;

					}

				// Darken tile if there's no tag
				if( n==0 && curEnumValue!=null ) {
					ctx.beginPath();
					ctx.rect(x, y, tilesetDef.tileGridSize, tilesetDef.tileGridSize );
					ctx.fillStyle = C.intToHexRGBA( C.addAlphaF(0x0, 0.3) );
					ctx.fill();
				}
			}

			// Custom data icons
			if( tilesetDef.hasTileCustomData(tileId) ) {
				var img = tilesetDef.tileGridSize<16 ? dataTinyImg : dataImg;
				var scale = M.imax(1, M.floor(tilesetDef.tileGridSize/32) );
				if( img.complete )
					ctx.drawImage(img, x, y, img.width*scale, img.height*scale);
				else
					img.onload = ()->ctx.drawImage(img, x, y, img.width*scale, img.height*scale);
			}
		}
	}


	override function onPickerMouseLeave(ev:js.jquery.Event) {
		super.onPickerMouseLeave(ev);
		ui.Tip.clear();
	}

	override function onPickerMouseMove(ev:js.jquery.Event) {
		super.onPickerMouseMove(ev);

		// if( tilesetDef.tagsSourceEnumUid==null )
		// 	return;

		var cx = pageToCx(ev.pageX,false);
		var cy = pageToCy(ev.pageY,false);
		if( cx>=0 && cx<tilesetDef.cWid && cy>=0 && cy<tilesetDef.cHei ) {
			var tid = tilesetDef.getTileId( cx, cy );
			var tipTxt = '**Tile $tid**';
			var tipCol : Null<Int> = null;
			if( tilesetDef.hasAnyTag(tid) ) {
				tipTxt += tilesetDef.getAllTagsAt(tid).join(" + ");
				var tag = tilesetDef.getAllTagsAt(tid)[0];
				tipCol = tilesetDef.getTagsEnumDef().getValue(tag).color;
			}
			if( tilesetDef.hasTileCustomData(tid) )
				tipTxt+="\n\""+tilesetDef.getTileCustomData(tid)+"\"";

			var tip = ui.Tip.simpleTip(ev.pageX, ev.pageY, tipTxt);
			if( tipCol!=null )
				tip.setColor(tipCol);
		}
		else
			ui.Tip.clear();
	}

	override function updateCursor(pageX:Float, pageY:Float, force:Bool = false) {
		super.updateCursor(pageX, pageY, force);

		if( curEnumValue==null )
			setCursorCss("pick");
		else
			setCursorCss("paint");
	}

	override function onSelect(tileIds:Array<Int>, added:Bool) {
		super.onSelect(tileIds, added);

		if( curEnumValue!=null ) {
			// Set/unset enum tags
			for(tid in tileIds)
				tilesetDef.setTag(tid, curEnumValue, added);
			Editor.ME.ge.emit( TilesetEnumChanged );
			refresh();
		}
		else {
			// Custom data
			var tid = tileIds[0];
			if( added ) {
				// Add
				var te = new ui.modal.dialog.TextEditor(
					tilesetDef.hasTileCustomData(tid) ? tilesetDef.getTileCustomData(tid) : "",
					'Tile $tid custom data',
					'You can enter any kind of data here, which will be associated to this tile and stored in the project JSON.\nThis data could either be numbers, text, JSON, XML etc. Basically, any tile related info you would like to pass to your game engine.',
					LangJson,
					(str)->{
						str = StringTools.trim(str);
						if( str.length==0 )
							tilesetDef.setTileCustomData(tid);
						else
							tilesetDef.setTileCustomData(tid, str);
						refresh();
					}
				);
				te.jHeader.append( tilesetDef.createTileHtmlImageFromTileId(tid, 64) );
			}
			else {
				// Remove
				new ui.modal.dialog.Confirm(
					L.t._("Clear custom data for tile ::tid::?", { tid:tid }),
					true,
					()->{
						tilesetDef.setTileCustomData(tid);
						refresh();
					}
				);
			}

		}
		setSelectedTileIds([]);
	}
}