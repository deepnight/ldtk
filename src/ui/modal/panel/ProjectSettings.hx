package ui.modal.panel;

class ProjectSettings extends ui.modal.Panel {
	var jForm(get,never) : js.jquery.JQuery; inline function get_jForm() return jModalAndMask.find("ul.form:first");

	public function new() {
		super();

		loadTemplate( "projectSettings", "projectSettings" );
		linkToButton("button.editProject");
		updateForm();

		jContent.find("button.new").click( function(ev) client.onNew(ev.getThis()) );
		jContent.find("button.load").click( function(_) client.onLoad() );
		jContent.find("button.save").click( function(_) client.onSave() );

	}

	override function onGlobalEvent(e:GlobalEvent) {
		super.onGlobalEvent(e);
		updateForm();
	}

	function updateForm() {
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
