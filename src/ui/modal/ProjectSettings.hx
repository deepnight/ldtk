package ui.modal;

class ProjectSettings extends ui.Modal {
	var jForm(get,never) : js.jquery.JQuery; inline function get_jForm() return jWin.find("ul.form:first");

	public function new() {
		super();

		loadTemplate( "projectSettings", "projectSettings" );
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
