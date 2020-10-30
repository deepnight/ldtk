package ui.modal.panel;

class EditProject extends ui.modal.Panel {

	public function new() {
		super();

		loadTemplate("editProject", "editProject");
		linkToButton("button.editProject");

		jContent.find("button.save").click( function(ev) {
			editor.onSave();
		});

		jContent.find("button.saveAs").click( function(ev) {
			editor.onSaveAs();
		});

		updateProjectForm();
	}

	override function onGlobalEvent(ge:GlobalEvent) {
		super.onGlobalEvent(ge);
		updateProjectForm();
	}

	function updateProjectForm() {
		var jForm = jContent.find("ul.form:first");

		var i = Input.linkToHtmlInput( project.minifyJson, jForm.find("[name=minify]") );
		i.linkEvent(ProjectSettingsChanged);

		var i = Input.linkToHtmlInput( project.exportTiled, jForm.find("[name=tiled]") );
		i.linkEvent(ProjectSettingsChanged);
		i.onValueChange = function(v) {
			if( v )
				new ui.modal.dialog.Message(Lang.t._("Disclaimer: Tiled export is only meant to load your LEd project in a game framework that only supports Tiled files. It is recommended to write your own LEd JSON parser, as some LEd features may not be supported.\nIt's not so complicated, I promise :)"), "project");
		}

		var i = Input.linkToHtmlInput( project.defaultGridSize, jForm.find("[name=defaultGridSize]") );
		i.setBounds(1,Const.MAX_GRID_SIZE);
		i.linkEvent(ProjectSettingsChanged);

		var i = Input.linkToHtmlInput( project.bgColor, jForm.find("[name=color]"));
		i.isColorCode = true;
		i.linkEvent(ProjectSettingsChanged);

		var pivot = jForm.find(".pivot");
		pivot.empty();
		pivot.append( JsTools.createPivotEditor(
			project.defaultPivotX, project.defaultPivotY,
			0x0,
			function(x,y) {
				project.defaultPivotX = x;
				project.defaultPivotY = y;
				editor.ge.emit(ProjectSettingsChanged);
			}
		));

		JsTools.parseComponents(jForm);
	}
}
