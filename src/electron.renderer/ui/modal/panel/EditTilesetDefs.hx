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
							curTd.setMetaDataInt(tid, valueId, active);
						else if( !active )
							curTd.removeAllMetaDataAt(tid);
						editor.ge.emitAtTheEndOfFrame( TilesetMetaDataChanged(curTd) );
					}
				)
			);

			// Meta-data render
			if( curTd.metaDataEnumUid!=null ) {
				var n = 0;
				var ed = curTd.getMetaDataEnumDef();
				var thick = M.fmax( 2, 1+Std.int( curTd.tileGridSize / 16 ) );
				picker.customTileRender = (ctx,x,y,tid)->{
					n = 0;
					var iconTd = ed.iconTilesetUid==null ? null : project.defs.getTilesetDef(ed.iconTilesetUid);
					for(ev in ed.values)
						if( curTd.hasMetaDataEnumAt(ev.id, tid) && ( curEnumValue==null || curEnumValue==ev ) ) {
							if( ev.tileId!=null && iconTd!=null ) {
								// Tile
								iconTd.drawTileTo2dContext(ctx, ev.tileId, x-n*2, y-n*4);
							}
							else {
								// Color
								ctx.beginPath();
								ctx.rect(
									x+thick*0.5 - n*2,
									y+thick*0.5 - n*4,
									curTd.tileGridSize-thick,
									curTd.tileGridSize-thick
								);
								// Fill
								ctx.fillStyle = C.intToHexRGBA( C.addAlphaF(ev.color, 0) );
								ctx.fill();
								// Black outline
								ctx.strokeStyle = C.intToHex( 0x0 );
								ctx.lineWidth = thick+2;
								ctx.stroke();
								// Outline
								ctx.strokeStyle = C.intToHex( ev.color );
								ctx.lineWidth = thick;
								ctx.stroke();
							}

							n++;
						}

					if( n==0 && curEnumValue!=null ) {
						// No meta
						ctx.beginPath();
						ctx.rect(x, y, curTd.tileGridSize, curTd.tileGridSize );
						ctx.fillStyle = C.intToHexRGBA( C.addAlphaF(0x0, 0.5) );
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
		var ed = curTd.getMetaDataEnumDef();
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
				if( ev.tileId!=null )
					jVal.prepend( JsTools.createTile(curTd, ev.tileId, 16) );
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

		// Metadata Enum selector
		var jSelect = jForm.find("#metaDataEnumUid");
		jSelect.empty();
		var jOpt = new J('<option value="">-- None --</option>');
		jOpt.appendTo(jSelect);
		for( ed in project.defs.getAllEnumsSorted() ) {
			var jOpt = new J('<option value="${ed.uid}">${ed.identifier}</option>');
			jOpt.appendTo(jSelect);
		}
		jSelect.change( ev->{
			var uid = Std.parseInt( jSelect.val() );
			if( !M.isValidNumber(uid) )
				uid = null;
			curTd.metaDataEnumUid = uid;
			editor.ge.emit( TilesetDefChanged(curTd) );
		});
		if( curTd.metaDataEnumUid!=null )
			jSelect.val(curTd.metaDataEnumUid);
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
