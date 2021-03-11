package ui.modal.panel;

class LevelInstancePanel extends ui.modal.Panel {
	var level: data.Level;
	var fieldsForm : FieldInstancesForm;

	public function new() {
		super();

		level = editor.curLevel;
		loadTemplate("levelInstancePanel");
		linkToButton("button.editLevelInstance");

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
					var deleted = level;
					close();
					editor.selectLevel( closest );
					project.removeLevel(deleted);
					editor.ge.emit( LevelRemoved(deleted) );
					editor.setWorldMode(true);
				}
			);
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

		// World panel
		jContent.find("button.worldSettings").click( (_)->{
			new ui.modal.panel.WorldPanel();
		});

		// World panel "edit" shortcut
		jContent.find(".editFields").click( (_)->{
			new ui.modal.panel.EditLevelFieldDefs();
		});

		// Field instance form
		fieldsForm = new FieldInstancesForm();
		jContent.find("#fieldInstances").replaceWith( fieldsForm.jWrapper );

		updateLevelForm();
		updateFieldsForm();
	}

	function useLevel(l:data.Level) {
		level = l;
		updateLevelForm();
		updateFieldsForm();
	}

	override function onGlobalEvent(ge:GlobalEvent) {
		super.onGlobalEvent(ge);

		switch ge {
			case WorldSettingsChanged:
				if( level==null || project.getLevel(level.uid)==null )
					destroy();
				else
					updateLevelForm();

			case ProjectSelected:
				useLevel(editor.curLevel);

			case LevelRestoredFromHistory(l):
				if( l.uid==level.uid )
					useLevel(l);

			case LevelSettingsChanged(l):
				if( l==level )
					updateLevelForm();

			case LevelAdded(level):

			case LevelSelected(l):
				if( l!=level )
					close();

			case LevelRemoved(l):
				if( l==level )
					close();

			case WorldLevelMoved:
				updateLevelForm();
				updateFieldsForm();

			case FieldDefSorted, FieldDefRemoved(_), FieldDefChanged(_), FieldDefAdded(_):
				updateFieldsForm();

			case FieldInstanceChanged(fd):
				updateFieldsForm();

			case _:
		}
	}

	function onFieldChange() {
		editor.ge.emit( LevelSettingsChanged(level) );
	}

	function onLevelResized(newPxWid:Int,newPxHei:Int) {
		new LastChance( Lang.t._("Level resized"), project );
		var before = level.toJson();
		curLevel.applyNewBounds(0, 0, newPxWid, newPxHei);
		onFieldChange();
		editor.ge.emit( LevelResized(level) );
		editor.curLevelHistory.saveResizedState( before, level.toJson() );
		new J("dl#levelForm *:focus").blur();
	}


	function updateLevelForm() {
		ui.Tip.clear();

		if( level==null ) {
			close();
			return;
		}

		var jForm = jContent.find("dl#levelForm");
		jForm.find("*").off();


		// Level identifier
		jContent.find(".levelIdentifier").text('"${level.identifier}"');
		var i = Input.linkToHtmlInput( level.identifier, jForm.find("#identifier"));
		i.fixValue = (v)->project.makeUniqueIdStr(v, (id)->project.isLevelIdentifierUnique(id, level));
		i.onChange = ()->onFieldChange();

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
		i.setBounds(project.defaultGridSize*2, 4096);
		i.onValueChange = (v)->onLevelResized(v, tmpHei);
		i.fixValue = v->project.snapWorldGridX(v,true);

		var e = jForm.find("#height"); e.replaceWith( e.clone() ); // block undo/redo
		var i = Input.linkToHtmlInput( tmpHei, jForm.find("#height"));
		i.setBounds(project.defaultGridSize*2, 4096);
		i.onValueChange = (v)->onLevelResized(tmpWid, v);
		i.fixValue = v->project.snapWorldGridY(v,true);

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