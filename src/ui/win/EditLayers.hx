package ui.win;

class EditLayers extends ui.Window {
	var jList : js.jquery.JQuery;
	var jForm : js.jquery.JQuery;
	public var curLayer : Null<LayerDef>;

	var pouet : Float = 5;

	public function new() {
		super();

		loadTemplate( hxd.Res.tpl.editLayers );
		jList = jWin.find(".layersList ul");
		jForm = jWin.find("form");

		// Create layer
		jWin.find(".addLayer").click( function(_) {
			var ld = project.createLayerDef(IntGrid);
			selectLayer(ld);
			client.ge.emit(LayerDefChanged);
			jForm.find("input").first().focus().select();
		});

		selectLayer(client.curLayerContent.def);
	}

	function selectLayer(ld:LayerDef) {
		curLayer = ld;

		jForm.find("*").off(); // cleanup event listeners

		// Set form class
		for(k in Type.getEnumConstructs(LayerType))
			jForm.removeClass("type-"+k);
		jForm.addClass("type-"+ld.type);

		// Fields
		var i = Input.linkToField( jForm.find("input[name='name']"), ld.name );
		i.unicityCheck = project.isLayerNameUnique;
		i.onChange = function() {
			client.ge.emit(LayerDefChanged);
			updateLayerList();
		};

		var i = Input.linkToField( jForm.find("select[name='type']"), ld.type );
		i.onChange = function() {
			client.ge.emit(LayerDefChanged);
			updateForm();
		};

		var i = Input.linkToField( jForm.find("input[name='gridSize']"), ld.gridSize );
		i.setBounds(1,32);
		i.onChange = function() {
			client.ge.emit(LayerDefChanged);
		}

		var i = Input.linkToField( jForm.find("input[name='displayOpacity']"), ld.displayOpacity );
		i.displayAsPct = true;
		i.setBounds(0.1, 1);
		i.onChange = function() {
			client.ge.emit(LayerDefChanged);
		}

		// Delete layer button
		jForm.find(".deleteLayer").click( function(ev) {
			if( project.layerDefs.length==1 ) {
				N.error("Cannot delete the last layer.");
				return;
			}

			new ui.Confirm(ev.getThis(), "If you delete this layer, it will be deleted in all levels as well. Are you sure?", function() {
				project.removeLayerDef(ld);
				selectLayer(project.layerDefs[0]);
				client.ge.emit(LayerDefChanged);
			});
		});


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
				for( val in ld.getAllIntGridValues() ) {
					var curIdx = idx;
					var e = jForm.find("xml#intGridValue").clone().children().wrapAll("<li/>").parent();
					e.addClass("value");
					e.insertBefore(addButton);
					e.find(".id").html("#"+idx);

					// Edit value name
					var i = Input.linkToField(e.find("input.name"), val.name);
					i.unicityCheck = ld.isIntGridValueNameUnique;
					i.unicityError = N.error.bind("This value name is already used.");
					i.onChange = client.ge.emit.bind(LayerDefChanged);

					if( ld.countIntGridValues()>1 && idx==ld.countIntGridValues()-1 )
						e.addClass("removable");

					// Edit color
					var col = e.find("input[type=color]");
					col.val( C.intToHex(val.color) );
					col.change( function(ev) {
						ld.getIntGridValue(curIdx).color = C.hexToInt( col.val() );
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
							new ui.Confirm(e.find("a.remove"), L.t._("This value is used in some levels: removing it will also remove the value from all these levels. Are you sure?"), run);
							return;
						}
						else
							run();
					});
					idx++;
				}


			case Entities:
				// TODO
		}

		updateLayerList();
	}


	function updateForm() {
		selectLayer(curLayer);
	}


	function updateLayerList() {
		jList.empty();

		for(l in project.layerDefs) {
			var e = new J("<li/>");
			jList.append(e);
			e.append('<span class="name">'+l.name+'</span>');
			if( curLayer==l )
				e.addClass("active");

			e.click( function(_) selectLayer(l) );
		}

		client.updateLayerList();
	}
}
