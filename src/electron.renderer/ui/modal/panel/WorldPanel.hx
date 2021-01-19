package ui.modal.panel;

class WorldPanel extends ui.modal.Panel {
	var level: data.Level;

	public function new() {
		super();

		jMask.hide();
		level = editor.curLevel;
		loadTemplate("worldPanel");

		// Delete button
		jContent.find("button.delete").click( (_)->{
			if( project.levels.length<=1 ) {
				N.error( L.t._("You can't remove last level.") );
				return;
			}

			new ui.modal.dialog.Confirm(
				Lang.t._("Are you sure you want to delete this level?"),
				true,
				()->{
					var closest = project.getClosestLevelFrom(level);
					new LastChance('Level ${level.identifier} removed', project);
					var l = level;
					project.removeLevel(level);
					editor.ge.emit( LevelRemoved(l) );
					editor.selectLevel( closest );
					editor.camera.scrollToLevel(editor.curLevel);
				}
			);
		});

		// Create button
		jContent.find("button.create").click( (ev:js.jquery.Event)->{
			if( editor.worldTool.isInAddMode() ) {
				editor.worldTool.stopAddMode();
				ev.getThis().removeClass("running");
			}
			else {
				editor.worldTool.startAddMode();
				ev.getThis().addClass("running");
				N.msg(L.t._("Select a spot on the world map..."));
			}
		});

		// Duplicate button
		jContent.find("button.duplicate").click( (_)->{
			var copy = project.duplicateLevel(level);
			editor.selectLevel(copy);
			switch project.worldLayout {
				case Free, GridVania:
					copy.worldX += project.defaultGridSize*4;
					copy.worldY += project.defaultGridSize*4;

				case LinearHorizontal:
				case LinearVertical:
			}
			editor.ge.emit( LevelAdded(copy) );
		});

		jContent.find("button.worldSettings").click( (_)->{
			jContent.find("#worldForm").slideToggle(100);
		});

		updateWorldForm();
		updateLevelForm();
	}

	function useLevel(l:data.Level) {
		level = l;
		updateLevelForm();
	}

	override function onGlobalEvent(ge:GlobalEvent) {
		super.onGlobalEvent(ge);

		switch ge {
			case WorldSettingsChanged:
				if( level==null || project.getLevel(level.uid)==null )
					destroy();
				else {
					updateWorldForm();
					updateLevelForm();
				}

			case ProjectSelected:
				updateWorldForm();
				useLevel(editor.curLevel);

			case LevelRestoredFromHistory(l):
				if( l.uid==level.uid )
					useLevel(l);

			case LevelSettingsChanged(l):
				if( l==level )
					updateLevelForm();

			case LevelAdded(level):

			case LevelSelected(l):
				useLevel(l);

			case LevelRemoved(l):

			case WorldLevelMoved:
				updateLevelForm();

			case ViewportChanged :

			case _:
		}
	}

	override function onClose() {
		super.onClose();
		editor.setWorldMode(false);
	}

	function onFieldChange() {
		editor.ge.emit( LevelSettingsChanged(level) );
	}

	function onLevelResized(newPxWid:Int,newPxHei:Int) {
		new LastChance( Lang.t._("Level resized"), project );
		curLevel.applyNewBounds(0, 0, newPxWid, newPxHei);
		onFieldChange();
		new J("ul#levelForm *:focus").blur();
	}


	function updateWorldForm() {
		if( level==null ) {
			close();
			return;
		}

		var jForm = jContent.find("#worldForm ul");
		jForm.find("*").off();

		for(k in ldtk.Json.WorldLayout.getConstructors())
			jForm.removeClass("layout-"+k);
		jForm.addClass("layout-"+project.worldLayout.getName());

		// World layout
		var old = project.worldLayout;
		var e = new form.input.EnumSelect(
			jForm.find("[name=worldLayout]"),
			ldtk.Json.WorldLayout,
			()->project.worldLayout,
			(l)->project.worldLayout = l,
			(l)->switch l {
				case Free: L.t._("2D free map - Freely positioned in space");
				case GridVania: L.t._("GridVania - Levels are positioned inside a large world-scale grid");
				case LinearHorizontal: L.t._("Horizontal - One level after the other");
				case LinearVertical: L.t._("Vertical - One level after the other");
			}
		);
		if( project.levels.length>2 )
			e.confirmMessage = L.t._("Changing this will change ALL the level positions! Please make sure you know what you're doing :)");
		e.onBeforeSetter = ()->{
			new LastChance(L.t._("World layout changed"), editor.project);
		}
		e.onValueChange = (l)->{
			project.onWorldLayoutChange(old);
			project.reorganizeWorld();
		}
		e.linkEvent( WorldSettingsChanged );

		// World grid
		var old = project.worldGridWidth;
		var i = Input.linkToHtmlInput( project.worldGridWidth, jForm.find("[name=worldGridWidth]"));
		i.linkEvent(WorldSettingsChanged);
		i.onChange = ()->project.onWorldGridChange(old, project.worldGridHeight);

		var old = project.worldGridHeight;
		var i = Input.linkToHtmlInput( project.worldGridHeight, jForm.find("[name=worldGridHeight]"));
		i.linkEvent(WorldSettingsChanged);
		i.onChange = ()->project.onWorldGridChange(project.worldGridWidth, old);

		JsTools.parseComponents(jForm);
	}



	function updateLevelForm() {
		if( level==null ) {
			close();
			return;
		}

		var jForm = jContent.find("ul#levelForm");
		jForm.find("*").off();


		// Level identifier
		jContent.find(".levelIdentifier").text('"${level.identifier}" (#${level.uid})');
		var i = Input.linkToHtmlInput( level.identifier, jForm.find("#identifier"));
		i.onChange = ()->onFieldChange();

		// Coords
		var i = Input.linkToHtmlInput( level.worldX, jForm.find("#worldX"));
		i.onChange = ()->onFieldChange();
		var i = Input.linkToHtmlInput( level.worldY, jForm.find("#worldY"));
		i.onChange = ()->onFieldChange();

		// Size
		var tmpWid = level.pxWid;
		var tmpHei = level.pxHei;
		var e = jForm.find("#width"); e.replaceWith( e.clone() ); // block undo/redo
		var i = Input.linkToHtmlInput( tmpWid, jForm.find("#width") );
		i.setBounds(project.defaultGridSize*2, 4096);
		i.onChange = ()->onLevelResized(tmpWid, tmpHei);

		var e = jForm.find("#height"); e.replaceWith( e.clone() ); // block undo/redo
		var i = Input.linkToHtmlInput( tmpHei, jForm.find("#height"));
		i.setBounds(project.defaultGridSize*2, 4096);
		i.onChange = ()->onLevelResized(tmpWid, tmpHei);

		// Bg color
		var c = level.getBgColor();
		var i = Input.linkToHtmlInput( c, jForm.find("#bgColor"));
		i.isColorCode = true;
		i.onChange = ()->{
			level.bgColor = c==project.defaultLevelBgColor ? null : c;
			onFieldChange();
		}
		var jSetDefault = i.jInput.siblings("a.reset");
		if( level.bgColor==null )
			jSetDefault.hide();
		else
			jSetDefault.show();
		jSetDefault.click( (_)->{
			level.bgColor = null;
			onFieldChange();
		});
		var jIsDefault = i.jInput.siblings("span.usingDefault").hide();
		if( level.bgColor==null )
			jIsDefault.show();
		else
			jIsDefault.hide();

		// Create bg image picker
		jForm.find(".bg .imagePicker").remove();
		var jImg = JsTools.createImagePicker(level.bgRelPath, (?relPath)->{
			var old = level.bgRelPath;
			if( relPath==null && old!=null ) {
				// Remove
				level.bgRelPath = null;
				level.bgPos = null;
				editor.watcher.stopWatchingRel( old );
			}
			else if( relPath!=null ) {
				// Add or update
				level.bgRelPath = relPath;
				if( old!=null )
					editor.watcher.stopWatchingRel( old );
				editor.watcher.watchImage(relPath);
				if( old==null )
					level.bgPos = Cover;
			}
			onFieldChange();
		});
		jImg.insertAfter( jForm.find(".bg>label:first-of-type") );

		// Bg position
		var jSelect = jForm.find("#bgPos");
		jSelect.empty();
		if( level.bgPos!=null ) {
			for(k in ldtk.Json.BgImagePos.getConstructors()) {
				var e = ldtk.Json.BgImagePos.createByName(k);
				var jOpt = new J('<option value="$k"/>');
				jSelect.append(jOpt);
				jOpt.text( switch e {
					case Unscaled: Lang.t._("Not scaled");
					case Contain: Lang.t._("Fit inside (keep aspect ratio)");
					case Cover: Lang.t._("Cover level (keep aspect ratio)");
					case CoverDirty: Lang.t._("Cover (dirty scaling)");
				});
			}
			jSelect.val( level.bgPos.getName() );
			jSelect.prop("disabled",false);
			jSelect.change( (_)->{
				level.bgPos = ldtk.Json.BgImagePos.createByName( jSelect.val() );
				onFieldChange();
			});
		}
		else
			jSelect.prop("disabled",true);


		// Custom fields
		// ... (not implemented yet)

		JsTools.parseComponents(jForm);
	}

	override function update() {
		super.update();
		if( !editor.worldMode )
			close();

		if( !editor.worldTool.isInAddMode() && jContent.find("button.create.running").length>0 )
			jContent.find("button.create").removeClass("running");
	}
}