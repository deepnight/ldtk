package ui;

class EditLayers extends dn.Process {
	public var client(get,never) : Client; inline function get_client() return Client.ME;
	public var project(get,never) : ProjectData; inline function get_project() return Client.ME.project;
	public var curLevel(get,never) : LevelData; inline function get_curLevel() return Client.ME.curLevel;

	public var curLayer : Null<LayerDef>;

	var jWin : js.jquery.JQuery;
	var jList : js.jquery.JQuery;
	var jForm : js.jquery.JQuery;

	var pouet : Float = 5;

	public function new() {
		super(Client.ME);
		Client.ME.loadTemplateInWindow( hxd.Res.tpl.editLayers );
		jWin = new J(".window .content");
		jWin.find("*").off(); // Cleanup events

		jList = jWin.find("ul.layers");
		jForm = jWin.find("form");

		// Create layer
		jWin.find(".addLayer").click( function(_) {
			var ld = project.createLayerDef(IntGrid, "New layer");
			selectLayer(ld);
			jForm.find("input").first().focus().select();
		});

		selectLayer( project.layerDefs[0] );
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
