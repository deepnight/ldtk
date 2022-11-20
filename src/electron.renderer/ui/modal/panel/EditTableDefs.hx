package ui.modal.panel;
import tabulator.Tabulator;

using Lambda;
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

		// TODO FIX THIS
		var table = project.defs.tables[0];

		var data = table.data;
		var columns = table.columns.map(function(x) return {field: x, editor: true});

		var tabulator = new Tabulator("#tableEditor", {
			importFormat:"array",
			height:"311px",
			data: data,
			autoColumns: true,
			autoColumnsDefinitions: columns,
			movableRows: true,
			movableColumns: true,
		});
		tabulator.on("cellEdited", function(cell) {
			// TODO allow for different primary key
			var id = cell.getData().id;
			var key_index = table.columns.indexOf("id");
			for (row in data) {
				if (row[key_index] == id) {
					var key = table.columns.indexOf(cell.getField());
					row[key] = cell.getValue();
					break;
				}
			}
		});
	}

	function updateTableList() {

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