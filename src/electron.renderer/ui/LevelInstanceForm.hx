package ui;

class LevelInstanceForm {
	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;

	public var jWrapper : js.jquery.JQuery;
	var level: data.Level;
	var fieldsForm : FieldInstancesForm;

	public function new() {
		jWrapper = new J('<div class="levelInstanceForm"/>');

		level = editor.curLevel;
		var raw = JsTools.getHtmlTemplate("levelInstanceForm");
		jWrapper.html(raw);

		// Create button
		jWrapper.find("button.create").click( (_)->{
			var vp = new ui.vp.LevelSpotPicker();
		});

		// Delete button
		jWrapper.find("button.delete").click( (_)->{
			if( project.levels.length<=1 ) {
				N.error(L.t._("You can't delete the last level."));
				return;
			}

			new ui.modal.dialog.Confirm(
				Lang.t._("Are you sure you want to delete this level?"),
				true,
				()->{
					var closest = project.getClosestLevelFrom(level);
					new LastChance( L.t._('Level ::id:: removed', {id:level.identifier}), project);
					var deleted = level;
					editor.selectLevel( closest );
					project.removeLevel(deleted);
					editor.ge.emit( LevelRemoved(deleted) );
					editor.setWorldMode(true);
				}
			);
		});

		// Duplicate button
		jWrapper.find("button.duplicate").click( (_)->{
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
			editor.invalidateLevelCache(copy);
		});

		// World panel
		jWrapper.find("button.worldSettings").click( (_)->{
			new ui.modal.panel.WorldPanel();
		});

		// World panel "edit" shortcut
		jWrapper.find(".editFields").click( (_)->{
			new ui.modal.panel.EditLevelFieldDefs();
		});

		// Field instance form
		fieldsForm = new FieldInstancesForm();
		jWrapper.find("#levelCustomFields").replaceWith( fieldsForm.jWrapper );

		updateLevelPropsForm();
		updateFieldsForm();
	}

	public inline function isUsingLevel(l:data.Level) {
		return l!=null && level!=null && l.iid==level.iid;
	}

	public function useLevel(l:data.Level) {
		level = l;
		updateLevelPropsForm();
		updateFieldsForm();
	}

	public function dispose() {
		jWrapper.remove();
		jWrapper = null;
		level = null;
		fieldsForm.dispose();
		fieldsForm = null;
	}

	public function onGlobalEvent(ge:GlobalEvent) {
		switch ge {
			case ProjectSelected:
				useLevel(editor.curLevel);

			case LevelRestoredFromHistory(l):
				if( isUsingLevel(l) )
					useLevel(l);

			case LevelSettingsChanged(l):
				if( isUsingLevel(l) )
					updateLevelPropsForm();

			case LevelAdded(level):

			case LevelSelected(l):
				useLevel(l);
				jWrapper.show();

			case LevelRemoved(l):
				if( isUsingLevel(l) )
					jWrapper.hide();

			case WorldLevelMoved(_):
				updateLevelPropsForm();
				updateFieldsForm();

			case FieldDefSorted, FieldDefRemoved(_), FieldDefChanged(_), FieldDefAdded(_):
				updateFieldsForm();

			case LevelFieldInstanceChanged(l,fi):
				if( isUsingLevel(l) )
					updateFieldsForm();

			case _:
		}
	}

	function onFieldChange() {
		editor.ge.emit( LevelSettingsChanged(level) );
		editor.invalidateLevelCache(level);
	}

	function onLevelResized(newPxWid:Int,newPxHei:Int) {
		new LastChance( Lang.t._("Level resized"), project );
		var before = level.toJson();
		level.applyNewBounds(0, 0, newPxWid, newPxHei);
		onFieldChange();
		editor.ge.emit( LevelResized(level) );
		editor.invalidateLevelCache(level);
		editor.curLevelHistory.saveResizedState( before, level.toJson() );
		new J("dl#levelForm *:focus").blur();
	}


	function updateLevelPropsForm() {
		ui.Tip.clear();

		var jForm = jWrapper.find("dl#levelProps");
		jForm.find("*").off();

		if( level==null )
			return;

		// Level identifier
		jWrapper.find(".levelIdentifier").text('"${level.identifier}"');
		var i = Input.linkToHtmlInput( level.identifier, jForm.find("#identifier"));
		i.fixValue = (v)->project.fixUniqueIdStr(v, (id)->project.isLevelIdentifierUnique(id, level));
		i.onChange = ()->onFieldChange();
		if( level.useAutoIdentifier )
			i.disable();
		else
			i.enable();

		// Auto level identifier
		var i = Input.linkToHtmlInput( level.useAutoIdentifier, jForm.find("#useAutoIdentifier") );
		i.onChange = ()->{
			project.applyAutoLevelIdentifiers();
			onFieldChange();
		}

		// Coords
		var i = Input.linkToHtmlInput( level.worldX, jForm.find("#worldX"));
		i.onChange = ()->onFieldChange();
		i.fixValue = v->project.snapWorldGridX(v,false);

		var i = Input.linkToHtmlInput( level.worldY, jForm.find("#worldY"));
		i.onChange = ()->onFieldChange();
		i.fixValue = v->project.snapWorldGridY(v,false);

		// Size
		var tmpWid = level.pxWid;
		var tmpHei = level.pxHei;
		var e = jForm.find("#width"); e.replaceWith( e.clone() ); // block undo/redo
		var i = Input.linkToHtmlInput( tmpWid, jForm.find("#width") );
		i.setBounds(project.defaultGridSize, 4096);
		i.onValueChange = (v)->onLevelResized(v, tmpHei);
		i.fixValue = v->project.snapWorldGridX(v,true);

		var e = jForm.find("#height"); e.replaceWith( e.clone() ); // block undo/redo
		var i = Input.linkToHtmlInput( tmpHei, jForm.find("#height"));
		i.setBounds(project.defaultGridSize, 4096);
		i.onValueChange = (v)->onLevelResized(tmpWid, v);
		i.fixValue = v->project.snapWorldGridY(v,true);

		// Bg color
		var c = level.getBgColor();
		var i = Input.linkToHtmlInput( c, jForm.find("#bgColor"));
		i.jInput.attr("colorTag","bg");
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
		jForm.find("dd.bg .imagePicker").remove();
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
		jImg.prependTo( jForm.find("dd.bg") );

		if( level.bgRelPath!=null )
			jForm.find("dd.bg .pos").show();
		else
			jForm.find("dd.bg .pos").hide();


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
			jSelect.change( (_)->{
				level.bgPos = ldtk.Json.BgImagePos.createByName( jSelect.val() );
				onFieldChange();
			});
		}

		// Bg pivot
		var jPivot = jForm.find(".pos>.pivot");
		jPivot.empty();
		if( level.bgRelPath!=null )
			jPivot.append( JsTools.createPivotEditor(level.bgPivotX, level.bgPivotY, (x,y)->{
				level.bgPivotX = x;
				level.bgPivotY = y;
				onFieldChange();
			}) );


		JsTools.parseComponents(jForm);
	}


	function updateFieldsForm() {
		fieldsForm.use( Level(level), project.defs.levelFields, (fd)->level.getFieldInstance(fd) );
	}
}