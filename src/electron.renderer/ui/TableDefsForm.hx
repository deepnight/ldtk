package ui;

import h3d.scene.Skin.Joint;

class TableDefsForm {
	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;
	public var jWrapper : js.jquery.JQuery;
	var jList(get,never) : js.jquery.JQuery; inline function get_jList() return jWrapper.find("ul.rowList");
	var jForm(get,never) : js.jquery.JQuery; inline function get_jForm() return jWrapper.find("dl.form");
	var td : Null<data.def.TableDef>;
	var curRow : Array<Dynamic>;


	public function new(td: Null<data.def.TableDef>) {
		this.td = td;
		this.curRow = td.data[0];

		jWrapper = new J('<div class="tableDefsForm"/>');
		jWrapper.html( JsTools.getHtmlTemplate("tableDefsForm"));

		updateList();
		updateForm();
	}
	public function selectRow(row) {
		curRow = row;
		updateList();
		updateForm();
	}

	public function updateList(){
		jList.empty();

		var jLi = new J('<li class="subList"/>');
		jLi.appendTo(jList);
		var jSubList = new J('<ul/>');
		jSubList.appendTo(jLi);

		var pki = td.columns.indexOf(td.primaryKey);
		for(row in td.data) {
			var jLi = new J("<li/>");
			jLi.appendTo(jSubList);
			jLi.append('<span class="table">'+row[pki]+'</span>');
			// jLi.data("uid",td.uid);

			if( row==curRow )
				jLi.addClass("active");
			jLi.click( function(_) {
				selectRow(row);
			});
			ui.modal.ContextMenu.addTo(jLi, [
				{
					label: L._Delete(),
					cb: () -> {},
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
	public function updateForm(){
		if( curRow==null ) {
			jForm.hide();
			return;
		}
		jForm.show();
		jForm.empty();
		for (i => column in td.columns) {
			jForm.append('<dt><label for=$column>$column</label></dt><dd></dd>');
			var jInput = new J('<input id=$column>');
			jInput.attr("type", "text");

			Input.linkToHtmlInput(curRow[i], jInput);
			jInput.appendTo(jForm.find("dd").last());
		}

	}
	public function deleteRow(row) {
		//TODO
	}


}
