package misc;

import cdb.Data.Column;
import js.jquery.JQuery;
import haxe.Json;
import ui.modal.dialog.TextEditor;
import ui.modal.ContextMenu;
import cdb.Sheet;
import misc.JsTools;
import js.html.Element;
import haxe.extern.EitherType;
import haxe.DynamicAccess;
import tabulator.Tabulator;

class Tabulator {
	public var element:JQuery;
	public var sheet:Sheet;
	public var columns:Array<Column>;
	public var lines:Array<Dynamic>;
	public var tabulator:Null<tabulator.Tabulator>;

	public var sub:Null<Tabulator>;
	public var parentCell:Null<CellComponent>;
	
	public function new(element:EitherType<String, js.html.Element>, columns:Array<Column>, lines:Array<Dynamic>, sheet:Sheet) {
		this.element = new J(element);
		this.columns = columns;
		this.lines = lines;
		this.sheet = sheet;
		createTabulator();
	}

	function createTabulator() {
		tabulator = new tabulator.Tabulator(element.get(0), {
			data: lines,
			columns: createColumns(columns),
			movableRows: true,
			movableColumns: true,
			columnDefaults: {
				maxWidth:300,
			},
		});
		tabulator.on("renderComplete", (e, cell) -> {
			for (column in sheet.columns) {
				var el = new J(tabulator.element).find('div.tabulator-col[tabulator-field="'+column.name+'"]');
				ContextMenu.addTo(el, false, [
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
						cb: () -> {
							sheet.deleteColumn(column.name);
							tabulator.deleteColumn(column.name);
						}
					},
				]);
			}
		});
		return tabulator;
	}

	function createColumns(columns:Array<Column>) {
		var cols = [];
		for (column in columns) {
			var col:DynamicAccess<Dynamic> = {};
			col.set("title", column.name);
			col.set("field", column.name);
			switch column.type {
				case TId, TString, TInt: 
					col.set("editor", "input");
				case TImage, TTilePos:
					col.set("formatter", imageFormatter);
					var line:DynamicAccess<Dynamic> = sheet.lines[0];
					col.set("headerFilterParams", {curTileset: Editor.ME.project.defs.getTilesetDefFrom(line.get(column.name).file)});
					col.set("headerFilter", imageHeaderFilter);
				case TBool:
					col.set("editor", "tickCross");
					col.set("formatter", "tickCross");
				case TList:
					col.set("formatter", listFormatter);
					col.set("formatterParams", {sheet: sheet});
					col.set("cellClick", listClick);
				case TDynamic:
					col.set("formatter", dynamicFormatter);
					col.set("formatterParams", {sheet: sheet});
					col.set("cellClick", dynamicClick);
				case _:
					// TODO editors
			}
			cols.push(col);
		}
		return cols;
	}

	function dynamicFormatter(cell:CellComponent, formatterParams, onRendered) {
		var sheet:Sheet = formatterParams.sheet;
		return sheet.base.valToString(TDynamic, cell.getValue());
	}

	function dynamicClick(e, cell:CellComponent) {
		var str = Json.stringify(cell.getValue(), null, "\t");
		var te = new TextEditor(str, cell.getField(), null, LangJson,
		(value) -> {
			// TODO Handle JSON parsing errors
			// TODO Could also use sheet.base.parseDynamic() when i change this file to a class
			cell.setValue(Json.parse(value));
		});
	}

	function listClick(e, cell:CellComponent) {
		var cellElement = cell.getElement();
		var subSheet = sheet.base.getSheet(sheet.name + "@" + cell.getField());

		var holder = js.Browser.document.createElement("div");
		holder.classList.add("subHolder");
		var table = js.Browser.document.createElement("div");

		// Close the old subTabulator if one exists and return if we're trying to open the same one
		// TODO This looks ugly but im too tired to find a better way rn
		if (sub != null) {
			if (sub.parentCell == cell) {
				removeSubTabulator();
				return;
			}
			removeSubTabulator();
		} 

		var subTabulator = new Tabulator(table, subSheet.columns, cell.getValue(), subSheet);
		
		holder.style.boxSizing = "border-box";
		holder.style.padding = "10px 30px 10px 10px";
		holder.style.borderTop = "1px solid #333";
		holder.style.borderBottom = "1px solid #333";

		table.style.border = "3px solid #333";
		table.style.height = "fit-content";
		table.style.width = "fit-content";

		holder.appendChild(table);
		cellElement.closest(".tabulator-row").append(holder);
		
		sub = subTabulator;
		sub.parentCell = cell;
	}

	function listFormatter(cell:CellComponent, formatterParams, onRendered) {
		var sheet:Sheet = formatterParams.sheet;
		var sub = sheet.base.getSheet(sheet.name + "@" + cell.getField());
		var str = "[" + Std.string([for (x in sub.columns) x.name]) + "]";
		return str;
	}

	function removeSubTabulator() {
		sub.element.closest(".subHolder").remove();
		sub = null;
	}

	function imageHeaderFilter(cell, onRendered, success, cancel, headerFilterParams) {
		// TODO For some reason you cant re-select the original tileset if you change it without reloading tabulator
		var content = new J("<select/>");
		var curTd = headerFilterParams.curTileset;
		var uid = curTd != null ? curTd.uid : null;

		JsTools.createTilesetSelect(
			Editor.ME.project,
			content,
			uid,
			false,
			(tileUid) -> {
				var td = Editor.ME.project.defs.getTilesetDef(tileUid);
				var cells:Array<CellComponent> = cell.getColumn().getCells();
				for (cell in cells) {
					var obj:DynamicAccess<Dynamic> = {};
					obj.set("file", td.relPath);
					obj.set("size", td.tileGridSize);
					obj.set("x", cell.getValue().x);
					obj.set("y", cell.getValue().y);
					cell.setValue(obj);
				}
			}
		);
		// We need to return the HTML element itself, not a JQuery object
		return content.get(0);
	}

	function imageFormatter(cell:CellComponent, formatterParams, onRendered) {
		var content = js.Browser.document.createElement("span");
		var values = cell.getValue();
		var td = Editor.ME.project.defs.getTilesetDefFrom(values.file);
		
		// Tile preview
		// LDTK uses pixels for the grid, Castle uses how many'th tile it is
		// TODO test createTilePicker()
		var exists = td != null ? true : false;

		var uid = exists ? td.uid : null;
		var size = exists ? td.tileGridSize : null;
		var relPath = exists ? td.relPath : null;
		var tilesetRect = exists ? {
			tilesetUid: uid,
			h: size,
			w: size,
			y: values.y * size,
			x: values.x * size
		} : null;

		var jPicker = JsTools.createTileRectPicker(
			uid,
			tilesetRect,
			exists,
			(tile) -> {
				var obj:DynamicAccess<Dynamic> = {};
				obj.set("file", relPath);
				obj.set("size", size);
				obj.set("x", tile.x / size);
				obj.set("y", tile.y / size);
				cell.setValue(obj);
			}
		);
		jPicker.appendTo(content);
		return content;
	}
}