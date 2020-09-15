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
			editor.ge.emit(LevelAdded);
			select(l);
		});

		// Delete level
		jContent.find(".mainList button.delete").click( function(ev) {
			if( project.levels.length==1 )
				N.error(L.t._("Can't delete the last level."));
			else {
				new ui.modal.dialog.Confirm(ev.getThis(), function() {
					new LastChance(Lang.t._("Level ::name:: deleted", { name:curLevel.identifier }), project);
					var idx = 0;
					for( l in project.levels)
						if( l==curLevel )
							break;
						else
							idx++;
					project.removeLevel( curLevel );
					if( idx==0 )
						editor.selectLevel( project.levels[0] );
					else
						editor.selectLevel( project.levels[idx-1] );
					editor.ge.emit(LevelRemoved);
				});
			}
		});

		updateList();
		updateForm();
	}

	override function onGlobalEvent(e:GlobalEvent) {
		super.onGlobalEvent(e);

		switch e {
			case ProjectSettingsChanged, ProjectSelected, LayerInstanceRestoredFromHistory(_):
				close();

			case LayerInstanceSelected, LayerInstanceVisiblityChanged(_):

			case LevelSelected, LevelSettingsChanged:
				updateList();
				updateForm();

			case LevelAdded, LevelSorted:
				updateList();

			case _:
		}
		updateList();
		updateForm();
	}

	function updateForm() {
		var i = Input.linkToHtmlInput( curLevel.identifier, jForm.find("[name=name]") );
		i.linkEvent(LevelSettingsChanged);
		i.validityCheck = function(id) return led.Project.isValidIdentifier(id) && project.isLevelIdentifierUnique(id);
		i.validityError = N.invalidIdentifier;
	}

	function updateList() {
		var list = jContent.find("ul.levels");
		list.empty();

		for(l in project.levels) {
			var e = new J("<li/>");
			e.appendTo(list);
			e.text( l.identifier );
			if( curLevel==l )
				e.addClass("active");

			e.click( function(_) {
				select(l);
			});
		}

		// Make level list sortable
		JsTools.makeSortable(jList, function(ev) {
			var moved = project.sortLevel(ev.oldIndex, ev.newIndex);
			select(moved);
			editor.ge.emit(LevelSorted);
		});

	}

	function select(l:led.Level) {
		editor.selectLevel(l);
	}
}

