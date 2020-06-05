package ui.win;

class ProjectSettings extends ui.Window {
	var jForm(get,never) : js.jquery.JQuery; inline function get_jForm() return jWin.find("ul.form:first");

	public function new() {
		super();

		loadTemplate( hxd.Res.tpl.projectSettings, "projectSettings" );
		updateForm();
	}

	override function onGlobalEvent(e:GlobalEvent) {
		super.onGlobalEvent(e);
		switch e {
			case ProjectChanged:

			case LayerDefChanged:
			case LayerDefSorted:
			case LayerContentChanged:

			case EntityDefChanged:
			case EntityDefSorted:
			case EntityFieldChanged:
		}
	}

	function updateForm() {
		var i = Input.linkToHtmlInput( project.name, jForm.find("[name=pName]") );
		i.onChange = client.ge.emit.bind(ProjectChanged);
	}
}
