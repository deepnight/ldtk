// Source: https://www.npmjs.com/package/tabulator-tables
package tabulator;
import js.jquery.Event;
import js.html.Element;
import haxe.extern.EitherType;

@:jsRequire("tabulator-tables")
extern class Tabulator {
	function new(element:EitherType<String, js.html.Element>, options:Dynamic);
	public var element:Element;

	public function on(eventName:String, cb:(e:Event, component:Dynamic) -> Void):Void;
	public function getData():Dynamic;
	public function getColumns():Array<ColumnComponent>;
	public function addRow(data:Dynamic):Void;
	public function addColumn(definition:ColumnDefinition):Void;
	public function redraw(full:Bool):Void;
	public function destroy():Void;
	public function updateColumnDefinition(name:String, data:Dynamic):Void;
	public function deleteColumn(name:String):Void;
}

@:jsRequire("tabulator-tables")
extern class CellComponent {
	public function getValue():Dynamic;
	public function getField():Dynamic;
	public function getTable():Tabulator;
	public function getRow():RowComponent;
	public function getElement():Element;
	public function getData():Dynamic;
	public function setValue(value:Dynamic):Void;
	public function getParentColumn():ColumnComponent;
}


@:jsRequire("tabulator-tables")
extern class RowComponent {
	public function getIndex():Int;
	public function getPosition():Int;
	public function getElement():Element;
	public function delete():Void;
}

@:jsRequire("tabulator-tables")
extern class ColumnComponent {
	public function getCells():Array<CellComponent>;
	public function getValue():Dynamic;
	public function getField():String;
}
typedef ColumnDefinition = {
	var ?title : String;
	var ?field : String;
	var ?formatter : Dynamic;
	var ?hozAlign : String;
	var ?editor : Dynamic;
	var ?headerFilter : Dynamic;
	var ?headerFilterParams : Dynamic;
	var ?cellClick : Dynamic;
}