package ui.modal.panel;

class EditLayerDefs extends ui.modal.Panel {
	var jList : js.jquery.JQuery;
	var jForm : js.jquery.JQuery;
	public var cur : Null<LayerDef>;

	public function new() {
		super();

		loadTemplate( "editLayerDefs", "defEditor layerDefs" );
		jList = jModalAndMask.find(".mainList ul");
		jForm = jModalAndMask.find("ul.form");
		linkToButton("button.editLayers");

		// Create layer
		jModalAndMask.find(".mainList button.create").click( function(ev) {
			function _create(type:LayerType) {
				var ld = project.defs.createLayerDef(type);
				select(ld);
				client.ge.emit(LayerDefChanged);
				jForm.find("input").first().focus().select();
			}

			// Type picker
			var w = new ui.modal.Dialog(ev.getThis(),"layerTypes");
			for(k in LayerType.getConstructors()) {
				var type = LayerType.createByName(k);
				var b = new J("<button/>");
				b.appendTo( w.jContent );
				JsTools.createLayerTypeIcon(type, b);
				b.click( function(_) {
					_create(type);
					w.close();
				});
			}

		});

		// Delete layer
		jModalAndMask.find(".mainList button.delete").click( function(ev) {
			if( cur==null ) {
				N.error("No layer selected.");
				return;
			}
			new ui.modal.dialog.Confirm(ev.getThis(), "If you delete this layer, it will be deleted in all levels as well. Are you sure?", function() {
				project.defs.removeLayerDef(cur);
				select(project.defs.layers[0]);
				client.ge.emit(LayerDefChanged);
			});
		});


		select(client.curLayerDef);
	}

	override function onGlobalEvent(e:GlobalEvent) {
		super.onGlobalEvent(e);
		switch e {
			case ProjectChanged: close();

			case LayerDefChanged:
				updateForm();
				updateList();

			case TilesetDefChanged:
				updateForm();
				updateTilesetPreview();

			case LayerDefSorted:
				updateList();

			case LayerInstanceChanged:

			case EntityDefChanged, EntityDefSorted, EntityFieldChanged, EntityFieldSorted:
		}
	}

	function select(ld:LayerDef) {
		cur = ld;
		jForm.find("*").off(); // cleanup event listeners

		if( cur==null ) {
			jForm.hide();
			return;
		}

		jForm.show();

		// Set form class
		for(k in Type.getEnumConstructs(LayerType))
			jForm.removeClass("type-"+k);
		jForm.addClass("type-"+ld.type);

		jForm.find("span.type").text( Lang.getLayerType(ld.type) );
		jForm.find("span.typeIcon").empty().append( JsTools.createLayerTypeIcon(ld.type,false) );


		// Fields
		var i = Input.linkToHtmlInput( ld.name, jForm.find("input[name='name']") );
		i.validityCheck = project.defs.isLayerNameValid;
		i.onChange = client.ge.emit.bind(LayerDefChanged);

		// var i = Input.linkToHtmlInput( ld.type, jForm.find("select[name='type']") );
		// i.onChange = client.ge.emit.bind(LayerDefChanged);

		var i = Input.linkToHtmlInput( ld.gridSize, jForm.find("input[name='gridSize']") );
		i.setBounds(1,Const.MAX_GRID_SIZE);
		i.onChange = client.ge.emit.bind(LayerDefChanged);

		var i = Input.linkToHtmlInput( ld.displayOpacity, jForm.find("input[name='displayOpacity']") );
		i.displayAsPct = true;
		i.setBounds(0.1, 1);
		i.onChange = client.ge.emit.bind(LayerDefChanged);

		// Layer-type specific inits
		switch ld.type {

			case IntGrid:
				var valuesList = jForm.find("ul.intGridValues");
				valuesList.find("li.value").remove();

				// Add intGrid value button
				var addButton = valuesList.find("li.add");
				addButton.find("button").off().click( function(ev) {
					ld.addIntGridValue(0xff0000);
					client.ge.emit(LayerDefChanged);
					updateForm();
				});

				// Existing values
				var idx = 0;
				for( intGridVal in ld.getAllIntGridValues() ) {
					var curIdx = idx;
					var e = jForm.find("xml#intGridValue").clone().children().wrapAll("<li/>").parent();
					e.addClass("value");
					e.insertBefore(addButton);
					e.find(".id").html("#"+idx);

					// Edit value name
					var i = new form.input.StringInput(
						e.find("input.name"),
						function() return intGridVal.name,
						function(v) intGridVal.name = v
					);
					i.validityCheck = ld.isIntGridValueNameValid;
					i.validityError = N.error.bind("This value name is already used.");
					i.onChange = client.ge.emit.bind(LayerDefChanged);

					if( ld.countIntGridValues()>1 && idx==ld.countIntGridValues()-1 )
						e.addClass("removable");

					// Edit color
					var col = e.find("input[type=color]");
					col.val( C.intToHex(intGridVal.color) );
					col.change( function(ev) {
						ld.getIntGridValueDef(curIdx).color = C.hexToInt( col.val() );
						client.ge.emit(LayerDefChanged);
						updateForm();
					});

					// Remove
					e.find("a.remove").click( function(ev) {
						function run() {
							ld.getAllIntGridValues().splice(curIdx,1);
							client.ge.emit(LayerDefChanged);
							updateForm();
						}
						if( ld.isIntGridValueUsedInProject(project, curIdx) ) {
							new ui.modal.dialog.Confirm(e.find("a.remove"), L.t._("This value is used in some levels: removing it will also remove the value from all these levels. Are you sure?"), run);
							return;
						}
						else
							run();
					});
					idx++;
				}


			case Entities:

			case Tiles:
				var uploader = jForm.find("input[name=tilesetFile]");
				uploader.attr("nwworkingdir",client.getCwd()+"\\tilesetTestImages");
				uploader.change( function(ev) {
					var path = uploader.val();
					var buffer = js.node.Fs.readFileSync(path);
					var bytes = buffer.hxToBytes();
					if( !ld.tilesetDef.importImage(bytes) ) {
						switch dn.Identify.getType(bytes) {
							case Unknown:
							case Png, Gif:
								N.error("Couldn't read this image: maybe the data is corrupted or the format special?");

							case Jpeg:
								N.error("Sorry, JPEG is not yet supported, please use PNG instead.");

							case Bmp:
								N.error("Sorry, BMP is not supported, please use PNG instead.");
						}
						return;
					}
					updateTilesetPreview();
				});

				var i = Input.linkToHtmlInput( ld.tilesetDef.tileGridSize, jForm.find("input[name=tilesetGridSize]") );
				i.linkEvent(LayerDefChanged);
				i.setBounds(2, 512); // TODO cap to texture width

				var i = Input.linkToHtmlInput( ld.tilesetDef.tileGridSpacing, jForm.find("input[name=tilesetGridSpacing]") );
				i.linkEvent(LayerDefChanged);
				i.setBounds(0, 512);
		}

		updateList();
		updateTilesetPreview();
	}

	function updateTilesetPreview() {
		if( cur.type!=Tiles || cur.tilesetDef.isEmpty() )
			return;

		// Main tileset view
		cur.tilesetDef.drawAtlasToCanvas( jForm.find(".tileset canvas.fullPreview") );

		// Demo tiles
		var padding = 8;
		var jDemo = jForm.find(".tileset canvas.demo");
		jDemo.attr("width", cur.tilesetDef.tileGridSize*6 + padding*5);
		jDemo.attr("height", cur.tilesetDef.tileGridSize);
		var cnv = Std.downcast( jDemo.get(0), js.html.CanvasElement );
		cnv.getContext2d().clearRect(0,0, cnv.width, cnv.height);

		var idx = 0;
		function renderDemoTile(tcx,tcy) {
			cur.tilesetDef.drawTileToCanvas(jDemo, cur.tilesetDef.coordId(tcx,tcy), (idx++)*(cur.tilesetDef.tileGridSize+padding), 0);
		}
		renderDemoTile(0,0);
		renderDemoTile(1,0);
		renderDemoTile(2,0);
		renderDemoTile(0,1);
		renderDemoTile(0,2);
	}


	function updateForm() {
		select(cur);
	}


	function updateList() {
		jList.empty();

		for(ld in project.defs.layers) {
			var e = new J("<li/>");
			jList.append(e);

			var icon = new J('<div class="icon"/>');
			e.append(icon);
			switch ld.type {
				case IntGrid: icon.addClass("intGrid");
				case Entities: icon.addClass("entity");
				case Tiles: icon.addClass("tile");
			}

			e.append('<span class="name">'+ld.name+'</span>');
			if( cur==ld )
				e.addClass("active");

			e.click( function(_) select(ld) );
		}

		// Make layer list sortable
		JsTools.makeSortable(".window .mainList ul", function(from, to) {
			var moved = project.defs.sortLayerDef(from,to);
			select(moved);
			client.ge.emit(LayerDefSorted);
		});
	}
}
