package ui.modal.panel;

class EditTilesetDefs extends ui.modal.Panel {
	var jList : js.jquery.JQuery;
	var jForm : js.jquery.JQuery;
	public var cur : Null<led.def.TilesetDef>;

	public function new(?selectedDef:led.def.TilesetDef) {
		super();

		loadTemplate( "editTilesetDefs", "defEditor tilesetDefs" );
		jList = jModalAndMask.find(".mainList ul");
		jForm = jModalAndMask.find("ul.form");
		linkToButton("button.editTilesets");

		// Create tileset
		jModalAndMask.find(".mainList button.create").click( function(ev) {
			var td = project.defs.createTilesetDef();
			select(td);
			client.ge.emit(TilesetDefChanged);
			jForm.find("input").first().focus().select();
		});

		// Delete tileset
		jModalAndMask.find(".mainList button.delete").click( function(ev) {
			if( cur==null ) {
				N.error("No tileset selected.");
				return;
			}
			new ui.modal.dialog.Confirm(ev.getThis(), "If you delete this tileset, it will be deleted in all levels and corresponding layers as well. Are you sure?", function() {
				N.notImplemented();
				// project.defs.removeLayerDef(cur);
				// select(project.defs.layers[0]);
				// client.ge.emit(TilesetDefChanged);
			});
		});


		select(selectedDef!=null ? selectedDef : project.defs.tilesets[0]);
	}

	override function onGlobalEvent(e:GlobalEvent) {
		super.onGlobalEvent(e);
		switch e {
			case ProjectSettingsChanged, ProjectSelected, LevelSettingsChanged, LevelSelected:
				close();

			case LayerInstanceRestoredFromHistory:
				updateList();
				updateForm();
				updateTilesetPreview();

			case TilesetDefChanged:
				updateList();
				updateForm();
				updateTilesetPreview();

			case _:
		}
	}

	function select(td:led.def.TilesetDef) {
		cur = td;
		updateList();
		updateForm();
		updateTilesetPreview();
	}



	function updateTilesetPreview() {
		if( cur==null )
			return;

		// Main tileset view
		var jFull = jForm.find(".tileset canvas.fullPreview");
		if( cur==null || !cur.isAtlasValid() ) {
			var cnv = Std.downcast( jFull.get(0), js.html.CanvasElement );
			cnv.getContext2d().clearRect(0,0, cnv.width, cnv.height);
		}
		else
			cur.drawAtlasToCanvas( jFull );

		// Demo tiles
		var padding = 8;
		var jDemo = jForm.find(".tileset canvas.demo");
		var cnv = Std.downcast( jDemo.get(0), js.html.CanvasElement );
		cnv.getContext2d().clearRect(0,0, cnv.width, cnv.height);

		if( cur!=null && cur.isAtlasValid() ) {
			jDemo.attr("width", cur.tileGridSize*6 + padding*5);
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
		if( cur.relPath!=null ) {
			jPath.empty();
			var parts = cur.relPath.split("/").map( function(p) return '<span>$p</span>' );
			jPath.append( parts.join('<span class="slash">/</span>') );
		}
		else
			jPath.text("-- No file --");
		jPath.off().click( function(ev) {
			if( cur.relPath!=null )
				JsTools.exploreToFile( client.makeFullFilePath(cur.relPath) );
		});

		// Fields
		var i = Input.linkToHtmlInput(cur.identifier, jForm.find("input[name='name']") );
		i.validityCheck = function(id) return led.Project.isValidIdentifier(id) && project.defs.isTilesetIdentifierUnique(id);
		i.validityError = N.invalidIdentifier;
		i.onChange = client.ge.emit.bind(TilesetDefChanged);

		// "Import image" button
		var b = jForm.find("#tilesetFile");
		if( cur.relPath==null )
			b.text( Lang.t._("Select an image file") );
		else if( !cur.isAtlasValid() )
			b.text("ERROR: Couldn't read image data");
		else
			b.text("Replace image");

		b.click( function(ev) {
			JsTools.loadDialog(["jpg","jpeg","gif","png"], function(absPath) {
				var oldPath = cur.relPath;
				var relPath = client.makeRelativeFilePath( absPath );

				if( !cur.loadAtlasImage(relPath) ) {
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

				project.defs.autoRenameTilesetIdentifier(oldPath, cur);
				updateTilesetPreview();
				client.ge.emit(TilesetDefChanged);
			});
		});

		var i = Input.linkToHtmlInput( cur.tileGridSize, jForm.find("input[name=tilesetGridSize]") );
		i.linkEvent(TilesetDefChanged);
		i.setBounds(2, 512); // TODO cap to texture width

		var i = Input.linkToHtmlInput( cur.tileGridSpacing, jForm.find("input[name=tilesetGridSpacing]") );
		i.linkEvent(TilesetDefChanged);
		i.setBounds(0, 512);
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

		// Make layer list sortable
		// JsTools.makeSortable(".window .mainList ul", function(from, to) {
			// var moved = project.defs.sortLayerDef(from,to);
			// select(moved);
		// 	client.ge.emit(LayerDefSorted);
		// });
	}
}
