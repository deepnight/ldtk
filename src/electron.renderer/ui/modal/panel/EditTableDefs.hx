package ui.modal.panel;
import cdb.Data.ColumnType;
import haxe.DynamicAccess;

class EditTableDefs extends ui.modal.Panel {
	var curSheet : Null<cdb.Sheet>;
	var tabulatorView = true;
	var tabulator : Tabulator;	

	public function new() {
		super();

		// Main page
		linkToButton("button.editTables");
		loadTemplate("editTableDefs");

		// Create a new table
		jContent.find("button.createTable").click( function(ev) {
			// var td = project.defs.createTable("New Table", ["Key"], [["Row"]]);
			// editor.ge.emit(TableDefAdded(td));
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
								i.load( project.makeRelativeFilePath(absPath) );
							case _:
								N.error('The file must have the ".csv" extension.');
						}
					});
				},
			});
		});
		if (project.db.sheets.length > 0) {
			selectTable(project.db.sheets[0]);
			return;
		}
		updateTableList();
		updateTableForm();
	}

	override function onGlobalEvent(e:GlobalEvent) {
		// super.onGlobalEvent(e);
		// switch e {
		// 	case TableDefAdded(td), TableDefChanged(td):
		// 		selectTable(td);

		// 	case TableDefRemoved(td):
		// 		selectTable(project.defs.tables[0]);

		// 	case _:
		// }
	}

	function updateTableForm() {
		var jTabForm = jContent.find("dl.tableForm");

		if( curSheet==null ) {
			jTabForm.hide();
			return;
		}
		jTabForm.show();
		// Input.linkToHtmlInput(curSheet.name, jTabForm.find("input[name='name']") );
		// i.linkEvent(TableDefChanged(curTable));

		// var jSel = jContent.find("#primaryKey");
		// for (column in curTable.columns) {
		// 	jSel.append('<option>'+ column +'</option>');
		// }
		// var i = Input.linkToHtmlInput(curTable.primaryKey, jTabForm.find("select[name='primaryKey']") );
		// i.linkEvent(TableDefChanged(curTable));
		// var i = Input.linkToHtmlInput(tableView, jTabForm.find("input[id='tableView']") );
		// i.linkEvent(TableDefChanged(curTable));
	}

	function selectTable (sheet:cdb.Sheet) {
		curSheet = sheet;
		updateTableList();
		updateTableForm();

		var jTabEditor = jContent.find("#tableEditor");
		jTabEditor.empty();

		if (tabulatorView) {
			var tabulator = new Tabulator("#tableEditor", curSheet);
		} else {
			// var tableDefsForm = new ui.TableDefsForm(curTable);
			// jTabEditor.append(tableDefsForm.jWrapper);
		}
	}

	function deleteSheet(sheet:cdb.Sheet) {
		new LastChance(L.t._("Table ::name:: deleted", { name:sheet.name }), project);
		// var old = td;
		// project.defs.removeTableDef(td);
		// editor.ge.emit( TableDefRemoved(old) );
	}

	function updateTableList() {

		var jList = jContent.find(".tableList>ul");
		jList.empty();

		var jLi = new J('<li class="subList"/>');
		jLi.appendTo(jList);
		var jSubList = new J('<ul/>');
		jSubList.appendTo(jLi);

		for (sheet in project.db.sheets.filter((x) -> !x.props.hide)) {
			var jLi = new J("<li/>");
			jLi.appendTo(jSubList);
			jLi.append('<span class="table">'+sheet.name+'</span>');
			// jLi.data("uid",td.uid);

			if( sheet==curSheet )
				jLi.addClass("active");
			jLi.click( function(_) {
				selectTable(sheet);
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
					cb: deleteSheet.bind(sheet),
				},
			]);
		}

		// Make list sortable
		JsTools.makeSortable(jSubList, function(ev) {
			// var jItem = new J(ev.item);
			// var fromIdx = project.defs.getTableIndex( jItem.data("uid") );
			// var toIdx = ev.newIndex>ev.oldIndex
			// 	? jItem.prev().length==0 ? 0 : project.defs.getTableIndex( jItem.prev().data("uid") )
			// 	: jItem.next().length==0 ? project.defs.tables.length-1 : project.defs.getTableIndex( jItem.next().data("uid") );

			// var moved = project.defs.sortTableDef(fromIdx, toIdx);
			// selectTable(moved);
			// editor.ge.emit(TilesetDefSorted);
		});
	}
}