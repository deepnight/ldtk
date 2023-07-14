// package ui.modal.panel;
// using Lambda;
// // class Tools {
// // 	function jstree(jq:JQuery):JSTree {
// // 		return js.Syntax.code('{0}.jstree()', jq);
// // 	}
// // }
// // // then
// // using Tools;
// // jquery("#div").jstree();
// class EditResourceDefs extends ui.modal.Panel {
// 	var curTable:Null<data.def.TableDef>;
// 	public function new() {
// 		super();
// 		// Main page
// 		linkToButton("button.editResources");
// 		loadTemplate("editResourceDefs");
// 		// Import
// 		jContent.find("button.refresh").click(ev -> {
// 			updateTableList();
// 			updateTableForm();
// 		});
// 		jContent.find("button.import").click(ev -> {
// 			var ctx = new ContextMenu(ev);
// 			ctx.add({
// 				label: L.t._("CSV - Ulix Dexflow"),
// 				sub: L.t._('Expected format:\n - One entry per line\n - Fields separated by column'),
// 				cb: () -> {
// 					dn.js.ElectronDialogs.openFile([".csv"], project.getProjectDir(), function(absPath:String) {
// 						absPath = StringTools.replace(absPath, "\\", "/");
// 						switch dn.FilePath.extractExtension(absPath, true) {
// 							case "csv":
// 								var i = new importer.Table();
// 								i.load(project.makeRelativeFilePath(absPath));
// 							case _:
// 								N.error('The file must have the ".csv" extension.');
// 						}
// 					});
// 				},
// 			});
// 		});
// 		updateTableList();
// 		updateTableForm();
// 	}
// 	function updateTableForm() {
// 		var jTabForm = jContent.find("dl.tableForm");
// 		if (curTable == null) {
// 			jTabForm.hide();
// 			return;
// 		}
// 		jTabForm.show();
// 		var i = Input.linkToHtmlInput(curTable.name, jTabForm.find("input[name='name']"));
// 	}
// 	function selectTable(td:data.def.TableDef) {
// 		curTable = td;
// 		updateTableList();
// 		updateTableForm();
// 		var table = curTable;
// 		var data = table.data;
// 		var columns = table.columns.map(function(x) return {field: x, editor: true});
// 		var treeElement = new js.jquery.JQuery("#treeEditor");
// 		trace(treeElement);
// 		trace(js.Syntax.code('{0}.jstree({
// 		"core" : {
// 			"animation" : 0,
// 			"themes" : { "stripes" : true },
// 			"data" : [
// 				{ "text" : "Root node", "children" : [
// 						{ "text" : "Child node 1" },
// 						{ "text" : "Child node 2" }
// 				]}
// 			]
// 		},
// 		"types" : {
// 			"#" : {
// 			"max_children" : 1,
// 			"max_depth" : 4,
// 			"valid_children" : ["root"]
// 			},
// 			"root" : {
// 			"icon" : "/static/3.3.12/assets/images/tree_icon.png",
// 			"valid_children" : ["default"]
// 			},
// 			"default" : {
// 			"valid_children" : ["default","file"]
// 			},
// 			"file" : {
// 			"icon" : "glyphicon glyphicon-file",
// 			"valid_children" : []
// 			}
// 		},
// 		"plugins" : [
// 			"contextmenu", "dnd", "search",
// 			"state", "types", "wholerow"
// 		]
// 	})', treeElement));
// 		// trace(treeElement.nextAll(".trace"));
// 		// trace(treeElement.jstree());
// 		// var tabulator = new Jstree("#tableEditor", {
// 		// 	importFormat: "array",
// 		// });
// 	}
// 	function deleteTableDef(td:data.def.TableDef) {
// 		new LastChance(L.t._("Table ::name:: deleted", {name: td.name}), project);
// 		var old = td;
// 		project.defs.removeTableDef(td);
// 		selectTable(project.defs.tables[0]);
// 		// editor.ge.emit( TilesetDefRemoved(old) );
// 	}
// 	function updateTableList() {
// 		var jList = jContent.find(".tableList>ul");
// 		jList.empty();
// 		var jLi = new J('<li class="subList"/>');
// 		jLi.appendTo(jList);
// 		var jSubList = new J('<ul/>');
// 		jSubList.appendTo(jLi);
// 		for (td in project.defs.tables) {
// 			var jLi = new J("<li/>");
// 			jLi.appendTo(jSubList);
// 			jLi.append('<span class="table">' + td.name + '</span>');
// 			jLi.data("name", td.name);
// 			if (td == curTable)
// 				jLi.addClass("active");
// 			jLi.click(function(_) {
// 				selectTable(td);
// 			});
// 			ContextMenu.addTo(jLi, [
// 				// {
// 				// 	label: L._Copy(),
// 				// 	cb: ()->App.ME.clipboard.copyData(CTilesetDef, td.toJson()),
// 				// 	enable: ()->!td.isUsingEmbedAtlas(),
// 				// },
// 				// {
// 				// 	label: L._Cut(),
// 				// 	cb: ()->{
// 				// 		App.ME.clipboard.copyData(CTilesetDef, td.toJson());
// 				// 		deleteTilesetDef(td);
// 				// 	},
// 				// 	enable: ()->!td.isUsingEmbedAtlas(),
// 				// },
// 				// {
// 				// 	label: L._PasteAfter(),
// 				// 	cb: ()->{
// 				// 		var copy = project.defs.pasteTilesetDef(App.ME.clipboard, td);
// 				// 		editor.ge.emit( TilesetDefAdded(copy) );
// 				// 		selectTileset(copy);
// 				// 	},
// 				// 	enable: ()->App.ME.clipboard.is(CTilesetDef),
// 				// },
// 				// {
// 				// 	label: L._Duplicate(),
// 				// 	cb: ()-> {
// 				// 		var copy = project.defs.duplicateTilesetDef(td);
// 				// 		editor.ge.emit( TilesetDefAdded(copy) );
// 				// 		selectTileset(copy);
// 				// 	},
// 				// 	enable: ()->!td.isUsingEmbedAtlas(),
// 				// },
// 				{
// 					label: L._Delete(),
// 					cb: deleteTableDef.bind(td),
// 				},
// 			]);
// 		}
// 		// Make sub list sortable
// 		JsTools.makeSortable(jSubList, function(ev) {
// 			var jItem = new J(ev.item);
// 			var fromIdx = project.defs.getTableIndex(jItem.data("name"));
// 			var toIdx = ev.newIndex > ev.oldIndex ? jItem.prev()
// 				.length == 0 ? 0 : project.defs.getTableIndex(jItem.prev().data("name")) : jItem.next().length == 0 ? project.defs.tables.length
// 					- 1 : project.defs.getTableIndex(jItem.next().data("name"));
// 			var moved = project.defs.sortTableDef(fromIdx, toIdx);
// 			selectTable(moved);
// 			// editor.ge.emit(TableDefSorted);
// 		});
// 	}
// }
