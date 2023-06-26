package misc;

import js.html.Option;
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
import thx.csv.Csv;

class Tabulator {
	public var element:JQuery;
	public var sheet:Sheet;
	public var columns:Array<Column>;
	public var columnTypes:Map<String, ColumnType>;
	public var lines:Array<Dynamic>;
	public var tabulator:Null<tabulator.Tabulator>;

	public var sub:Null<Tabulator>;
	public var parentCell:Null<CellComponent>;
	
	public function new(element:EitherType<String, js.html.Element>, sheet:Sheet, ?parentCell:CellComponent) {
		this.element = new J(element);
		this.parentCell = parentCell;
		this.columns = sheet.columns;
		this.columnTypes = [for (x in columns) x.name => x.type];
		this.lines = parentCell == null ? sheet.getLines() : parentCell.getValue();
		if (this.lines == null) this.lines = [];
		this.sheet = sheet;
		createTabulator();
	}

	function createTabulator() {
		var cols = [({formatter: "rownum"}:ColumnDefinition)].concat([for (c in columns) createColumnDef(c)]);
		tabulator = new tabulator.Tabulator(element.get(0), {
			data: lines,
			columns: cols,
			movableRows: true,
			movableColumns: true,
			columnDefaults: {
				maxWidth:300,
			},
		});
		(js.Browser.window:Dynamic).tabulator = tabulator; // TODO remove this when debugging isnt needed
		tabulator.on("cellContext", (e, cell:CellComponent) -> {
			var ctx = new ContextMenu(e);
			var row = cell.getRow();
			ctx.add({
				label: new LocaleString("Add row before"),
				cb: createRow.bind(row, true)
			});
			ctx.add({
				label: new LocaleString("Add row after"),
				cb: createRow.bind(row, false)
			});
			ctx.add({
				label: new LocaleString("Delete row"),
				cb: () -> {
					sheet.deleteLine.bind(row.getPosition()-1);
					row.delete();
				}
			});

		});
		tabulator.on("headerContext", (e, columnComponent:ColumnComponent) -> {
			var column = getColumn(columnComponent);
			var ctx = new ContextMenu(e);
			ctx.add({
				label: new LocaleString("Add column"),
				cb: () -> new ui.modal.dialog.CastleColumn(sheet, (c)-> {
					tabulator.addColumn(createColumnDef(c));
				})
			});
			// The rest are only for existing columns
			if (column != null) {
				ctx.add({
					label: new LocaleString("Edit column"),
					cb: () -> new ui.modal.dialog.CastleColumn(sheet, column, (c)->{
						tabulator.updateColumnDefinition(c.name, createColumnDef(c));
					})
				});
				if (column.type == TString) {
					var displayCol = sheet.props.displayColumn;
					ctx.add({
						label: new LocaleString("Set as display column"),
						sub: new LocaleString(displayCol == column.name ? "Enabled" : "Disabled"),
						cb: () -> {
							sheet.props.displayColumn = displayCol == column.name ? null : column.name;
						}
					});
				}
				ctx.add({
					label: L._Delete(),
					cb: () -> {
						sheet.deleteColumn(column.name);
						tabulator.deleteColumn(column.name);
					}
				});
			}
			ctx.add({
				label: new LocaleString("Add row"),
				cb: () -> createRow()
			});
		});
		tabulator.on("rowMoved", (row:RowComponent) -> {
			var data = row.getData();
			var fromIndex = lines.indexOf(data);
			var toIndex = row.getPosition() - 1;
			lines.splice(fromIndex, 1); // Remove the original item
			lines.insert(toIndex, data); // Add the same data to the new position
		});

		if (parentCell != null) {
			// All the formatters write to this.lines, but we don't really want that for Sub Tabulators
			// Just clear sheet.lines and copy table data to where it needs to be
			tabulator.on("dataChanged", (c) -> {
				sheet.lines.splice(0, sheet.lines.length);
				parentCell.setValue(tabulator.getData());
			});
		}
		return tabulator;
	}

	public static function importSheet(type:String, absPath:String) {
		var fileContent = NT.readFileString(absPath);
		var table_name = absPath.split("/").pop();
		var data:Array<Array<Dynamic>> = Csv.decode(fileContent);
		var keys:Array<String> = data[0].map(Std.string);
		data.shift(); // Remove keys from the array

		var columns = [];
		for (key in keys) {
			var col:Column = {
				name: key,
				type: TString,
				typeStr: null
			}
			// columns.push(createColumnDef(col));
			columns.push(col);
		}
		var rows = [];
		for (row in data) {
			var obj:DynamicAccess<String> = {};
			for (i => val in row) {
				if (i > keys.length) continue; // TODO Is this the desired behaviour to handle extra values on rows?
				obj.set(keys[i], val);
			}
			rows.push(obj);
		}
		var s = Editor.ME.project.db.createSheet(table_name);
		for (c in columns) {
			s.addColumn(c);
		}
		for (l in rows) {
			s.lines.push(l);
		}
		return s;
	}

	function getColumn(column:ColumnComponent){
		for (col in sheet.columns) {
			if (column.getField() == col.name) {
				return col;
			}
		}
		return null;
	}

	// Add a row before or after specified RowComponent
	function createRow(?row:RowComponent, before=false) {
		// TODO getDefault doesnt actually return values that work. Maybe the fix should be done to the actual functions
		if (row == null) {
			var line = sheet.newLine();
			tabulator.addRow(line, before);
		} else {
			var castleIndex = before ? row.getPosition()-1 : row.getPosition();
			var line = sheet.newLine(castleIndex);
			tabulator.addRow(line, before, row);
		}
	}

	public function createColumnDef(c:Column) {
		var def:ColumnDefinition = {};
		def.title = c.name;
		def.field =  c.name;
		def.hozAlign = "center";
		var t = c.type;
		switch t {
			case TId, TString:
				def.editor = "input";
			case TInt, TFloat:
				def.editor = "number";
			case TImage, TTilePos:
				def.formatter =  imageFormatter;
			case TBool:
				def.editor = "tickCross";
				def.formatter = "tickCross";
			case TList:
				def.formatter = listFormatter;
				def.cellClick = listClick;
			case TDynamic:
				def.formatter = dynamicFormatter;
				def.cellClick = dynamicClick;
			case TTileLayer:
				def.formatter = tileLayerFormatter;
			case TRef(t):
				def.formatter = refFormatter;
			case _:
				// TODO editors
		}
		return def;
	}

	function tileLayerFormatter(cell:CellComponent, formatterParams, onRendered) {
		return "#DATA";
	}

	function refFormatter(cell:CellComponent, formatterParams, onRendered) {
		var value:Null<String> = cell.getValue();
		var type = columnTypes.get(cell.getField());
		var content = new J("<select class='advanced'/>");

		var refSheet = sheet.base.getSheet(sheet.base.typeStr(type));
		var idCol = refSheet.idCol.name;
		var nameCol = refSheet.props.displayColumn != null ? refSheet.props.displayColumn : idCol;
		var iconCol = refSheet.props.displayIcon;
		var empty = new Option("-- Select a line --", true);
		content.append(empty);
		for (line in refSheet.lines) {
			var line:DynamicAccess<Dynamic> = line;
			var name = line.get(nameCol);
			var selected = value == line.get(idCol);
			if (selected) empty.selected = false;
			var opt = new Option(name, name, false, selected);

			if (iconCol != null) {
				var i:TilePos = line.get(iconCol);
				var td = Editor.ME.project.defs.getTilesetDefFrom(i.file);
				opt.setAttribute("tile", Json.stringify(tilePosToTilesetRect(i, td)));
			}
			content.append(opt);
		}
		content.on("change", (e) -> {
			var val = content.val();
			cell.setValue(val);
		});
		onRendered(() -> {
			misc.JsTools.parseComponents(new J(cell.getElement()));
		});
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

		var subTabulator = new Tabulator(table, subSheet, cell);
		
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
	}

	function listFormatter(cell:CellComponent, formatterParams, onRendered) {
		var sub = sheet.base.getSheet(sheet.name + "@" + cell.getField());
		var str = "[" + Std.string([for (x in sub.columns) x.name]) + "]";
		return str;
	}

	function removeSubTabulator() {
		sub.tabulator.destroy();
		sub.element.closest(".subHolder").remove();
		sub = null;
	}

	function imageFormatter(cell:CellComponent, formatterParams, onRendered) {
		var tileRectPicker = new J("<span/>");
		var tilesetSelect = new J("<span/>");
		var values:TilePos = cell.getValue();
		var select = JsTools.createTilesetSelect(Editor.ME.project, null, null, false, (uid) -> {
			var td = Editor.ME.project.defs.getTilesetDef(uid);
			saveTilesetRect(cell, tilePosToTilesetRect(values, td), td);
		});
		select.appendTo(tilesetSelect);
		if (values == null || (values != null && values.file == null)) return tilesetSelect.get(0); 
		var td = Editor.ME.project.defs.getTilesetDefFrom(values.file);
		if (td == null ) return tilesetSelect.get(0); 
		var jPicker = JsTools.createTileRectPicker(
			td.uid,
			tilePosToTilesetRect(values, td),
			true,
			(tile) -> saveTilesetRect(cell, tile, td)
		);
		jPicker.appendTo(tileRectPicker);
		return tileRectPicker.get(0);
	}

	// LDTK uses pixels for the grimaimage CasPPooes how many'th tile it is
	function tilePosToTilesetRect(tilePos:TilePos, td:TilesetDef):TilesetRect {
		if (tilePos == null || td == null) return null;
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
		var values:TilePos = cell.getValue();
		var obj:DynamicAccess<Dynamic> = {};
		var size = td.tileGridSize;
		var x;
		var y;
		// Reset the position if the tileset changed. They might be different sizes
		if (values != null && values.file != td.relPath) {
			x = 0;
			y = 0;
		} else {
			x = tile == null ? 0 : tile.x;
			y = tile == null ? 0 : tile.y;
		}
		obj.set("file", td.relPath);
		obj.set("size", size);
		obj.set("x", x / size);
		obj.set("y", y / size);
		cell.setValue(obj);
	}
}