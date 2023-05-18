// Source: https://www.npmjs.com/package/tabulator-tables
package tabulator;
import js.html.Element;
import haxe.extern.EitherType;

@:jsRequire("tabulator-tables")
extern class Tabulator {
	function new(element:EitherType<String, js.html.Element>, options:Dynamic);
	public var sub:Null<Tabulator>;
	public var parentCell:Null<CellComponent>;
	public var sheet:cdb.Sheet;
	public var element:Element;

	public function on(eventName:String, cb:(e:Dynamic, cell:Dynamic) -> Void):Void;
	public function getData():Dynamic;
	public function redraw(full:Bool):Void;
	public function destroy():Void;
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
}

@:jsRequire("tabulator-tables")
extern class ColumnComponent {
}