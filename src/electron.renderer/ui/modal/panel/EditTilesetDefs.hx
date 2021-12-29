package ui.modal.panel;

class EditTilesetDefs extends ui.modal.Panel {
	var jList : js.jquery.JQuery;
	var jForm : js.jquery.JQuery;
	public var curTd : Null<data.def.TilesetDef>;


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
			jForm.find(".imagePicker .pick").click();
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

			case TilesetImageLoaded(td, init):
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
		updateList();
		updateForm();
		updateTilesetPreview();
	}



	function updateTilesetPreview() {
		ui.Tip.clear();

		var jPickerWrapper = jContent.find(".pickerWrapper");

		// No atlas
		if( curTd==null ) {
			jPickerWrapper.hide();
			return;
		}

		jPickerWrapper.off().empty();

		// Picker / tagger
		jPickerWrapper.show();
		if( curTd.isAtlasLoaded() )
			new ui.ts.TileTagger(jPickerWrapper, curTd);

		JsTools.parseComponents(jPickerWrapper);

		checkBackup();
	}


	inline function rebuildPixelData() {
		curTd.buildPixelData( Editor.ME.ge.emit.bind(TilesetDefPixelDataCacheRebuilt(curTd)) );
	}


	function updateForm() {
		jForm.find("*").off(); // cleanup event listeners

		if( curTd==null ) {
			jForm.hide();
			jContent.find(".none").show();
			return;
		}

		JsTools.parseComponents(jForm);
		jForm.show();
		jContent.find(".none").hide();

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
			editor.ge.emit( TilesetImageLoaded(curTd, false) );
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
			if( ed.isExternal() ) {
				jOpt.prop("disabled",true);
				jOpt.append(' (unsupported external enum)');
			}
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
		if( curTd.tagsSourceEnumUid!=null ) {
			jSelect.removeClass("noValue");
			jSelect.val(curTd.tagsSourceEnumUid);
		}
		else
			jSelect.addClass("noValue");

		checkBackup();
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

		// Make list sortable
		JsTools.makeSortable(jList, function(ev) {
			var moved = project.defs.sortTilesetDef(ev.oldIndex, ev.newIndex);
			selectTileset(moved);
			editor.ge.emit(TilesetDefSorted);
		});

		checkBackup();
	}
}
