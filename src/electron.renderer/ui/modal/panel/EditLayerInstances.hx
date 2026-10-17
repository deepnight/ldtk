package ui.modal.panel;

class EditLayerInstances extends ui.modal.Panel {
	var jList : js.jquery.JQuery;
	var jForms : js.jquery.JQuery;
	var jFormsWrapper : js.jquery.JQuery;
	var search : QuickSearch;

	var level : data.Level;

	public var cur : Null<data.inst.LayerInstance>;

	public function new() {
		super();

		loadTemplate("editLayerInstances");
		linkToButton("button.editLayerInstances");

		level = editor.curLevel;

		jList = jModalAndMask.find(".mainList ul");
		jForms = jModalAndMask.find("dl.form");
		jFormsWrapper = jModalAndMask.find(".rightColumn");

		// Create layer button
		jModalAndMask.find(".mainList button.create").click( (ev)->{
			new ui.modal.dialog.SelectLayerDef( ev.getThis(), createLayer );
		});

		// Create quick search
		search = new ui.QuickSearch( jContent.find(".mainList ul") );
		search.jWrapper.appendTo( jContent.find(".search") );

		select(editor.curLayerInstance);
	}



	function createLayer(layerDef: data.def.LayerDef) {
		var li = level.createLayerInstance( layerDef );
		li.level.sortLayerInstances( li.level.layerInstances.length-1, 0 );
		editor.ge.emit( LayerInstanceAdded(li) );
		editor.curLevelTimeline.saveFullLevelState();

		select(li);
		jForms.find("input").first().focus().select();
	}

	function deleteLayer(li:data.inst.LayerInstance) {
		level.removeLayerInstance(li);
		editor.ge.emit( LayerInstanceRemoved(li) );

		if( level.layerInstances.length>0 )
			select(level.layerInstances[0]);
		else
			select(null);
	}

	function moveLayer(fromIndex:Int, toIndex:Int) {
		var moved = level.sortLayerInstances(fromIndex, toIndex);
		editor.ge.emit( LayerInstancesSorted(level) );
		editor.curLevelTimeline.saveFullLevelState();

		select(moved);
	}



	override function onGlobalEvent(e:GlobalEvent) {
		super.onGlobalEvent(e);
		switch e {
			case WorldMode(true), ProjectSettingsChanged, ProjectSelected, LevelSelected(_):
				close();

			case LevelRemoved(l):
				if( l==level )
					close();

			case LayerInstancesRestoredFromHistory(_):
				updateForm();
				updateList();

			case LayerDefAdded, LayerDefRemoved(_), LayerDefChanged(_, _), LayerInstanceChangedGlobally(_):
				updateList();
				updateForm();

			case TilesetDefChanged(_):
				updateForm();

			case LayerInstanceVisiblityChanged(li):
				if( li==cur )
					updateForm();

			case LayerInstancesSorted(l):
				if( l==level )
					updateList();

			case LayerInstanceAdded(li):
				if( li.level==level )
					updateList();
			
			case LayerInstanceRemoved(li):
				if( li.level==level )
					updateList();

				if( cur==li )
					select(null);

			case _:
		}
	}

	public function select(li:Null<data.inst.LayerInstance>) {
		cur = li;
		updateForm();
		updateList();
	}

	function updateForm() {
		Tip.clear();
		jForms.find("*").off(); // cleanup event listeners
		jForms.find(".tmp").remove();

		if( cur==null ) {
			jContent.find(".none").show();
			jFormsWrapper.hide();
			return;
		}
		jContent.find(".none").hide();


		// Lost layer instance
		if( level.getLayerInstance(cur.iid)==null ) {
			if( level.layerInstances.length>0 )
				select( level.layerInstances[0] );
			else
				select( null );
			return;
		}

		editor.selectLayerInstance(cur);

		jFormsWrapper.show();

		// Set up layer type info
		for(k in Type.getEnumConstructs(ldtk.Json.LayerType))
			jFormsWrapper.removeClass("type-"+k);
		jFormsWrapper.removeClass("type-IntGridAutoLayer");
		jFormsWrapper.addClass("type-"+cur.def.type);
		if( cur.def.type==IntGrid && cur.def.isAutoLayer() )
			jFormsWrapper.addClass("type-IntGridAutoLayer");

		jContent.find("#typeSpecificTitle").text( cur.def.type.getName() );


		// Definition
		jForms.find("#layerDefName").text( cur.def.identifier );

		var jButton = jForms.find("button.editLayerDef");
		jButton.click( (_)->{
			close();
			App.ME.executeAppCommand(C_OpenLayerDefPanel);
		});


		// Identifier
		var i = Input.linkToHtmlInput( cur.identifier, jForms.find("input[name='name']") );
		i.fixValue = (v)->project.fixUniqueIdStr(v, (id)->level.isLayerNameUnique(id,cur));
		i.onChange = editor.ge.emit.bind( LayerInstanceChangedGlobally(cur) );


		// Visibility
		var i = Input.linkToHtmlInput( cur.visible, jForms.find("input[name='visible']") );
		i.onChange = ()->{
			editor.levelRender.invalidateLayer(cur);
			editor.ge.emit(LayerInstanceVisiblityChanged(cur));
		}


		// Layer type specific configuration
		switch (cur.def.type) {

			case Entities:
				// Move entities
				jForms.find(".moveEntities").click( _->{
					new ui.modal.dialog.MoveEntitiesBetweenLayers(cur);
				});

			default:

		}


		JsTools.parseComponents(jForms);
		checkBackup();
	}


	function updateList() {
		Tip.clear();
		jList.empty();

		ContextMenu.attachTo(jList, false, [
			{
				label: L._Paste(),
				cb: ()->{
					var copy = level.pasteLayerInstance(App.ME.clipboard);
					if( copy!=null ) {
						editor.ge.emit( LayerInstanceAdded(copy) );
						select(copy);
					}
				},
				enable: ()->App.ME.clipboard.is(CLayerInstance),
			},
		]);

		for(li in level.layerInstances) {
			var jLi = new J("<li/>");
			jLi.appendTo(jList);

			if( li.def.hideInList )
				jLi.addClass("hidden");
			jLi.addClass( Std.string(li.def.type) );

			jLi.append( JsTools.createLayerTypeIcon2(li.def.type) );
			JsTools.applyListCustomColor(jLi, li.def.uiColor, cur==li);

			var jNameSpan = new J('<span class="name"/>');
			jNameSpan.text(li.identifier);
			jLi.append(jNameSpan);

			if( cur==li )
				jLi.addClass("active");

			ContextMenu.attachTo_new(jLi, (ctx:ContextMenu)->{
				ctx.addElement( Ctx_CopyPaster({
					elementName: "layer",
					clipType: CLayerInstance,
					copy: ()->App.ME.clipboard.copyData(CLayerInstance, li.toJson()),
					cut: ()->{
						App.ME.clipboard.copyData(CLayerInstance, li.toJson());
						deleteLayer(li);
					},
					paste: ()->{
						var copy = level.pasteLayerInstance(App.ME.clipboard, li);
						if( copy!=null ) {
							editor.ge.emit( LayerInstanceAdded(li) );
							select(copy);
						}
					},
					duplicate: ()->{
						var copy = level.duplicateLayerInstance(li);
						editor.ge.emit( LayerInstanceAdded(li) );
						select(copy);
					},
					delete: ()->deleteLayer(li),
				}) );
			});

			jLi.click( _->select(li) );
		}

		// Make layer list sortable
		JsTools.makeSortable(jList, (ev)->{
			moveLayer(ev.oldIndex, ev.newIndex);
		});

		checkBackup();
		search.run();
	}
}
