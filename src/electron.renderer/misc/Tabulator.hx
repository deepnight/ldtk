package misc;

import data.def.TilesetDef;
import ldtk.Json.TilesetRect;
import cdb.Types.TilePos;
import cdb.Data.ColumnType;
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
	public var columnTypes:Map<String, ColumnType>;
	public var lines:Array<Dynamic>;
	public var tabulator:Null<tabulator.Tabulator>;

	public var sub:Null<Tabulator>;
	public var parentCell:Null<CellComponent>;
	
	public function new(element:EitherType<String, js.html.Element>, sheet:Sheet) {
		this.element = new J(element);
		this.columns = sheet.columns;
		this.columnTypes = [for (x in columns) x.name => x.type];
		this.lines = sheet.getLines();
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
			var t = column.type;
			switch t {
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
					col.set("cellClick", listClick);
				case TDynamic:
					col.set("formatter", dynamicFormatter);
					col.set("cellClick", dynamicClick);
				case TTileLayer:
					col.set("formatter", tileLayerFormatter);
				case TRef(t):
					col.set("formatter", refFormatter);
				case _:
					// TODO editors
			}
			cols.push(col);
		}
		return cols;
	}

	function tileLayerFormatter(cell:CellComponent, formatterParams, onRendered) {
		return "#DATA";
	}

	function refFormatter(cell:CellComponent, formatterParams, onRendered) {
		var value:Null<String> = cell.getValue();
		var type = columnTypes.get(cell.getField());
		var content = new J("<span/>");
		if (value == null) return content.get(0);

		// Index contains reference data I think
		var s = sheet.base.getSheet(sheet.base.typeStr(type));
		var i = s.index.get(value);

		if (i == null) {
			content.val("#REF");
			return content.get(0);
		}
		// Ref Image
		if (i.ico != null) {
			var jPicker = tilePosToTileRectPicker(i.ico, cell, true);
			content.append(jPicker);
		}
		// Ref Name
		content.append(StringTools.htmlEscape(i.disp));
		return content.get(0);
	}

	function dynamicFormatter(cell:CellComponent, formatterParams, onRendered) {
		return sheet.base.valToString(TDynamic, cell.getValue());
	}

	function dynamicClick(e, cell:CellComponent) {
		var str = Json.stringify(cell.getValue(), null, "\t");
		var te = new TextEditor(str, cell.getField(), null, LangJson,
		(value) -> {
			// TODO Handle JSON parsing errors
			var val = sheet.base.parseDynamic(value);
			cell.setValue(val);
		});
	}

	function listClick(e, cell:CellComponent) {
		var cellElement = cell.getElement();
		var subSheet = sheet.base.getSheet(sheet.name + "@" + cell.getField());

		var holder = js.Browser.document.createElement("div");
		holder.classList.add("subHolder");
		var table = js.Browser.document.createElement("div");

		// Close the old subTabulator if one exists and return if we're trying to open the same one
		if (sub != null) {
			if (sub.parentCell == cell) {
				removeSubTabulator();
				return;
			}
			removeSubTabulator();
		} 

		var subTabulator = new Tabulator(table, subSheet);
		
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
					var values:TilePos = cell.getValue();
					saveTilesetRect(cell, tilePosToTilesetRect(values, td), td);
				}
			}
		);
		// We need to return the HTML element itself, not a JQuery object
		return content.get(0);
	}

	function imageFormatter(cell:CellComponent, formatterParams, onRendered) {
		var content = new J("<span/>");
		var values:TilePos = cell.getValue();
		var jPicker = tilePosToTileRectPicker(values, cell, true);
		
		if (jPicker == null) {
			var jPicker = JsTools.createTileRectPicker(null, null, false, (x) -> {});
			jPicker.appendTo(content);
			return content.get(0);
		}

		jPicker.appendTo(content);
		return content.get(0);
	}

	// Create a tile image (and possibly a picker) from a CastleDB TImage object
	// Provide a cellComponent and set editable to true to allow editing
	function tilePosToTileRectPicker(tilePos:TilePos, ?cell:CellComponent, ?editable = true) {
		var td = Editor.ME.project.defs.getTilesetDefFrom(tilePos.file);
		if (td == null) return null;
		var jPicker = JsTools.createTileRectPicker(
			td.uid,
			tilePosToTilesetRect(tilePos, td),
			editable,
			cell == null ? (x) -> {} : (tile) -> saveTilesetRect(cell, tile, td)
		);
		return jPicker;
	}

	// LDTK uses pixels for the grimaimage CasPPooes how many'th tile it is
	function tilePosToTilesetRect(tilePos:TilePos, td:TilesetDef):TilesetRect {
		var size = td.tileGridSize;
		var tilesetRect =  {
			tilesetUid: td.uid,
			h: size,
			w: size,
			y: tilePos.y * size,
			x: tilePos.x * size,
		};
		return tilesetRect;
	}

	// Save the tilesetPicker value to CastleDB
	function saveTilesetRect(cell:CellComponent, tile:TilesetRect, td:TilesetDef) {
		var obj:DynamicAccess<Dynamic> = {};
		var size = td.tileGridSize;
		obj.set("file", td.relPath);
		obj.set("size", size);
		obj.set("x", tile.x / size);
		obj.set("y", tile.y / size);
		cell.setValue(obj);
	}
}