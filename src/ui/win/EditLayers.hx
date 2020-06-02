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
			updateForm();
			jForm.find("input").first().focus().select();
		});

		selectLayer(client.curLayer.def);
	}

	function selectLayer(ld:LayerDef) {
		curLayer = ld;

		for(k in Type.getEnumConstructs(LayerType))
			jForm.removeClass("type-"+k);
		jForm.addClass("type-"+ld.type);

		var i = form.Input.linkToField( jForm.find("input[name='name']"), ld.name );
		i.onChange = updateLayerList;

		var i = form.Input.linkToField( jForm.find("input[name='gridSize']"), ld.gridSize );
		i.setBounds(1,32);
		i.onChange = function() {
			client.levelRender.invalidate();
		}

		var i = form.Input.linkToField( jForm.find("select[name='type']"), ld.type );
		i.onChange = updateForm;

		switch ld.type {
			case IntGrid:
				var valuesList = jForm.find("ul.intGridValues");
				valuesList.find("li.value").remove();

				// Add value button
				var addButton = valuesList.find("li.add");
				addButton.find("button").off().click( function(ev) {
					ld.intGridValues.push(0xff0000);
					updateForm();
					ev.preventDefault();
				});

				// Existing values
				var idx = 0;
				for(c in ld.intGridValues) {
					var curIdx = idx;
					var e = jForm.find("xml#intGridValue").clone().children().wrapAll("<li/>").parent();
					e.addClass("value");
					e.insertBefore(addButton);
					e.find(".id").html("#"+idx);

					if( idx==ld.intGridValues.length-1 )
						e.addClass("removable");

					// Edit color
					var col = e.find("input[type=color]");
					col.val( C.intToHex(c) );
					col.change( function(ev) {
						ld.intGridValues[curIdx] = C.hexToInt( col.val() );
						updateForm();
					});

					// Remove
					e.find("a.remove").click( function(ev) {
						trace("remove "+curIdx);
						ld.intGridValues.splice(curIdx,1);
						updateForm();
						ev.preventDefault();
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
