package ui.modal.panel;

class EditTilesetDefs extends ui.modal.Panel {
	var jList : js.jquery.JQuery;
	var jForm : js.jquery.JQuery;
	public var curTd : Null<data.def.TilesetDef>;

	var curEnumValue : Null<data.DataTypes.EnumDefValue>;


	public function new(?selectedDef:data.def.TilesetDef) {
		super();

		loadTemplate( "editTilesetDefs", "defEditor editTilesetDefs" );
		jList = jModalAndMask.find(".mainList ul");
		jForm = jModalAndMask.find("dl.form");
		linkToButton("button.editTilesets");

		// Create tileset
		jModalAndMask.find(".mainList button.create").click( function(ev) {
			var td = project.defs.createTilesetDef();
			selectTileset(td);
			editor.ge.emit( TilesetDefAdded(td) );
			jForm.find("input").first().focus().select();
		});

		selectTileset(selectedDef!=null ? selectedDef : project.defs.tilesets[0]);
	}

	function deleteTilesetDef(td:data.def.TilesetDef) {
		new LastChance(L.t._("Tileset ::name:: deleted", { name:td.identifier }), project);
		var old = td;
		project.defs.removeTilesetDef(td);
		selectTileset(project.defs.tilesets[0]);
		editor.ge.emit( TilesetDefRemoved(old) );
	}

	override function onGlobalEvent(e:GlobalEvent) {
		super.onGlobalEvent(e);
		switch e {
			case ProjectSettingsChanged, ProjectSelected, LevelSettingsChanged(_), LevelSelected(_):
				close();

			case LayerInstanceRestoredFromHistory(li):
				updateList();
				updateForm();
				updateTilesetPreview();

			case TilesetDefChanged(td):
				updateList();
				updateForm();
				updateTilesetPreview();
				if( td==curTd )
					rebuildPixelData();

			case TilesetMetaDataChanged(td):
				updateTilesetPreview();

			case TilesetDefPixelDataCacheRebuilt(td):
				if( td==curTd )
					updateTilesetPreview();

			case _:
		}
	}

	function selectTileset(td:data.def.TilesetDef) {
		curTd = td;
		curEnumValue = null;
		updateList();
		updateForm();
		updateTilesetPreview();
	}



	function updateTilesetPreview() {
		var jPickerWrapper = jContent.find(".pickerWrapper");

		if( curTd==null ) {
			jPickerWrapper.hide();
			jContent.find(".tilesDemo").hide();
			return;
		}

		jContent.find(".tilesDemo").show();

		// Main tileset view
		jPickerWrapper.show();
		var jPicker = jPickerWrapper.find(".picker");
		jPicker.empty();
		if( curTd.isAtlasLoaded() ) {
			var picker = new TilesetPicker(
				jPicker,
				curTd,
				PaintId(
					()->curEnumValue==null ? null : curEnumValue.id,
					(tid:Int, valueId:Null<String>, active:Bool)->{
						if( valueId!=null )
							curTd.setTag(tid, valueId, active);
						else if( !active )
							curTd.removeAllTagsAt(tid);
						editor.ge.emitAtTheEndOfFrame( TilesetMetaDataChanged(curTd) );
					}
				)
			);

			// Meta-data render
			if( curTd.tagsSourceEnumUid!=null ) {
				// Picker tooltip
				picker.onMouseMoveCustom = (event, tid:Int)->{
					if( curTd.hasAnyTag(tid) )
						ui.Tip.simpleTip(event.pageX, event.pageY, curTd.getAllTagsAt(tid).join(", "));
					else
						ui.Tip.clear();
				}
				picker.onMouseLeaveCustom = (_)->ui.Tip.clear();

				// Custom picker grid rendering
				var n = 0;
				var ed = curTd.getTagsEnumDef();
				var isSmallGrid = curTd.tileGridSize<16;
				var thickness = M.imax(1, Std.int( curTd.tileGridSize / 16 ) );
				var offX = isSmallGrid ? -1 : -thickness*2;
				var offY = isSmallGrid ? -1 : -thickness*2;
				picker.customTileRender = (ctx,x,y,tid)->{
					n = 0;
					var iconTd = ed.iconTilesetUid==null ? null : project.defs.getTilesetDef(ed.iconTilesetUid);
					for(ev in ed.values)
						if( curTd.hasTag(ev.id, tid) && ( curEnumValue==null || curEnumValue==ev ) ) {
							if( ev.tileId!=null && iconTd!=null ) {
								// Tile
								iconTd.drawTileTo2dContext(ctx, ev.tileId, x-n*offX, y-n*offY);
							}
							else {
								// Contrast outline
								if( !isSmallGrid ) {
									ctx.beginPath();
									ctx.rect(
										x+thickness*0.5 + n*offX,
										y+thickness*0.5 + n*offY,
										curTd.tileGridSize-thickness-1,
										curTd.tileGridSize-thickness-1
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
									curTd.tileGridSize-thickness - (isSmallGrid?0:1),
									curTd.tileGridSize-thickness - (isSmallGrid?0:1)
								);
								ctx.strokeStyle = C.intToHex( ev.color );
								ctx.lineWidth = thickness;
								ctx.stroke();
							}

							n++;
						}

					if( n==0 && curEnumValue!=null ) {
						// No meta
						ctx.beginPath();
						ctx.rect(x, y, curTd.tileGridSize, curTd.tileGridSize );
						ctx.fillStyle = C.intToHexRGBA( C.addAlphaF(0x0, 0.66) );
						ctx.fill();
					}
					return true;
				}
			}
			picker.renderGrid();
		}

		// Enum values
		var jValues = jPickerWrapper.find(".values");
		jValues.empty();
		var ed = curTd.getTagsEnumDef();
		if( ed==null )
			jValues.hide();
		else {
			jValues.show();

			function _selectEnumValue(?ev:data.DataTypes.EnumDefValue) {
				curEnumValue = ev;
				jValues.find(".active").removeClass("active");
				jValues.find('[value=${ev==null?null:ev.id}]').addClass("active");
				updateTilesetPreview();
			}

			var jVal = new J('<li value="null" class="none">-- Show all --</li>');
			jVal.appendTo(jValues);
			jVal.click( ev->_selectEnumValue(null) );

			for(ev in ed.values) {
				var jVal = new J('<li value="${ev.id}">${ev.id}</li>');
				if( ev.tileId!=null ) {
					var iconTd = project.defs.getTilesetDef(ed.iconTilesetUid);
					if( iconTd!=null )
						jVal.prepend( JsTools.createTile(iconTd, ev.tileId, 16) );
				}
				jVal.appendTo(jValues);
				jVal.css({
					borderColor: C.intToHex(ev.color),
					backgroundColor: C.intToHex( C.toBlack(ev.color,0.4) ),
				});
				jVal.click( _->_selectEnumValue(ev) );
			}
			jValues.find('[value=${curEnumValue==null ? null : curEnumValue.id}]').addClass("active");

		}

		// Demo tiles
		var padding = 8;
		var jDemo = jContent.find(".tilesDemo canvas");
		JsTools.clearCanvas(jDemo);

		if( curTd!=null && curTd.isAtlasLoaded() ) {
			jDemo.attr("width", curTd.tileGridSize*8 + padding*7);
			jDemo.attr("height", curTd.tileGridSize);

			var idx = 0;
			function renderDemoTile(tcx,tcy) {
				curTd.drawTileToCanvas(jDemo, curTd.getTileId(tcx,tcy), (idx++)*(curTd.tileGridSize+padding), 0);
			}
			renderDemoTile(0,0);
			renderDemoTile(1,0);
			renderDemoTile(2,0);
			renderDemoTile(0,1);
			renderDemoTile(0,2);
			renderDemoTile(0,3);
			renderDemoTile(0,4);
		}
	}


	inline function rebuildPixelData() {
		curTd.buildPixelData( Editor.ME.ge.emit.bind(TilesetDefPixelDataCacheRebuilt(curTd)) );
	}


	function updateForm() {
		jForm.find("*").off(); // cleanup event listeners

		if( curTd==null ) {
			jForm.hide();
			// jContent.find(".noTileLayer").hide();
			jContent.find(".none").show();
			return;
		}

		JsTools.parseComponents(jForm);
		jForm.show();
		jContent.find(".none").hide();
		// if( !project.defs.hasLayerType(Tiles) && !project.defs.hasAutoLayer() )
		// 	jContent.find(".noTileLayer").show();
		// else
		// 	jContent.find(".noTileLayer").hide();

		// Image file picker
		jForm.find(".imagePicker").remove();
		var jImg = JsTools.createImagePicker(curTd.relPath, (?relPath)->{
			var oldRelPath = curTd.relPath;
			if( relPath==null ) {
				// Remove image
				if( oldRelPath!=null )
					editor.watcher.stopWatchingRel(oldRelPath);
				curTd.removeAtlasImage();
			}
			else {
				// Load image
				App.LOG.fileOp("Loading atlas: "+project.makeAbsoluteFilePath(relPath));

				var result = curTd.importAtlasImage(relPath);
				switch result {
					case Ok:

					case FileNotFound, LoadingFailed(_):
						new ui.modal.dialog.Warning( Lang.atlasLoadingMessage(relPath, result) );
						return;

					case TrimmedPadding, RemapLoss, RemapSuccessful:
						new ui.modal.dialog.Message( Lang.atlasLoadingMessage(relPath, result), "tile" );
				}

				if( oldRelPath!=null )
					editor.watcher.stopWatchingRel(oldRelPath);
				editor.watcher.watchImage(curTd.relPath);
				project.defs.autoRenameTilesetIdentifier(oldRelPath, curTd);
			}

			updateTilesetPreview();
			editor.ge.emit( TilesetDefChanged(curTd) );
		});
		jImg.appendTo( jForm.find("dd.img") );


		// Fields
		var i = Input.linkToHtmlInput(curTd.identifier, jForm.find("input[name='name']") );
		i.fixValue = (v)->project.makeUniqueIdStr(v, (id)->project.defs.isTilesetIdentifierUnique(id,curTd));
		i.onChange = editor.ge.emit.bind( TilesetDefChanged(curTd) );

		var i = Input.linkToHtmlInput( curTd.tileGridSize, jForm.find("input[name=tilesetGridSize]") );
		i.linkEvent( TilesetDefChanged(curTd) );
		i.setBounds(2, curTd.getMaxTileGridSize());

		var i = Input.linkToHtmlInput( curTd.spacing, jForm.find("input[name=spacing]") );
		i.linkEvent( TilesetDefChanged(curTd) );
		i.setBounds(0, curTd.getMaxTileGridSize());

		var i = Input.linkToHtmlInput( curTd.padding, jForm.find("input[name=padding]") );
		i.linkEvent( TilesetDefChanged(curTd) );
		i.setBounds(0, curTd.getMaxTileGridSize());

		// Tags source Enum selector
		var jSelect = jForm.find("#tagsSourceEnumUid");
		jSelect.empty();
		var jOpt = new J('<option value="">-- None --</option>');
		jOpt.appendTo(jSelect);
		for( ed in project.defs.getAllEnumsSorted() ) {
			var jOpt = new J('<option value="${ed.uid}">${ed.identifier}</option>');
			jOpt.appendTo(jSelect);
		}
		var oldUid = curTd.tagsSourceEnumUid;
		jSelect.change( ev->{
			// Change enum
			var uid = Std.parseInt( jSelect.val() );
			if( !M.isValidNumber(uid) )
				uid = null;

			function _apply() {
				curTd.tagsSourceEnumUid = uid;
				editor.ge.emit( TilesetDefChanged(curTd) );
			}
			if( oldUid!=null && oldUid!=uid && curTd.hasAnyTag() )
				new ui.modal.dialog.Confirm(
					jSelect,
					L.t._("Be careful: you have tags in this tileset. You will LOSE them by changing the source Enum!"),
					true,
					()->{
						new LastChance(L.t._("Tileset tags removed"), project);
						_apply();
					},
					()->jSelect.val(Std.string(oldUid))
				);
			else
				_apply();
		});
		if( curTd.tagsSourceEnumUid!=null )
			jSelect.val(curTd.tagsSourceEnumUid);
	}


	function updateList() {
		jList.empty();

		for(td in project.defs.tilesets) {
			var e = new J("<li/>");
			jList.append(e);

			e.append('<span class="name">'+td.identifier+'</span>');
			if( curTd==td )
				e.addClass("active");

			e.click( function(_) selectTileset(td) );

			ContextMenu.addTo(e, [
				{
					label: L._Duplicate(),
					cb: ()-> {
						var copy = project.defs.duplicateTilesetDef(td);
						editor.ge.emit( TilesetDefAdded(copy) );
						selectTileset(copy);
					},
				},
				{
					label: L._Delete(),
					cb: deleteTilesetDef.bind(td),
				},
			]);
		}
	}
}
