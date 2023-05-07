// Source: https://www.npmjs.com/package/tabulator-tables
package tabulator;
import js.html.Element;
import haxe.extern.EitherType;
import js.jquery.JQuery;
import haxe.DynamicAccess;
import cdb.Data;

@:jsRequire("tabulator-tables")
extern class Tabulator {
	function new(element:EitherType<String, js.html.Element>, options:Dynamic);

	public function on(eventName:String, cb:(e:Dynamic, cell:Dynamic) -> Void):Void;
}

@:jsRequire("tabulator-tables")
extern class CellComponent {
	public function getValue():Dynamic;
	public function getField():Dynamic;
	public function getData():Dynamic;
}

function createTabulator(element:EitherType<String, js.html.Element>, columns:Array<cdb.Data.Column>, lines:Array<Dynamic>, sheet:cdb.Sheet, project:data.Project) {
	var tabulator = new Tabulator(element, {
		data: createData(lines, columns, project),
		columns: createColumns(columns),
		movableRows: true,
		movableColumns: true,
	});
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
function createColumns(columns:Array<cdb.Data.Column>) {
	var cols = [];
	for (column in columns) {
		var col:DynamicAccess<Dynamic> = {};
		col.set("title", column.name);
		col.set("field", column.name);
		switch column.type {
			case TId, TString: 
				col.set("editor", "input");
			case TImage, TTilePos:
				col.set("formatter", "image");
			case TBool:
				col.set("editor", "tickCross");
				col.set("formatter", "tickCross");
			case _:
				// TODO editors
		}
		cols.push(col);
	}
	return cols;
}
function createData(original_lines:Array<Dynamic>, columns:Array<Column>, project:data.Project) {
	// TODO
	// This has got to be the stupidest way to clone an array
	var s = new haxe.Serializer();
	s.serialize(original_lines);
	var us = new haxe.Unserializer(s.toString());
	var lines:Array<Dynamic> = us.unserialize();

	var columnTypes:DynamicAccess<ColumnType> = {}
	for (col in columns) {
		columnTypes.set(col.name, col.type);
	}

	for (line in lines) {
		var line:DynamicAccess<Dynamic> = line;
		for (col in line.keys()) {
			switch columnTypes.get(col) {
				case TImage, TTilePos:
					line.set(col, project.getAbsExternalFilesDir() + "/" + line.get(col).file);
				case _:
					// TODO visualize the data
			}
		}
	}
	return lines;
}
