package ui.modal.panel;

class EditTilesetDefs extends ui.modal.Panel {
	var jList : js.jquery.JQuery;
	var jForm : js.jquery.JQuery;
	public var cur : Null<data.def.TilesetDef>;

	public function new(?selectedDef:data.def.TilesetDef) {
		super();

		loadTemplate( "editTilesetDefs", "defEditor tilesetDefs" );
		jList = jModalAndMask.find(".mainList ul");
		jForm = jModalAndMask.find("ul.form");
		linkToButton("button.editTilesets");

		// Create tileset
		jModalAndMask.find(".mainList button.create").click( function(ev) {
			var td = project.defs.createTilesetDef();
			select(td);
			editor.ge.emit( TilesetDefAdded(td) );
			jForm.find("input").first().focus().select();
		});

		// Delete tileset
		jModalAndMask.find(".mainList button.delete").click( function(ev) {
			if( cur==null ) {
				N.error("No tileset selected.");
				return;
			}
			new ui.modal.dialog.Confirm(ev.getThis(), "If you delete this tileset, it will be deleted in all levels and corresponding layers as well. Are you sure?", function() {
				new LastChance(L.t._("Tileset ::name:: deleted", { name:cur.identifier }), project);
				var old = cur;
				project.defs.removeTilesetDef(cur);
				select(project.defs.tilesets[0]);
				editor.ge.emit( TilesetDefRemoved(old) );
			});
		});


		select(selectedDef!=null ? selectedDef : project.defs.tilesets[0]);
	}

	override function onGlobalEvent(e:GlobalEvent) {
		super.onGlobalEvent(e);
		switch e {
			case ProjectSettingsChanged, ProjectSelected, LevelSettingsChanged, LevelSelected:
				close();

			case LayerInstanceRestoredFromHistory(li):
				updateList();
				updateForm();
				updateTilesetPreview();

			case TilesetDefChanged(td):
				updateList();
				updateForm();
				updateTilesetPreview();

			case _:
		}
	}

	function select(td:data.def.TilesetDef) {
		cur = td;
		updateList();
		updateForm();
		updateTilesetPreview();
	}



	function updateTilesetPreview() {
		var jPickerWrapper = jContent.find(".pickerWrapper");

		if( cur==null ) {
			jPickerWrapper.hide();
			jContent.find(".tilesDemo").hide();
			return;
		}

		jContent.find(".tilesDemo").show();

		// Main tileset view
		jPickerWrapper.show().empty();
		if( cur.isAtlasLoaded() ) {
			var picker = new TilesetPicker(jPickerWrapper, cur, ViewOnly);
			picker.renderGrid();
			picker.resetScroll();
		}

		// Demo tiles
		var padding = 8;
		var jDemo = jContent.find(".tilesDemo canvas");
		JsTools.clearCanvas(jDemo);

		if( cur!=null && cur.isAtlasLoaded() ) {
			jDemo.attr("width", cur.tileGridSize*8 + padding*7);
			jDemo.attr("height", cur.tileGridSize);

			var idx = 0;
			function renderDemoTile(tcx,tcy) {
				cur.drawTileToCanvas(jDemo, cur.getTileId(tcx,tcy), (idx++)*(cur.tileGridSize+padding), 0);
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


	function updateForm() {
		jForm.find("*").off(); // cleanup event listeners

		if( cur==null ) {
			jForm.hide();
			jContent.find(".noTileLayer").hide();
			jContent.find(".none").show();
			return;
		}

		JsTools.parseComponents(jForm);
		jForm.show();
		jContent.find(".none").hide();
		if( !project.defs.hasLayerType(Tiles) )
			jContent.find(".noTileLayer").show();
		else
			jContent.find(".noTileLayer").hide();

		// Image path
		var jPath = jForm.find(".path");
		var jLocate = jForm.find(".locate");
		if( cur.relPath!=null ) {
			jPath.empty().show().append( JsTools.makePath(cur.relPath) );
			jLocate.empty().show().append( JsTools.makeExploreLink( Editor.ME.makeAbsoluteFilePath(cur.relPath) ) );
		}
		else {
			jLocate.hide();
			jPath.hide();
		}

		// Fields
		var i = Input.linkToHtmlInput(cur.identifier, jForm.find("input[name='name']") );
		i.validityCheck = function(id) return data.Project.isValidIdentifier(id) && project.defs.isTilesetIdentifierUnique(id);
		i.validityError = N.invalidIdentifier;
		i.onChange = editor.ge.emit.bind( TilesetDefChanged(cur) );

		// "Import image" button
		var b = jForm.find("#tilesetFile");
		if( !cur.hasAtlasPath() )
			b.text( Lang.t._("Select an image file") );
		else if( !cur.isAtlasLoaded() )
			b.text("ERROR: Couldn't read image data");
		else
			b.text("Replace image");

		b.click( function(ev) {
			dn.electron.Dialogs.open([".png", ".gif", ".jpg", ".jpeg"], Editor.ME.getProjectDir(), function(absPath) {
				var oldRelPath = cur.relPath;
				var relPath = Editor.ME.makeRelativeFilePath( absPath );
				App.LOG.fileOp("Loading atlas: "+absPath);

				if( !cur.importAtlasImage(editor.getProjectDir(), relPath) ) {
					switch dn.Identify.getType( JsTools.readFileBytes(absPath) ) {
						case Unknown:
							N.error("ERROR: I don't think this is an actual image");

						case Png, Jpeg, Gif:
							N.error("ERROR: couldn't read this image file");

						case Bmp:
							N.error("ERROR: unsupported image format");
					}
					return;
				}

				if( oldRelPath!=null )
					editor.watcher.stopWatching( editor.makeAbsoluteFilePath(oldRelPath) );
				editor.watcher.watchTileset(cur);

				project.defs.autoRenameTilesetIdentifier(oldRelPath, cur);
				updateTilesetPreview();
				editor.ge.emit( TilesetDefChanged(cur) );
			});
		});

		var i = Input.linkToHtmlInput( cur.tileGridSize, jForm.find("input[name=tilesetGridSize]") );
		i.linkEvent( TilesetDefChanged(cur) );
		i.setBounds(2, cur.getMaxTileGridSize());

		var i = Input.linkToHtmlInput( cur.spacing, jForm.find("input[name=spacing]") );
		i.linkEvent( TilesetDefChanged(cur) );
		i.setBounds(0, cur.getMaxTileGridSize());

		var i = Input.linkToHtmlInput( cur.padding, jForm.find("input[name=padding]") );
		i.linkEvent( TilesetDefChanged(cur) );
		i.setBounds(0, cur.getMaxTileGridSize());
	}


	function updateList() {
		jList.empty();

		for(td in project.defs.tilesets) {
			var e = new J("<li/>");
			jList.append(e);

			e.append('<span class="name">'+td.identifier+'</span>');
			if( cur==td )
				e.addClass("active");

			e.click( function(_) select(td) );
		}
	}
}
