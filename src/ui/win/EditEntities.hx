package ui.win;

class EditEntities extends ui.Window {
	var jList : js.jquery.JQuery;
	var jEntityForm : js.jquery.JQuery;

	public var cur : Null<EntityDef>;

	public function new() {
		super();

		loadTemplate( hxd.Res.tpl.editEntities, "defEditor entityDefs" );
		jList = jWin.find(".mainList ul");

		jEntityForm = jWin.find(".entityDef");

		// Create
		jWin.find(".mainList button.create").click( function(_) {
			var ed = project.createEntityDef();
			select(ed);
			// client.ge.emit(LayerDefChanged);
			jEntityForm.find("input").first().focus().select();
		});

		// Delete
		jWin.find(".mainList button.delete").click( function(ev) {
			if( cur==null ) {
				N.error("No entity selected.");
				return;
			}
			project.removeEntityDef(cur);
			client.ge.emit(EntityDefChanged);
			if( project.entityDefs.length>0 )
				select(project.entityDefs[0]);
			else
				select(null);
		});

		select(project.entityDefs[0]);
	}

	override function onGlobalEvent(e:GlobalEvent) {
		super.onGlobalEvent(e);
		switch e {
			case LayerDefChanged:
			case LayerDefSorted:
			case LayerContentChanged:

			case EntityDefChanged:
				updateEntityForm();
				updateLists();

			case EntityDefSorted:
				updateLists();
		}
	}

	function select(ed:Null<EntityDef>) {
		cur = ed;
		jEntityForm.find("*").off(); // cleanup event listeners

		if( cur==null ) {
			jEntityForm.css("visibility","hidden");
			return;
		}
		jEntityForm.css("visibility","visible");


		// Name
		var i = Input.linkToField( jEntityForm.find("input[name='name']"), ed.name );
		i.validityCheck = project.isEntityNameValid;
		i.onChange = function() {
			client.ge.emit(EntityDefChanged);
		};

		// Dimensions
		var i = Input.linkToField( jEntityForm.find("input[name='width']"), ed.width);
		i.setBounds(1,256);
		i.onChange = client.ge.emit.bind(EntityDefChanged);

		var i = Input.linkToField( jEntityForm.find("input[name='height']"), ed.height);
		i.setBounds(1,256);
		i.onChange = client.ge.emit.bind(EntityDefChanged);

		// 	new ui.Confirm(ev.getThis(), "If you delete this layer, it will be deleted in all levels as well. Are you sure?", function() {
		// 		project.removeLayerDef(ld);
		// 		select(project.layerDefs[0]);
		// 		client.ge.emit(LayerDefChanged);
		// 	});
		// });

		updateLists();
	}


	function updateEntityForm() {
		select(cur);
	}

	function updateFieldForm() {

	}


	function updateLists() {
		jList.empty();

		for(ed in project.entityDefs) {
			var elem = new J("<li/>");
			jList.append(elem);
			elem.append('<span class="name">'+ed.name+'</span>');
			if( cur==ed )
				elem.addClass("active");

			elem.click( function(_) select(ed) );
		}

		// Make layer list sortable
		JsTools.makeSortable(".window .mainList ul", function(from, to) {
			N.notImplemented();
			// var moved = project.sortLayerDef(from,to);
			// select(moved);
			// client.ge.emit(LayerDefSorted);
		});
	}
}
