// Source: https://www.npmjs.com/package/tabulator-tables
package tabulator;
import haxe.DynamicAccess;
import cdb.Data;

@:jsRequire("tabulator-tables")
extern class Tabulator {
	function new(element:String, options:Dynamic);

	public function on(eventName:String, cb:(args:Dynamic) -> Void):Void;
}

@:jsRequire("tabulator-tables")
extern class CellComponent {
	public function getValue():Dynamic;
	public function getField():Dynamic;
	public function getData():Dynamic;
}

function createColumns(columns:Array<cdb.Data.Column>) {
	trace(columns);
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
function createData(project:data.Project, sheet:cdb.Sheet) {
	// TODO
	// This has got to be the stupidest way to clone an array
	var s = new haxe.Serializer();
	s.serialize(sheet.lines);
	var us = new haxe.Unserializer(s.toString());
	var lines:Array<Dynamic> = us.unserialize();

	var columnTypes:DynamicAccess<ColumnType> = {}
	for (col in sheet.columns) {
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
