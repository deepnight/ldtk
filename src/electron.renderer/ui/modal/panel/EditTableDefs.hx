package ui.modal.panel;

class EditTableDefs extends ui.modal.Panel {
	var curTable : Null<data.def.TableDef>;

	public function new() {
		super();

		// Main page
		linkToButton("button.editTables");
		loadTemplate("editTableDefs");

		// Import
		jContent.find("button.refresh").click( ev->{
			updateTableList();
		});

		jContent.find("button.import").click( ev->{
			var ctx = new ContextMenu(ev);
			ctx.add({
				label: L.t._("CSV - Ulix Dexflow"),
				sub: L.t._('Expected format:\n - One entry per line\n - Fields separated by column'),
				cb: ()->{
					dn.js.ElectronDialogs.openFile([".csv"], project.getProjectDir(), function(absPath:String) {
						absPath = StringTools.replace(absPath,"\\","/");
						switch dn.FilePath.extractExtension(absPath,true) {
							case "csv":
								var i = new importer.Table();
								i.load( project.makeRelativeFilePath(absPath) );
							case _:
								N.error('The file must have the ".csv" extension.');
						}
					});
				},
			});
		});
		updateTableList();
	}

	function selectTable (td:data.def.TableDef) {
		curTable = td;
		updateTableList();
	}

	function updateTableList() {

		trace(project.defs.tables);
		var jEnumList = jContent.find(".tableList>ul");
		jEnumList.empty();

		var jLi = new J('<li class="subList"/>');
		jLi.appendTo(jEnumList);
		var jSubList = new J('<ul/>');
		jSubList.appendTo(jLi);

		for(t in project.defs.tables) {
			var jLi = new J("<li/>");
			jLi.appendTo(jSubList);
			jLi.append('<span class="table">'+t.name+'</span>');

			if( t==curTable )
				jLi.addClass("active");
			jLi.click( function(_) {
				selectTable(t);
			});
		}
	}
}