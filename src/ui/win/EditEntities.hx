package ui.win;

class EditEntities extends ui.Window {
	var jList : js.jquery.JQuery;
	var jForm : js.jquery.JQuery;

	public var cur : Null<EntityDef>;

	public function new() {
		super();

		loadTemplate( hxd.Res.tpl.editEntities, "defEditor entityDefs" );
		jList = jWin.find(".mainList ul");

		jForm = jWin.find("form");
		jForm.submit( function(ev) ev.preventDefault() );

		// Create
		jWin.find(".mainList button.create").click( function(_) {
			var ed = project.createEntityDef();
			select(ed);
			// client.ge.emit(LayerDefChanged);
			jForm.find("input").first().focus().select();
		});

		// Delete
		jWin.find(".mainList button.delete").click( function(ev) {
			if( cur==null ) {
				N.error("No entity selected.");
				return;
			}
			N.notImplemented();
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
				updateForm();
				updateList();

			case EntityDefSorted:
				updateList();
		}
	}

	function select(ed:EntityDef) {
		cur = ed;

		jForm.find("*").off(); // cleanup event listeners

		// Fields
		var i = Input.linkToField( jForm.find("input[name='name']"), ed.name );
		i.unicityCheck = project.isEntityNameValid;
		i.onChange = function() {
			client.ge.emit(EntityDefChanged);
		};

		// 	new ui.Confirm(ev.getThis(), "If you delete this layer, it will be deleted in all levels as well. Are you sure?", function() {
		// 		project.removeLayerDef(ld);
		// 		select(project.layerDefs[0]);
		// 		client.ge.emit(LayerDefChanged);
		// 	});
		// });

		updateList();
	}


	function updateForm() {
		select(cur);
	}


	function updateList() {
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
