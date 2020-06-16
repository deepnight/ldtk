package ui.modal.panel;

class ProjectSettings extends ui.modal.Panel {
	var jForm(get,never) : js.jquery.JQuery; inline function get_jForm() return jModalAndMask.find("ul.form:first");

	public function new() {
		super();

		loadTemplate( "projectSettings", "projectSettings" );
		linkToButton("button.editProject");
		updateForm();
	}

	override function onGlobalEvent(e:GlobalEvent) {
		super.onGlobalEvent(e);
	}

	function updateForm() {
		var i = Input.linkToHtmlInput( project.name, jForm.find("[name=pName]") );
		i.linkEvent(ProjectChanged);

		var i = Input.linkToHtmlInput( project.defaultGridSize, jForm.find("[name=defaultGridSize]") );
		i.setBounds(1,Const.MAX_GRID_SIZE);
		i.linkEvent(ProjectChanged);

		var i = Input.linkToHtmlInput( project.bgColor, jForm.find("[name=color]"));
		i.isColorCode = true;
		i.linkEvent(ProjectChanged);

		var pivot = jForm.find(".pivot");
		pivot.empty();
		pivot.append( JsTools.createPivotEditor(
			project.defaultPivotX, project.defaultPivotY,
			0x0,
			function(x,y) {
				project.defaultPivotX = x;
				project.defaultPivotY = y;
				client.ge.emit(ProjectChanged);
			}
		));
	}
}
