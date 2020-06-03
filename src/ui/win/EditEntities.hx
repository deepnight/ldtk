package ui.win;

class EditEntities extends ui.Window {
	var jList : js.jquery.JQuery;
	var jEntityForm : js.jquery.JQuery;
	var jFieldsForm : js.jquery.JQuery;

	public var curEntity : Null<EntityDef>;

	public function new() {
		super();

		loadTemplate( hxd.Res.tpl.editEntities, "defEditor entityDefs" );
		jList = jWin.find(".mainList ul");

		jEntityForm = jWin.find("ul.form.entityDef");
		jFieldsForm = jWin.find(".fields ul.form");

		// Create
		jWin.find(".mainList button.create").click( function(_) {
			var ed = project.createEntityDef();
			selectEntity(ed);
			// client.ge.emit(LayerDefChanged);
			jEntityForm.find("input").first().focus().select();
		});

		// Delete
		jWin.find(".mainList button.delete").click( function(ev) {
			if( curEntity==null ) {
				N.error("No entity selected.");
				return;
			}
			project.removeEntityDef(curEntity);
			client.ge.emit(EntityDefChanged);
			if( project.entityDefs.length>0 )
				selectEntity(project.entityDefs[0]);
			else
				selectEntity(null);
		});

		selectEntity(project.entityDefs[0]);
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

	function selectEntity(ed:Null<EntityDef>) {
		curEntity = ed;
		jEntityForm.find("*").off(); // cleanup event listeners

		if( curEntity==null ) {
			new J(".formsWrapper").css("visibility","hidden");
			return;
		}
		else
			new J(".formsWrapper").css("visibility","visible");


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

		// Color
		var col = jEntityForm.find("input[name=color]");
		col.val( C.intToHex(ed.color) );
		col.change( function(ev) {
			ed.color = C.hexToInt( col.val() );
			client.ge.emit(EntityDefChanged);
			updateEntityForm();
		});

		// 	new ui.Confirm(ev.getThis(), "If you delete this layer, it will be deleted in all levels as well. Are you sure?", function() {
		// 		project.removeLayerDef(ld);
		// 		select(project.layerDefs[0]);
		// 		client.ge.emit(LayerDefChanged);
		// 	});
		// });

		updateLists();
	}


	function updateEntityForm() {
		selectEntity(curEntity);
	}

	function updateFieldForm() {
	}


	function updateLists() {
		jList.empty();

		for(ed in project.entityDefs) {
			var elem = new J("<li/>");
			jList.append(elem);
			elem.append('<span class="name">'+ed.name+'</span>');
			if( curEntity==ed )
				elem.addClass("active");

			elem.click( function(_) selectEntity(ed) );
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
