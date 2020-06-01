package ui;

class EditLayers extends dn.Process {
	public var client(get,never) : Client; inline function get_client() return Client.ME;
	public var project(get,never) : ProjectData; inline function get_project() return Client.ME.project;
	public var curLevel(get,never) : LevelData; inline function get_curLevel() return Client.ME.curLevel;

	public var curLayer : Null<LayerDef>;

	var jWin : js.jquery.JQuery;
	var jList : js.jquery.JQuery;
	var jForm : js.jquery.JQuery;

	public function new() {
		super(Client.ME);
		Client.ME.loadTemplateInWindow( hxd.Res.tpl.editLayers );
		jWin = new J(".window .content");
		jWin.find("*").off(); // Cleanup events

		jList = jWin.find("select.layers");
		jForm = jWin.find("form");

		// Select layer
		jList.change( function(ev) {
			selectLayer( project.layerDefs[ jList.val() ] );
		});

		// Add layer button
		jWin.find(".addLayer").click( function(_) {
			var ld = project.createLayerDef(IntGrid, "New layer");
			selectLayer(ld);
			jForm.find("input").first().focus().select();
		});

		selectLayer( project.layerDefs[0] );
	}

	function selectLayer(ld:LayerDef) {
		curLayer = ld;

		var i = FormInput.linkToField( jForm.find("input[name='name']"), ld.name );
		i.onChange = updateLayerList;


		var i = FormInput.linkToField( jForm.find("input[name='gridSize']"), ld.gridSize );
		i.setIntBounds(1, 256);
		i.onChange = updateLayerList;

		// var input = jForm.find("input[name='name']");
		// input.val( curLayer.name );
		// input.off().change( function(ev) {
		// 	ld.name = input.val();
		// 	updateLayerList();
		// });

		// var input = jForm.find("input[name='gridSize']");
		// input.off().change( function(_) {
		// 	ld.gridSize = Std.parseInt( input.val() );
		// });
		// input.val( curLayer.gridSize );

		updateLayerList();
	}

	function updateLayerList() {
		jList.empty();

		var idx = 0;
		for(l in project.layerDefs) {
			var e = new J("<option/>");
			jList.append(e);
			e.text(l.name+" ("+l.type+")");
			e.attr("value", idx++);
			if( curLayer==l )
				e.attr("selected","selected");
		}

		client.updateLayerList();
	}
}
