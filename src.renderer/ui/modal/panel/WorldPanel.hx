package ui.modal.panel;

class WorldPanel extends ui.modal.Panel {
	var level: data.Level;

	public function new() {
		super();

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
					var dh = new dn.DecisionHelper(project.levels);
					dh.removeValue(level);
					dh.score( (l)->-level.getBoundsDist(l) );

					new LastChance('Level ${level.identifier} removed', project);
					var l = level;
					project.removeLevel(level);
					editor.ge.emit( LevelRemoved(l) );
					editor.selectLevel( dh.getBest() );
					editor.camera.scrollToLevel(editor.curLevel);
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
			case ProjectSettingsChanged:
				if( level==null || project.getLevel(level.uid)==null )
					destroy();
				else {
					updateWorldForm();
					updateLevelForm();
				}

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


	function updateWorldForm() {
		if( level==null ) {
			close();
			return;
		}

		var jForm = jContent.find("ul#worldForm");
		jForm.find("*").off();

		// World layout
		var e = new form.input.EnumSelect(
			jForm.find("[name=worldLayout]"),
			data.DataTypes.WorldLayout,
			()->project.worldLayout,
			(l)->project.worldLayout = l,
			(l)->switch l {
				case Free: L.t._("FREE - freely positioned in space");
				case WorldGrid: L.t._("CASTLEVANIESQUE - levels are positioned inside a large world-scale grid");
				case LinearHorizontal: L.t._("LINEAR (horizontal) - one level after the other");
				case LinearVertical: L.t._("LINEAR (vertical) - one level after the other");
			}
		);
		if( project.levels.length>2 )
			e.confirmMessage = L.t._("Changing this might affect ALL the levels layout, so please make sure you know what you're doing :)");
		e.onValueChange = (l)->{
			project.reorganizeWorld();
		}
		e.linkEvent( ProjectSettingsChanged ); // TODO use another event

		// World grid
		var i = Input.linkToHtmlInput( project.worldGridWidth, jForm.find("[name=worldGridWidth]"));
		i.linkEvent(ProjectSettingsChanged);

		var i = Input.linkToHtmlInput( project.worldGridHeight, jForm.find("[name=worldGridHeight]"));
		i.linkEvent(ProjectSettingsChanged);

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

		// Custom fields
		// ... (not implemented yet)

		JsTools.parseComponents(jForm);
	}

	override function update() {
		super.update();
		if( !editor.worldMode )
			close();
	}
}