package ui.modal.panel;

class WorldPanel extends ui.modal.Panel {
	var levelInstanceForm : ui.LevelInstanceForm;

	public function new() {
		super();

		linkToButton("button.world");
		jMask.hide();
		loadTemplate("worldPanel");

		if( !project.hasFlag(MultiWorlds) )
			jWrapper.find(".worldBar").hide();

		// Create world button
		jWrapper.find(".worldBar button.create").click( (_)->{
			var w = project.createWorld(true);
			editor.selectWorld(w,true);
			Notification.success(L.t._("New world created"), w.identifier);
			editor.ge.emit( WorldCreated(w) );
		});

		// Delete world button
		jWrapper.find(".worldBar button.delete").click( (_)->{
			if( project.worlds.length<=1 ) {
				N.error(L.t._("You can't delete the last world."));
				return;
			}

			new ui.modal.dialog.Confirm(
				Lang.t._("Are you sure you want to delete this world?"),
				true,
				()->{
					new LastChance( L.t._('World ::id:: removed', {id:curWorld.identifier}), project);
					var deleted = curWorld;
					for( other in project.worlds )
						if( other!=curWorld ) {
							editor.selectWorld(other);
							break;
						}
					project.removeWorld(deleted);
					editor.ge.emit( WorldRemoved(deleted) );
					editor.setWorldMode(true);
				}
			);
		});


		// Create level button
		jWrapper.find(".levelBar button.create").click( (_)->{
			var vp = new ui.vp.LevelSpotPicker();
		});

		// Delete level button
		jWrapper.find(".levelBar button.delete").click( (_)->{
			if( curWorld.levels.length<=1 ) {
				N.error(L.t._("You can't delete the last level."));
				return;
			}

			new ui.modal.dialog.Confirm(
				Lang.t._("Are you sure you want to delete this level?"),
				true,
				()->{
					var level = editor.curLevel;
					var closest = curWorld.getClosestLevelFrom(level);
					new LastChance( L.t._('Level ::id:: removed', {id:level.identifier}), project);
					var deleted = level;
					editor.selectLevel( closest );
					for(nl in deleted.getNeighbours())
						editor.invalidateLevelCache(nl);
					curWorld.removeLevel(deleted);
					editor.ge.emit( LevelRemoved(deleted) );
					editor.setWorldMode(true);
				}
			);
		});

		// Duplicate level button
		jWrapper.find(".levelBar button.duplicate").click( (_)->{
			new ui.modal.dialog.Confirm(
				Lang.t._("Create a copy of the current level?"),
				()->{
					var copy = curWorld.duplicateLevel(editor.curLevel);
					editor.selectLevel(copy);
					editor.camera.fit();
					switch curWorld.worldLayout {
						case Free, GridVania:
							copy.worldX += project.defaultGridSize*4;
							copy.worldY += project.defaultGridSize*4;

						case LinearHorizontal:
						case LinearVertical:
					}
					editor.ge.emit( LevelAdded(copy) );
					editor.invalidateLevelCache(copy);
				}
			);
		});

		// Current level instance form
		levelInstanceForm = new ui.LevelInstanceForm(jContent.find(".currentLevelInstance"), true);
		levelInstanceForm.useLevel(editor.curLevel);

		updateWorldForm();

		if( editor.gifMode )
			jModalAndMask.hide();
	}


	override function onDispose() {
		super.onDispose();
		levelInstanceForm.dispose();
		levelInstanceForm = null;
	}

	override function onGlobalEvent(ge:GlobalEvent) {
		super.onGlobalEvent(ge);

		switch ge {
			case WorldSettingsChanged:
				updateWorldForm();

			case WorldSelected(_):
				updateWorldForm();

			case WorldCreated(_), WorldRemoved(_):
				// updateWorldForm();

			case ProjectSelected:
				updateWorldForm();

			case _:
		}

		if( levelInstanceForm!=null && !isClosing() )
			levelInstanceForm.onGlobalEvent(ge);
	}


	function updateWorldForm() {
		jContent.find(".curWorldId").text(curWorld.identifier);

		var jForm = jContent.find(".worldSettings dl.form");
		jForm.find("*").off();

		for(k in ldtk.Json.WorldLayout.getConstructors())
			jForm.removeClass("layout-"+k);
		jForm.addClass("layout-"+curWorld.worldLayout.getName());

		jForm.find("#worldIid").val(curWorld.iid);
		jForm.find(".copyWorldIid").click(_->{
			App.ME.clipboard.copyStr(curWorld.iid);
			N.copied();
		});

		// List all worlds
		var jSelect = jContent.find(".worldBar select");
		jSelect.off();
		jSelect.empty();
		for(w in project.worlds) {
			var jOpt = new J('<option/>');
			jSelect.append(jOpt);
			jOpt.attr("value",w.iid);
			jOpt.text(w.identifier);
		}
		jSelect.val(curWorld.iid);
		jSelect.change( (_)->{
			var iid = jSelect.val();
			var w = project.getWorldIid(iid);
			editor.selectWorld(w);
		});

		// World ID
		var i = Input.linkToHtmlInput(curWorld.identifier, jForm.find("#worldId"));
		i.fixValue = (v)->project.fixUniqueIdStr( v, (id)->project.isWorldIdentifierUnique(id,curWorld) );
		i.linkEvent(WorldSettingsChanged);
		if( !project.hasFlag(MultiWorlds) )
			i.disable();

		// World layout
		var old = curWorld.worldLayout;
		var e = new form.input.EnumSelect(
			jForm.find("[name=worldLayout]"),
			ldtk.Json.WorldLayout,
			()->curWorld.worldLayout,
			(l)->curWorld.worldLayout = l,
			(l)->switch l {
				case Free: L.t._("2D free map - Freely positioned in space");
				case GridVania: L.t._("GridVania - Levels are positioned inside a large world-scale grid");
				case LinearHorizontal: L.t._("Horizontal - One level after the other");
				case LinearVertical: L.t._("Vertical - One level after the other");
			}
		);

		if( project.countAllLevels() > 2 )
			e.customConfirm = (oldV,newV)->L.t._("Changing this will change ALL the level positions! Please make sure you know what you're doing :)");
		e.onBeforeSetter = _->{
			new LastChance(L.t._("World layout changed"), editor.project);
		}
		e.onValueChange = (l)->{
			curWorld.onWorldLayoutChange(old);
			curWorld.reorganizeWorld();
		}
		e.linkEvent( WorldSettingsChanged );

		// Default new level size
		var i = Input.linkToHtmlInput( curWorld.defaultLevelWidth, jForm.find("#defaultLevelWidth"));
		i.linkEvent(WorldSettingsChanged);
		i.setBounds(project.defaultGridSize, 9999);
		i.fixValue = v->curWorld.snapWorldGridX(v,true);
		var i = Input.linkToHtmlInput( curWorld.defaultLevelHeight, jForm.find("#defaultLevelHeight"));
		i.linkEvent(WorldSettingsChanged);
		i.setBounds(project.defaultGridSize, 9999);
		i.fixValue = v->curWorld.snapWorldGridY(v,true);

		// World grid
		var oldW = curWorld.worldGridWidth;
		var i = Input.linkToHtmlInput( curWorld.worldGridWidth, jForm.find("[name=worldGridWidth]"));
		i.linkEvent(WorldSettingsChanged);
		i.onChange = ()->curWorld.onWorldGridChange(oldW, curWorld.worldGridHeight);

		var oldH = curWorld.worldGridHeight;
		var i = Input.linkToHtmlInput( curWorld.worldGridHeight, jForm.find("[name=worldGridHeight]"));
		i.linkEvent(WorldSettingsChanged);
		i.onChange = ()->curWorld.onWorldGridChange(curWorld.worldGridWidth, oldH);

		JsTools.parseComponents(jForm);
		checkBackup();
	}


	override function onClose() {
		super.onClose();
		editor.setWorldMode(false);
	}

	override function update() {
		super.update();
		if( !editor.worldMode )
			close();
	}
}