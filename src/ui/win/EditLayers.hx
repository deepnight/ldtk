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
			var ld = project.createLayerDef(IntGrid, "New layer");
			selectLayer(ld);
			client.onLayerDefChange();
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
		var i = form.Input.linkToField( jForm.find("input[name='name']"), ld.name );
		i.onChange = function() {
			client.onLayerDefChange();
			updateLayerList();
		};

		var i = form.Input.linkToField( jForm.find("select[name='type']"), ld.type );
		i.onChange = function() {
			client.onLayerDefChange();
			updateForm();
		};

		var i = form.Input.linkToField( jForm.find("input[name='gridSize']"), ld.gridSize );
		i.setBounds(1,32);
		i.onChange = function() {
			client.onLayerDefChange();
		}

		var i = form.Input.linkToField( jForm.find("input[name='displayOpacity']"), ld.displayOpacity );
		i.displayAsPct = true;
		i.setBounds(0.1, 1);
		i.onChange = function() {
			client.onLayerDefChange();
		}

		// Delete layer button
		jForm.find(".deleteLayer").click( function(_) {
			if( project.layerDefs.length==1 )
				return;

			project.removeLayerDef(ld);
			selectLayer(project.layerDefs[0]);
			client.onLayerDefChange();
		});


		// Layer-type specific inits
		switch ld.type {

			case IntGrid:
				var valuesList = jForm.find("ul.intGridValues");
				valuesList.find("li.value").remove();

				// Add intGrid value button
				var addButton = valuesList.find("li.add");
				addButton.find("button").off().click( function(ev) {
					ld.intGridValues.push({
						name: "Unknown",
						color: 0xff0000,
					});
					client.onLayerDefChange();
					updateForm();
					// jForm.find("li.value:last input[type=color]").click(); // TODO need proper user-triggered event
				});

				// Existing values
				var idx = 0;
				for(val in ld.intGridValues) {
					var curIdx = idx;
					var e = jForm.find("xml#intGridValue").clone().children().wrapAll("<li/>").parent();
					e.addClass("value");
					e.insertBefore(addButton);
					e.find(".id").html("#"+idx);

					var nameInput = e.find("input.name");
					nameInput.val(val.name);
					nameInput.change( function(_) {
						val.name = nameInput.val();
					});

					if( ld.intGridValues.length>1 && idx==ld.intGridValues.length-1 )
						e.addClass("removable");

					// Edit color
					var col = e.find("input[type=color]");
					col.val( C.intToHex(val.color) );
					col.change( function(ev) {
						ld.intGridValues[curIdx].color = C.hexToInt( col.val() );
						client.onLayerDefChange();
						updateForm();
					});

					// Remove
					e.find("a.remove").click( function(ev) {
						ld.intGridValues.splice(curIdx,1);
						client.onLayerDefChange();
						updateForm();
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
