package ui.modal.panel;

class WorldPanel extends ui.modal.Panel {
	var fieldForm : FieldDefsForm;

	public function new() {
		super();

		jMask.hide();
		loadTemplate("worldPanel");

		fieldForm = new FieldDefsForm(FP_Level);
		jContent.find("#levelFields").replaceWith(fieldForm.jWrapper);
		fieldForm.useFields( project.defs.levelFields );
		updateWorldForm();
	}


	override function onGlobalEvent(ge:GlobalEvent) {
		super.onGlobalEvent(ge);

		switch ge {
			case WorldSettingsChanged:
				updateWorldForm();

			case ProjectSelected:
				fieldForm.useFields( project.defs.levelFields );
				updateWorldForm();

			case _:
		}
	}


	function updateWorldForm() {
		var jForm = jContent.find(".worldSettings ul.form");
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

		// Default new level size
		var i = Input.linkToHtmlInput( project.defaultLevelWidth, jForm.find("#defaultLevelWidth"));
		i.linkEvent(WorldSettingsChanged);
		i.setBounds(32, 9999);
		i.fixValue = v->project.snapWorldGridX(v,true);
		var i = Input.linkToHtmlInput( project.defaultLevelHeight, jForm.find("#defaultLevelHeight"));
		i.linkEvent(WorldSettingsChanged);
		i.setBounds(32, 9999);
		i.fixValue = v->project.snapWorldGridY(v,true);

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


	override function onClose() {
		super.onClose();
		var anyNonWorldPanel = false;
		for(m in Modal.ALL)
			if( !m.destroyed && m!=this && !Std.isOfType(m,LevelPanel) ) {
				anyNonWorldPanel = true;
				break;
			}
		if( !anyNonWorldPanel )
			new LevelPanel();
		else if( editor.worldMode )
			editor.setWorldMode(false);
	}

	override function update() {
		super.update();
		if( !editor.worldMode )
			close();
	}
}