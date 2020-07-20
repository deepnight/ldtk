package ui.modal.panel;

class ProjectSettings extends ui.modal.Panel {

	public function new() {
		super();

		loadTemplate( "projectSettings", "projectSettings" );
		linkToButton("button.editProject");

		jContent.find("button.new").click( function(ev) client.onNew(ev.getThis()) );
		jContent.find("button.load").click( function(_) client.onLoad() );

		updateProjectForm();
	}

	override function onGlobalEvent(ge:GlobalEvent) {
		super.onGlobalEvent(ge);
		updateProjectForm();
	}

	function updateProjectForm() {
		var jForm = jContent.find("ul.form:first");

		var i = Input.linkToHtmlInput( project.name, jForm.find("[name=pName]") );
		i.linkEvent(ProjectSettingsChanged);

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
				client.ge.emit(ProjectSettingsChanged);
			}
		));
	}
}
