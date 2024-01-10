package ui.modal.panel;

class EditTilesetDefs extends ui.modal.Panel {
	var jList : js.jquery.JQuery;
	var jForm : js.jquery.JQuery;
	public var curTd : Null<data.def.TilesetDef>;
	var search : QuickSearch;


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

		// Create quick search
		search = new ui.QuickSearch( jList );
		search.jWrapper.appendTo( jContent.find(".search") );

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

			case LayerInstancesRestoredFromHistory(_):
				updateList();
				updateForm();
				updateTilesetPreview();

			case TilesetDefChanged(td):
				updateList();
				updateForm();
				updateTilesetPreview();
				if( td==curTd )
					curTd.buildPixelDataAndNotify();

			case TilesetImageLoaded(td, init):
				updateForm();
				updateTilesetPreview();
				if( td==curTd )
					curTd.buildPixelDataAndNotify();

			case TilesetMetaDataChanged(td):
				updateTilesetPreview();

			case TilesetDefPixelDataCacheRebuilt(td):
				if( td==curTd )
					updateTilesetPreview();

			case _:
		}
	}

	public function selectTileset(td:data.def.TilesetDef) {
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
			if( curTd.isUsingEmbedAtlas() )
				new ui.Tileset(jPickerWrapper, curTd);
			else
				new ui.ts.TileTagger(jPickerWrapper, curTd);

		JsTools.parseComponents(jPickerWrapper);

		checkBackup();
	}



	function updateForm() {
		jForm.find("*").off(); // cleanup event listeners
		var jEmbed = jContent.find(".embedTileset");

		if( curTd==null ) {
			jForm.hide();
			jEmbed.hide();
			jContent.find(".none").show();
			return;
		}

		jForm.show();
		jContent.find(".none").hide();

		if( curTd.isUsingEmbedAtlas() ) {
			jForm.addClass("embed");
			var inf = Lang.getEmbedAtlasInfos(curTd.embedAtlas);
			jEmbed.find(".author").html('<a href="${inf.url}">${inf.author}</a>');
			var jInfoWrapper = jEmbed.find(".infos");
			jInfoWrapper.empty();
			var jInfAuthor = new J('<div class="author"/>');
			jInfoWrapper.append(jInfAuthor);
			jInfAuthor.append('Image by <strong>${inf.author}</strong>');
			jInfAuthor.append(' (<a href="${inf.url}">website</a>)');
			jInfoWrapper.append('<button class="blue" href="${inf.support.url}"><span class="icon love"></span> ${inf.support.label}</button>');
			JsTools.parseComponents(jEmbed);
		}
		else
			jForm.removeClass("embed");

		// Image file picker
		jForm.find("dd.img").empty();
		if( curTd.isUsingEmbedAtlas() )
			jForm.find("dd.img").append("<span>This tileset uses an embed atlas image.</span>");
		else {
			var jImg = JsTools.createImagePicker(project, curTd.relPath, (relPath)->{
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

						case FileNotFound, LoadingFailed(_), UnsupportedFileOrigin(_):
							new ui.modal.dialog.Warning( Lang.imageLoadingMessage(relPath, result) );
							return;

						case TrimmedPadding, RemapLoss, RemapSuccessful:
							new ui.modal.dialog.Message( Lang.imageLoadingMessage(relPath, result), "tile" );
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
		}


		// Fields
		var i = Input.linkToHtmlInput(curTd.identifier, jForm.find("input[name='name']") );
		i.fixValue = (v)->project.fixUniqueIdStr(v, (id)->project.defs.isTilesetIdentifierUnique(id,curTd));
		i.onChange = editor.ge.emit.bind( TilesetDefChanged(curTd) );

		var i = Input.linkToHtmlInput( curTd.tileGridSize, jForm.find("input[name=tilesetGridSize]") );
		i.setBounds(2, curTd.getMaxTileGridSize());
		var oldGrid = curTd.tileGridSize;
		i.onChange = ()->{
			new LastChance(L.t._("Tileset grid changed"), project);

			var result = curTd.remapAllTileIdsAfterGridChange(oldGrid);
			editor.ge.emit(TilesetDefChanged(curTd));

			switch result {
				case Ok:
					N.msg("No change");

				case RemapLoss:
					new ui.modal.dialog.Warning(L.t._("The new grid size is larger than the previous one.\nSome tiles may have been lost in the remapping process."));

				case RemapSuccessful:
					new ui.modal.dialog.Message(L.t._("All tiles were successfully remapped."));

				case _:
					N.error("Unknown remapping result: "+result);
			}
		}

		var i = Input.linkToHtmlInput( curTd.spacing, jForm.find("input[name=spacing]") );
		i.linkEvent( TilesetDefChanged(curTd) );
		i.setBounds(0, curTd.getMaxTileGridSize());

		var i = Input.linkToHtmlInput( curTd.padding, jForm.find("input[name=padding]") );
		i.linkEvent( TilesetDefChanged(curTd) );
		i.setBounds(0, curTd.getMaxTileGridSize());


		// Tags
		var ted = new TagEditor(
			curTd.tags,
			()->editor.ge.emit(TilesetDefChanged(curTd)),
			()->project.defs.getRecallTags(project.defs.tilesets, td->td.tags),
			()->project.defs.tilesets.map( td->td.tags ),
			(oldT,newT)->{
				for(td in project.defs.tilesets)
					td.tags.rename(oldT,newT);
				editor.ge.emit( TilesetDefChanged(curTd) );
			},
			true
		);
		jForm.find("#tags").empty().append(ted.jEditor);

		// Tags source Enum selector
		var jSelect = jForm.find("#tagsSourceEnumUid");
		jSelect.empty();
		var jOpt = new J('<option value="">-- None --</option>');
		jOpt.appendTo(jSelect);
		var tagGroups = project.defs.getAllEnumsGroupedByTag();
		for( group in tagGroups ) {
			var jOptGroup = new J('<optgroup label="All enums"/>');
			jOptGroup.appendTo(jSelect);
			if( tagGroups.length>1 )
				jOptGroup.attr('label', group.tag==null ? L._Untagged() : group.tag);
			for(ed in group.all) {
				var jOpt = new J('<option value="${ed.uid}">${ed.identifier}</option>');
				if( ed.isExternal() ) {
					jOpt.prop("disabled",true);
					jOpt.append(' (unsupported external enum)');
				}
				jOpt.appendTo(jOptGroup);
			}
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

		JsTools.parseComponents(jForm);
		checkBackup();
	}


	function updateList() {
		jList.empty();

		// List context menu
		ContextMenu.attachTo(jList, false, [
			{
				label: L._Paste(),
				cb: ()->{
					var copy = project.defs.pasteTilesetDef(App.ME.clipboard);
					editor.ge.emit( TilesetDefAdded(copy) );
					selectTileset(copy);
				},
				enable: ()->App.ME.clipboard.is(CTilesetDef),
			},
		]);

		var tagGroups = project.defs.groupUsingTags(project.defs.tilesets, td->td.tags);
		for( group in tagGroups) {
			// Tag name
			if( tagGroups.length>1 ) {
				var jSep = new J('<li class="title collapser"/>');
				jSep.text( group.tag==null ? L._Untagged() : group.tag );
				jSep.appendTo(jList);
				jSep.attr("id", project.iid+"_tileset_tag_"+group.tag);
				jSep.attr("default", "open");
			}

			var jLi = new J('<li class="subList"/>');
			jLi.appendTo(jList);
			var jSubList = new J('<ul class="niceList compact"/>');
			jSubList.appendTo(jLi);

			for(td in group.all) {
				var jLi = new J('<li class="draggable"/>');
				jSubList.append(jLi);

				jLi.append('<span class="name">'+td.identifier+'</span>');
				jLi.data("uid",td.uid);
				if( curTd==td )
					jLi.addClass("active");

				if( td.isUsingEmbedAtlas() )
					jLi.find(".name").prepend('<span class="icon embed"/>');

				jLi.click( function(_) selectTileset(td) );

				ContextMenu.attachTo_new(jLi, (ctx:ContextMenu)->{
					ctx.addElement( Ctx_CopyPaster({
						elementName: "tileset",
						clipType: CTilesetDef,
						copy: td.isUsingEmbedAtlas() ? null : ()->App.ME.clipboard.copyData(CTilesetDef, td.toJson()),
						cut: td.isUsingEmbedAtlas() ? null : ()->{
							App.ME.clipboard.copyData(CTilesetDef, td.toJson());
							deleteTilesetDef(td);
						},
						paste: ()->{
							var copy = project.defs.pasteTilesetDef(App.ME.clipboard, td);
							editor.ge.emit( TilesetDefAdded(copy) );
							selectTileset(copy);
						},
						duplicate: td.isUsingEmbedAtlas() ? null : ()->{
							var copy = project.defs.duplicateTilesetDef(td);
							editor.ge.emit( TilesetDefAdded(copy) );
							selectTileset(copy);
						},
						delete: ()->deleteTilesetDef(td),
					}) );
				});
			}

			// Make list sortable
			JsTools.makeSortable(jSubList, function(ev) {
				var jItem = new J(ev.item);
				var fromIdx = project.defs.getTilesetIndex( jItem.data("uid") );
				var toIdx = ev.newIndex>ev.oldIndex
					? jItem.prev().length==0 ? 0 : project.defs.getTilesetIndex( jItem.prev().data("uid") )
					: jItem.next().length==0 ? project.defs.tilesets.length-1 : project.defs.getTilesetIndex( jItem.next().data("uid") );

				var moved = project.defs.sortTilesetDef(fromIdx, toIdx);
				selectTileset(moved);
				editor.ge.emit(TilesetDefSorted);
			}, { onlyDraggables:true });
		}

		JsTools.parseComponents(jList);
		checkBackup();
		search.run();
	}
}
