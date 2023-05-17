package misc;

import cdb.Sheet;
import misc.JsTools;
import js.html.Element;
import haxe.extern.EitherType;
import js.jquery.JQuery;
import haxe.DynamicAccess;
import cdb.Data;
import tabulator.Tabulator;

function createTabulator(element:EitherType<String, js.html.Element>, columns:Array<cdb.Data.Column>, lines:Array<Dynamic>, sheet:Sheet) {
	var tabulator = new Tabulator(element, {
		// data: createData(lines, columns, project),
		data: lines,
		columns: createColumns(columns, sheet),
		movableRows: true,
		movableColumns: true,
	});
	tabulator.sheet = sheet;
	return tabulator;
	// tabulator.on("cellClick", function(e, cell) {
	// 	var columnTypes:DynamicAccess<ColumnType> = {};
	// 	for (col in sheet.columns) {
	// 		columnTypes.set(col.name, col.type);
	// 	}
	// 	var colType = columnTypes.get(cell.getField());

	// 	switch colType {
	// 		case TList:
	// 			var row:JQuery = cell.getRow().getElement();

	// 			var ele = js.Browser.document.createElement("div");
	// 			ele.id = "contara";
	// 			row.append(ele);

	// 			var ref = sheet.getSub(sheet.columns[5]);
	// 			trace(ref.name);
	// 			createTabulator("#contara", ref.columns, ref.lines, ref, project);
	// 		case _:
	// 			// We dont need to handle clicks on all types
			
	
		// }
	// });
}
function createColumns(columns:Array<cdb.Data.Column>, sheet:Sheet) {
	var cols = [];
	for (column in columns) {
		var col:DynamicAccess<Dynamic> = {};
		col.set("title", column.name);
		col.set("field", column.name);
		switch column.type {
			case TId, TString: 
				col.set("editor", "input");
			case TImage, TTilePos:
				col.set("formatter", imageFormatter);
				col.set("formatterParams", {});
			case TBool:
				col.set("editor", "tickCross");
				col.set("formatter", "tickCross");
			case TList:
				col.set("formatter", listFormatter);
				col.set("formatterParams", {});
				col.set("cellClick", listClick);
			case _:
				// TODO editors
		}
		cols.push(col);
	}
	return cols;
}
// 
// I should be able to pass the lines staight to Tabulator. Keeping this here in case it doesn't work later on
//
// function createData(lines:Array<Dynamic>, columns:Array<Column>, project:data.Project) {
// 	// TODO
// 	// This has got to be the stupidest way to clone an array
// 	// var s = new haxe.Serializer();
// 	// s.serialize(original_lines);
// 	// var us = new haxe.Unserializer(s.toString());
// 	// var lines:Array<Dynamic> = us.unserialize();

// 	var columnTypes:DynamicAccess<ColumnType> = {}
// 	for (col in columns) {
// 		columnTypes.set(col.name, col.type);
// 	}

// 	for (line in lines) {
// 		var line:DynamicAccess<Dynamic> = line;
// 		for (col in line.keys()) {
// 			switch columnTypes.get(col) {
// 				case TImage, TTilePos:
// 					// line.set(col, project.getAbsExternalFilesDir() + "/" + line.get(col).file);
// 				case _:
// 					// TODO visualize the data
// 			}
// 		}
// 	}
// 	return lines;
// }


function listClick(e, cell:CellComponent) {
	var tabulator:tabulator.Tabulator = cell.getTable();
	var sheet:Sheet = tabulator.sheet;
	var cellElement = cell.getElement();
	var subSheet = sheet.base.getSheet(sheet.name + "@" + cell.getField());

	var holder = js.Browser.document.createElement("div");
	holder.classList.add("subHolder");
	var table = js.Browser.document.createElement("div");

	// Close the old subTabulator if one exists and return if we're trying to open the same one
	// TODO This looks ugly but im too tired to find a better way rn
	// TODO Opening the same TList from another row just closes it aswell
	if (tabulator.sub != null) {
		if (tabulator.sub.sheet.name == subSheet.name) {
			removeSubTabulator(tabulator);
			return;
		}
		removeSubTabulator(tabulator);
	}

	var subTabulator = createTabulator(table, subSheet.columns, cell.getValue(), subSheet);
	
	holder.style.boxSizing = "border-box";
	holder.style.padding = "10px 30px 10px 10px";
	holder.style.borderTop = "1px solid #333";
	holder.style.borderBottom = "1px solid #333";

	table.style.border = "3px solid #333";
	table.style.height = "fit-content";
	table.style.width = "fit-content";

	holder.appendChild(table);
	cellElement.closest(".tabulator-row").append(holder);
	
	tabulator.sub = subTabulator;
}

function listFormatter(cell:CellComponent, formatterParams, onRendered) {
	var values:DynamicAccess<Dynamic> = cell.getValue()[0];
	return Std.string(values.keys());
}

function removeSubTabulator(tabulator:Tabulator) {
	tabulator.sub.element.closest(".subHolder").remove();
	tabulator.sub = null;
}

function imageFormatter(cell:CellComponent, formatterParams, onRendered) {
	var content = js.Browser.document.createElement("span");
	var values = cell.getValue();
    var td = Editor.ME.project.defs.getTilesetDefFrom(values.file);
	
	// Tile preview
    // LDTK uses pixels for the grid, Castle uses how many'th tile it is
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