package ui.win;

class EditLayers extends ui.Window {
	var jList : js.jquery.JQuery;
	var jForm : js.jquery.JQuery;
	public var curLayer : Null<LayerDef>;

	var pouet : Float = 5;

	public function new() {
		super();

		loadTemplate( hxd.Res.tpl.editLayers );
		jList = jWin.find("ul.layers");
		jForm = jWin.find("form");

		// Create layer
		jWin.find(".addLayer").click( function(_) {
			var ld = project.createLayerDef(IntGrid, "New layer");
			selectLayer(ld);
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

		var i = form.Input.linkToField( jForm.find("select[name='type']"), ld.type );
		i.onChange = selectLayer.bind(ld);

		updateLayerList();
	}


	function updateLayerList() {
		jList.empty();

		for(l in project.layerDefs) {
			var e = new J("<li/>");
			jList.append(e);
			e.text(l.name+" ("+l.type+")");
			if( curLayer==l )
				e.addClass("selected");

			e.click( function(_) selectLayer(l) );
		}

		client.updateLayerList();
	}
}
