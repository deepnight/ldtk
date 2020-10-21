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
			new ui.modal.dialog.Confirm(ev.getThis(), function() {
				deleteLevel(curLevel);
			});
		});

		updateList();
		updateForm();
	}

	function deleteLevel(l:data.Level) {
		if( project.levels.length==1 ) {
			N.error(L.t._("Can't delete the last level."));
			return false;
		}

		new LastChance(Lang.t._("Level ::name:: deleted", { name:l.identifier }), project);
		var idx = 0;
		for( pl in project.levels)
			if( pl==l )
				break;
			else
				idx++;
		project.removeLevel( l );
		if( idx==0 )
			editor.selectLevel( project.levels[0] );
		else
			editor.selectLevel( project.levels[idx-1] );
		editor.ge.emit(LevelRemoved);
		return true;
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
		i.validityCheck = function(id) return data.Project.isValidIdentifier(id) && project.isLevelIdentifierUnique(id);
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

			ContextMenu.addTo(e, [
				{
					label: L._Duplicate(),
					cb:()->{
						project.duplicateLevel(l);
						editor.ge.emit(LevelAdded);
					}
				},
				{ label: L._Delete(), cb:deleteLevel.bind(l) },
			]);

			if( l.hasAnyError() )
				e.append('<div class="error">Contains errors</div>');

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

	function select(l:data.Level) {
		editor.selectLevel(l);
	}
}

