package ui.modal.panel;
import tabulator.Tabulator;

using Lambda;
class EditTableDefs extends ui.modal.Panel {
	var curTable : Null<data.def.TableDef>;
	var tableView = false;
	var tabulator : Tabulator;	

	public function new() {
		super();

		// Main page
		linkToButton("button.editTables");
		loadTemplate("editTableDefs");

		// Create a new table
		jContent.find("button.createTable").click( function(ev) {
			var td = project.defs.createTable("New Table", ["Key"], [["Row"]]);
			editor.ge.emit(TableDefAdded(td));
		});

		// Import
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
								var td = i.load( project.makeRelativeFilePath(absPath) );
								editor.ge.emit(TableDefAdded(td));
							case _:
								N.error('The file must have the ".csv" extension.');
						}
					});
				},
			});
		});
		updateTableList();
		updateTableForm();
	}

	override function onGlobalEvent(e:GlobalEvent) {
		super.onGlobalEvent(e);
		switch e {
			case TableDefAdded(td), TableDefChanged(td):
				selectTable(td);

			case TableDefRemoved(td):
				selectTable(project.defs.tables[0]);

			case _:
		}
	}

	function updateTableForm() {
		var jTabForm = jContent.find("dl.tableForm");

		if( curTable==null ) {
			jTabForm.hide();
			return;
		}
		jTabForm.show();
		var i = Input.linkToHtmlInput(curTable.name, jTabForm.find("input[name='name']") );

		var jSel = jContent.find("#primaryKey");
		for (column in curTable.columns) {
			jSel.append('<option>'+ column +'</option>');
		}
		var i = Input.linkToHtmlInput(curTable.primaryKey, jTabForm.find("select[name='primaryKey']") );
		var i = Input.linkToHtmlInput(tableView, jTabForm.find("input[id='tableView']") );
	}

	function selectTable (td:data.def.TableDef) {
		curTable = td;
		updateTableList();
		updateTableForm();

		var table = curTable;
		var jTabEditor = jContent.find("#tableEditor");
		jTabEditor.empty();

		if (tableView) {
			var data = table.data;
			var columns = table.columns.map(function(x) return {title: x, field: x, editor: true});

			jContent.find("#tableEditor").append("<div id=tabulator></div>");
			tabulator = new Tabulator("#tabulator", {
				importFormat:"array",
				layout:"fitData",
				data: data,
				columns: columns,
				movableRows: true,
				movableColumns: true,
			});
			tabulator.on("cellEdited", function(cell) {
				// TODO Implement changing primary keys here aswell
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
		} else {
			var tableDefsForm = new ui.TableDefsForm(curTable);
			jTabEditor.append(tableDefsForm.jWrapper);
		}
	}

	function deleteTableDef(td:data.def.TableDef) {
		new LastChance(L.t._("Table ::name:: deleted", { name:td.name }), project);
		var old = td;
		project.defs.removeTableDef(td);
		editor.ge.emit( TableDefRemoved(old) );
	}

	function updateTableList() {

		var jList = jContent.find(".tableList>ul");
		jList.empty();

		var jLi = new J('<li class="subList"/>');
		jLi.appendTo(jList);
		var jSubList = new J('<ul/>');
		jSubList.appendTo(jLi);

		for(td in project.defs.tables) {
			var jLi = new J("<li/>");
			jLi.appendTo(jSubList);
			jLi.append('<span class="table">'+td.name+'</span>');
			jLi.data("uid",td.uid);

			if( td==curTable )
				jLi.addClass("active");
			jLi.click( function(_) {
				selectTable(td);
			});

			ContextMenu.addTo(jLi, [
				// {
				// 	label: L._Copy(),
				// 	cb: ()->App.ME.clipboard.copyData(CTilesetDef, td.toJson()),
				// 	enable: ()->!td.isUsingEmbedAtlas(),
				// },
				// {
				// 	label: L._Cut(),
				// 	cb: ()->{
				// 		App.ME.clipboard.copyData(CTilesetDef, td.toJson());
				// 		deleteTilesetDef(td);
				// 	},
				// 	enable: ()->!td.isUsingEmbedAtlas(),
				// },
				// {
				// 	label: L._PasteAfter(),
				// 	cb: ()->{
				// 		var copy = project.defs.pasteTilesetDef(App.ME.clipboard, td);
				// 		editor.ge.emit( TilesetDefAdded(copy) );
				// 		selectTileset(copy);
				// 	},
				// 	enable: ()->App.ME.clipboard.is(CTilesetDef),
				// },
				// {
				// 	label: L._Duplicate(),
				// 	cb: ()-> {
				// 		var copy = project.defs.duplicateTilesetDef(td);
				// 		editor.ge.emit( TilesetDefAdded(copy) );
				// 		selectTileset(copy);
				// 	},
				// 	enable: ()->!td.isUsingEmbedAtlas(),
				// },
				{
					label: L._Delete(),
					cb: deleteTableDef.bind(td),
				},
			]);
		}

		// Make list sortable
		JsTools.makeSortable(jSubList, function(ev) {
			var jItem = new J(ev.item);
			var fromIdx = project.defs.getTableIndex( jItem.data("uid") );
			var toIdx = ev.newIndex>ev.oldIndex
				? jItem.prev().length==0 ? 0 : project.defs.getTableIndex( jItem.prev().data("uid") )
				: jItem.next().length==0 ? project.defs.tables.length-1 : project.defs.getTableIndex( jItem.next().data("uid") );

			var moved = project.defs.sortTableDef(fromIdx, toIdx);
			selectTable(moved);
			// editor.ge.emit(TilesetDefSorted);
		});
	}
}