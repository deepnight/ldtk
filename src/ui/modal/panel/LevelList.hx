package ui.modal.panel;

class LevelList extends ui.modal.Panel {
	var jList(get,never) : js.jquery.JQuery; inline function get_jList() return jContent.find(".mainList ul");
	var jForm(get,never) : js.jquery.JQuery; inline function get_jForm() return jContent.find("ul.form:first");

	public function new() {
		super();

		loadTemplate( "levelList", "levelList" );
		linkToButton("button.levelList");

		jContent.find(".mainList button.create").click( function(ev) {
			var l = project.createLevel();
			client.ge.emit(LevelAdded);
			select(l);
		});

		jContent.find(".mainList button.delete").click( function(ev) {
			N.notImplemented();
		});

		updateList();
		updateForm();
	}

	override function onGlobalEvent(e:GlobalEvent) {
		super.onGlobalEvent(e);

		switch e {
			case ProjectSettingsChanged, ProjectSelected, LayerInstanceRestoredFromHistory:
				close();

			case LayerInstanceSelected, LayerInstanceVisiblityChanged:

			case LevelSelected, LevelSettingsChanged:
				updateList();
				updateForm();

			case LevelAdded:
				updateList();

			case _:
		}
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
		client.selectLevel(l);
	}
}

