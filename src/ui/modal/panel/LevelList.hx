package ui.modal.panel;

class LevelList extends ui.modal.Panel {
	var jForm(get,never) : js.jquery.JQuery; inline function get_jForm() return jModalAndMask.find("ul.form:first");

	public function new() {
		super();

		loadTemplate( "levelList", "levelList" );
		linkToButton("button.levelList");
		updateList();
		updateForm();
	}

	override function onGlobalEvent(e:GlobalEvent) {
		super.onGlobalEvent(e);
		updateList();
		updateForm();
	}

	function updateForm() {
		var i = Input.linkToHtmlInput( curLevel.customName, jForm.find("[name=name]") );
		i.linkEvent(LevelSettingsChanged);
		i.setPlaceholder( curLevel.getDefaultName() );
	}

	function updateList() {
		var list = jContent.find("ul.levels");
		list.empty();

		for(l in project.levels) {
			var e = new J("<li/>");
			e.appendTo(list);
			e.text( l.getName() );
			if( curLevel==l )
				e.addClass("active");

			e.click( function(_) {
				select(l);
			});
		}
	}

	function select(l:led.Level) {
	}
}

