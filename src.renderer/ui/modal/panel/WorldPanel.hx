package ui.modal.panel;

class WorldPanel extends ui.modal.Panel {
	var level(get,never) : data.Level;
		inline function get_level() return editor.curLevel;

	public function new() {
		super();

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
					var dh = new dn.DecisionHelper(project.levels);
					dh.removeValue(level);
					dh.score( (l)->-level.getBoundsDist(l) );

					new LastChance('Level ${level.identifier} removed', project);
					var l = level;
					project.removeLevel(level);
					editor.ge.emit( LevelRemoved(l) );
					editor.selectLevel( dh.getBest() );
					updateForm();
				}
			);
		});

		// Create button
		jContent.find("button.create").click( (_)->{
			editor.worldTool.startAddMode();
			N.msg(L.t._("Select a spot on the world map..."));
		});

		// Duplicate button
		jContent.find("button.duplicate").click( (_)->{
			var copy = project.duplicateLevel(level);
			editor.selectLevel(copy);
			switch project.worldLayout {
				case Free, WorldGrid:
					copy.worldX += project.defaultGridSize*4;
					copy.worldY += project.defaultGridSize*4;

				case LinearHorizontal:
				case LinearVertical:
			}
			editor.ge.emit( LevelAdded(copy) );
		});


		updateForm();
	}

	override function onGlobalEvent(ge:GlobalEvent) {
		super.onGlobalEvent(ge);

		switch ge {
			case ProjectSettingsChanged:
				if( level==null )
					destroy();
				else
					updateForm();

			case LevelSelected(l):
				updateForm();

			case LevelRemoved(l):
				updateForm();

			case WorldLevelMoved:
				updateForm();

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


	function updateForm() {
		if( level==null ) {
			close();
			return;
		}

		var jForm = jContent.find("ul.form");
		jForm.find("*").off();

		// Level identifier
		jForm.find(".uid").text("#"+level.uid);
		var i = Input.linkToHtmlInput( level.identifier, jForm.find("#identifier"));
		i.onChange = ()->onFieldChange();

		// Coords
		var i = Input.linkToHtmlInput( level.worldX, jForm.find("#worldX"));
		i.onChange = ()->onFieldChange();
		var i = Input.linkToHtmlInput( level.worldY, jForm.find("#worldY"));
		i.onChange = ()->onFieldChange();

		// Bg color
		var c = level.getBgColor();
		var i = Input.linkToHtmlInput( c, jForm.find("#bgColor"));
		i.isColorCode = true;
		i.onChange = ()->{
			level.bgColor = c==project.defaultLevelBgColor ? null : c;
			onFieldChange();
		}
		var jDefault = i.jInput.siblings("a.reset");
		if( level.bgColor==null )
			jDefault.hide();
		jDefault.click( (_)->{
			level.bgColor = null;
			onFieldChange();
		});
		if( level.bgColor!=null )
			i.jInput.siblings("span.usingDefault").hide();

		// Custom fields (not implemented yet)
		// if( level.def.fieldDefs.length==0 )
		// 	jForm.append('<div class="empty">This entity has no custom field.</div>');
		// else {
		// 	// Field defs form
		// 	var jForm = renderFieldDefsForm(level.def.fieldDefs, (fd)->level.getFieldInstance(fd));
		// 	jForm.appendTo(jForm);
		// }
	}

	override function update() {
		super.update();
		if( !editor.worldMode )
			close();
	}
}